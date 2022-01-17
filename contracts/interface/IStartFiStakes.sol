// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 
 *@title  IStartFi Stakes
 * [ desc ] : contract to hold users stakes
 *@notice : the logic behind this contract is not implemented yet, this is just a basic design for the sake of testing the marketplace cycle
 */

interface IStartFiStakes {
    /******************************************* decalrations go here ********************************************************* */

    event DepositFunds(address indexed diposter, uint256 amount);
    event WithdrawFunds(address indexed diposter, uint256 amount);
    event ChangeLockDuration(uint256 duration);

    /******************************************* constructor goes here ********************************************************* */

    // deposit
    function deposit(address user, uint256 amount) external;

    function ValidateStakes(address user, uint256[] calldata proofIndexes) external returns (uint256 reservAmount);

    // withdraw
    function withdraw(uint256 amount, uint256[] calldata proofIndexes) external;

    function emergencyWithdraw(uint256[] calldata proofIndexes) external;
}
