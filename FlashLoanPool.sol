// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IFlashLoanReceiver.sol";

contract FlashLoanPool is ReentrancyGuard {
    IERC20 public immutable loanToken;
    uint256 public poolFeeBps; // 1 basis point = 0.01%
    address public owner;

    /// @notice Max fee is 10% (1000 bps)
    uint256 public constant MAX_FEE_BPS = 1000;

    event FlashLoanExecuted(address indexed receiver, uint256 amount, uint256 fee);
    event LiquidityWithdrawn(address indexed owner, uint256 amount);
    event TokensRescued(address indexed token, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "FPO: not owner");
        _;
    }

    constructor(address _token, uint256 _feeBps) {
        require(_token != address(0), "Invalid token address");
        require(_feeBps <= MAX_FEE_BPS, "Fee exceeds max");
        loanToken = IERC20(_token);
        poolFeeBps = _feeBps;
        owner = msg.sender;
    }

    /// @notice Transfer ownership to a new address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "FPO: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Owner can withdraw liquidity from the pool
    function withdrawLiquidity(uint256 amount) external onlyOwner {
        require(amount > 0, "FPO: zero amount");
        require(loanToken.balanceOf(address(this)) >= amount, "FPO: insufficient balance");
        require(loanToken.transfer(owner, amount), "FPO: transfer failed");
        emit LiquidityWithdrawn(owner, amount);
    }

    /// @notice Rescue any ERC20 tokens accidentally sent to the contract
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "FPO: zero amount");
        require(IERC20(token).transfer(owner, amount), "FPO: transfer failed");
        emit TokensRescued(token, amount);
    }

    /// @notice Owner can update the fee (capped at MAX_FEE_BPS)
    function setFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= MAX_FEE_BPS, "Fee exceeds max");
        poolFeeBps = _newFeeBps;
    }

    function flashLoan(
        address receiverAddress,
        uint256 amount,
        bytes calldata params
    ) external nonReentrant {
        uint256 balanceBefore = loanToken.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient pool liquidity");

        uint256 fee = (amount * poolFeeBps) / 10000;

        require(loanToken.transfer(receiverAddress, amount), "Token transfer failed");

        require(
            IFlashLoanReceiver(receiverAddress).executeOperation(
                address(loanToken),
                amount,
                fee,
                params
            ),
            "Flash loan execution failed"
        );

        uint256 balanceAfter = loanToken.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore + fee,
            "Flash loan capital not returned with fee"
        );

        emit FlashLoanExecuted(receiverAddress, amount, fee);
    }
}
