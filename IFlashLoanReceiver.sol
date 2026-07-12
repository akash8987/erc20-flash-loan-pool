// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external returns (bool);
}
