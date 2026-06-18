// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title FinanceManager
/// @notice Unified finance management contract for the Pharos Finance Manager skill.
///         Supports token locking, Uniswap-compatible swaps, batch payments,
///         and multi-token portfolio snapshots.
contract FinanceManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────────────────────
    // Types
    // ─────────────────────────────────────────────────────────────

    struct Lock {
        address token;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    // ─────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────

    /// @notice Uniswap-compatible swap router deployed on Pharos
    address public swapRouter;

    /// @notice user => array of time-locked deposits
    mapping(address => Lock[]) public locks;

    // ─────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────

    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 indexed lockIndex, uint256 amount);
    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event BatchPaid(address indexed sender, address indexed token, uint256 totalAmount, uint256 recipientCount);
    event SwapRouterUpdated(address indexed oldRouter, address indexed newRouter);

    // ─────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────

    constructor(address _swapRouter) Ownable(msg.sender) {
        require(_swapRouter != address(0), "Invalid router");
        swapRouter = _swapRouter;
    }

    // ─────────────────────────────────────────────────────────────
    // Module 1: Deposit / Lock
    // ─────────────────────────────────────────────────────────────

    /// @notice Lock tokens for a specified number of days.
    /// @param token      ERC20 token address to lock
    /// @param amount     Amount in token's native decimals (wei)
    /// @param durationDays  Number of days until unlock
    function deposit(
        address token,
        uint256 amount,
        uint256 durationDays
    ) external nonReentrant {
        require(token != address(0), "Invalid token");
        require(amount > 0, "Amount must be > 0");
        require(durationDays > 0, "Duration must be > 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 unlockTime = block.timestamp + (durationDays * 1 days);
        locks[msg.sender].push(Lock({
            token:      token,
            amount:     amount,
            unlockTime: unlockTime,
            withdrawn:  false
        }));

        emit Deposited(msg.sender, token, amount, unlockTime);
    }

    /// @notice Withdraw a previously locked deposit after unlock time.
    /// @param lockIndex  Index into the caller's locks array
    function withdraw(uint256 lockIndex) external nonReentrant {
        Lock storage l = locks[msg.sender][lockIndex];
        require(!l.withdrawn, "Already withdrawn");
        require(block.timestamp >= l.unlockTime, "Still locked");

        uint256 amount = l.amount;
        address token  = l.token;
        l.withdrawn = true;
        l.amount    = 0;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, lockIndex, amount);
    }

    /// @notice Read all locks for a given wallet.
    function getLocks(address wallet) external view returns (Lock[] memory) {
        return locks[wallet];
    }

    // ─────────────────────────────────────────────────────────────
    // Module 2: Swap
    // ─────────────────────────────────────────────────────────────

    /// @notice Swap an exact amount of tokenIn for as much tokenOut as possible.
    /// @param tokenIn        Token to sell
    /// @param tokenOut       Token to buy
    /// @param amountIn       Exact amount of tokenIn to spend
    /// @param amountOutMin   Minimum acceptable tokenOut (slippage guard)
    /// @param fee            Pool fee tier: 500, 3000, or 10000
    /// @return amountOut     Actual amount of tokenOut received
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24  fee
    ) external nonReentrant returns (uint256 amountOut) {
        require(tokenIn  != address(0), "Invalid tokenIn");
        require(tokenOut != address(0), "Invalid tokenOut");
        require(amountIn > 0,           "Amount must be > 0");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(swapRouter, amountIn);

        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn:            tokenIn,
            tokenOut:           tokenOut,
            fee:                fee,
            recipient:          msg.sender,
            deadline:           block.timestamp + 300, // 5 min deadline
            amountIn:           amountIn,
            amountOutMinimum:   amountOutMin,
            sqrtPriceLimitX96:  0
        });

        // Call the Uniswap-compatible router
        (bool success, bytes memory data) = swapRouter.call(
            abi.encodeWithSignature(
                "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))",
                params
            )
        );
        require(success, "Swap failed");
        amountOut = abi.decode(data, (uint256));

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // ─────────────────────────────────────────────────────────────
    // Module 3: Batch Pay
    // ─────────────────────────────────────────────────────────────

    /// @notice Send an ERC20 token to multiple recipients in one transaction.
    /// @param token       Token to distribute
    /// @param recipients  Array of recipient addresses
    /// @param amounts     Corresponding array of amounts (must match recipients length)
    function batchPay(
        address   token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(token != address(0), "Invalid token");
        require(recipients.length > 0, "No recipients");
        require(recipients.length == amounts.length, "Length mismatch");

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be > 0");
            total += amounts[i];
        }

        // Pull total from sender first
        IERC20(token).safeTransferFrom(msg.sender, address(this), total);

        // Distribute
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).safeTransfer(recipients[i], amounts[i]);
        }

        emit BatchPaid(msg.sender, token, total, recipients.length);
    }

    // ─────────────────────────────────────────────────────────────
    // Module 4: Portfolio Snapshot
    // ─────────────────────────────────────────────────────────────

    /// @notice Read the ERC20 balance of a wallet across multiple tokens.
    ///         Read-only — no gas cost beyond the call itself.
    /// @param wallet   Wallet to inspect
    /// @param tokens   Array of ERC20 token addresses to check
    /// @return balances  Array of balances in the same order as tokens
    function getBalances(
        address   wallet,
        address[] calldata tokens
    ) external view returns (uint256[] memory balances) {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0)) {
                balances[i] = IERC20(tokens[i]).balanceOf(wallet);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Admin
    // ─────────────────────────────────────────────────────────────

    /// @notice Update the swap router address (owner only).
    function setSwapRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0), "Invalid router");
        emit SwapRouterUpdated(swapRouter, newRouter);
        swapRouter = newRouter;
    }

    /// @notice Recover any ERC20 accidentally sent directly to this contract.
    function recoverToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
