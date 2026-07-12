// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IFlashLoanReceiver.sol";

contract FlashLoanPool is ReentrancyGuard {
    IERC20 public immutable loanToken;
    uint256 public poolFeeBps; // 1 basis point = 0.01%

    event FlashLoanExecuted(address indexed receiver, uint256 amount, uint256 fee);

    constructor(address _token, uint256 _feeBps) {
        require(_token != address(0), "Invalid token address");
        loanToken = IERC20(_token);
        poolFeeBps = _feeBps;
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
