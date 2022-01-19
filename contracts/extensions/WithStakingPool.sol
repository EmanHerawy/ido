// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 
 *@title  StartFi Stakes
 * [ desc ] : contract to hold users stakes
 *@notice : the logic behind this contract is not implemented yet, this is just a basic design for the sake of testing the marketplace cycle
 */

contract WithStakingPool is ReentrancyGuard {
    /******************************************* decalrations go here ********************************************************* */
    uint256 private _lockDuration;
    address private _stakingToken;

    mapping(address => uint256) stakerTotalStakes;
    mapping(address => uint256) stakerTimestamp;
    /******************************************* modifiers go here ********************************************************* */

    // events

    event DepositFunds(address indexed diposter, uint256 amount);
    event WithdrawFunds(address indexed diposter, uint256 amount);
    event ChangeLockDuration(uint256 duration);

    /******************************************* constructor goes here ********************************************************* */

    constructor(address token_, uint256 lockDuration_) {
        require(token_ != address(0) && lockDuration_ != 0, 'Zero values are not allowes');
        _stakingToken = token_;
        _lockDuration = lockDuration_;
    }

    /******************************************* read state functions go here ********************************************************* */

    // deposit
    function _deposit(address user, uint256 amount) internal {
        require(IERC20(_stakingToken).allowance(user, address(this)) >= amount, 'Invalid amount');
        IERC20(_stakingToken).transferFrom(user, address(this), amount);
        stakerTotalStakes[user] += amount;
        stakerTimestamp[user] = block.timestamp;
        emit DepositFunds(user, amount);
    }

    function _safeTokenTransfer(address to, uint256 amount) private returns (bool) {
        return IERC20(_stakingToken).transfer(to, amount);
    }

    // withdraw
    function _unstake(address user, uint256 amount) internal nonReentrant {
        // TODO:check marketplace user reserves
        require(stakerTotalStakes[user] >= amount, 'Invalid amount');

        stakerTotalStakes[user] -= amount;

        _safeTokenTransfer(user, amount);

        emit WithdrawFunds(user, amount);
    }

    function _updateLockDuration(uint256 _duration) internal {
        require(_duration > 1 days, 'Lock time must not be less than a day');
        _lockDuration = _duration;
        emit ChangeLockDuration(_duration);
    }

    //getpoolinfo
    function getReserves(address _owner) public view returns (uint256) {
        return stakerTotalStakes[_owner];
    }

    function lockDuration() external view returns (uint256) {
        return _lockDuration;
    }

    function stakingToken() external view returns (address) {
        return _stakingToken;
    }

    function isUnLockedFund(address user) public view returns (bool) {
        return stakerTimestamp[user] + _lockDuration <= block.timestamp;
    }
}
