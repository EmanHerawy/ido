// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 
 *@title  StartFi Stakes
 * [ desc ] : contract to hold users stakes
 *@notice : the logic behind this contract is not implemented yet, this is just a basic design for the sake of testing the marketplace cycle
 */

contract StartFiStakes is Pausable, ReentrancyGuard, AccessControlEnumerable {
    /******************************************* decalrations go here ********************************************************* */
    uint256 private _lockDuration;
    address private _stakingToken;
    bytes32 public constant IDO_ROLE = keccak256('IDO_ROLE');
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');

    struct userPools {
        uint256 amount;
        uint256 registerBlock;
        bool reservedToIDO;
    }

    mapping(address => uint256) stakerTotalStakes;
    mapping(address => userPools[]) stakerPools;
    /******************************************* modifiers go here ********************************************************* */
    modifier onlyIDO() {
        require(hasRole(IDO_ROLE, _msgSender()), 'caller is not IDO');

        _;
    }
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), 'caller is not the owner');

        _;
    }
    // events

    event DepositFunds(address indexed diposter, uint256 amount);
    event WithdrawFunds(address indexed diposter, uint256 amount);
    event ChangeLockDuration(uint256 duration);

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        address token_,
        address _owner,
        uint256 lockDuration_
    ) {
        _stakingToken = token_;
        _lockDuration = lockDuration_;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);

        _setupRole(OWNER_ROLE, _owner);
    }

    /******************************************* read state functions go here ********************************************************* */

    /**
     * @dev Pauses contract.
     *
     *
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses contract.
     *
     *
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    // deposit
    function deposit(address user, uint256 amount) external whenNotPaused nonReentrant {
        require(_getAllowance(_msgSender()) >= amount, 'Invalid amount');
        IERC20(_stakingToken).transferFrom(_msgSender(), address(this), amount);
        stakerPools[user].push(userPools(amount, block.timestamp, false));
        stakerTotalStakes[user] += amount;
        // stakerFree[user] += amount;
        emit DepositFunds(user, amount);
    }

    function validateStakes(address user, uint256[] calldata proofIndexes)
        external
        onlyIDO
        whenNotPaused
        returns (uint256 reservAmount)
    {
        userPools[] storage _userPools = stakerPools[user];

        for (uint256 index = 0; index < proofIndexes.length; index++) {
            if (
                _userPools[proofIndexes[index]].reservedToIDO == false &&
                _userPools[proofIndexes[index]].amount > 0 &&
                _userPools[proofIndexes[index]].registerBlock + _lockDuration <= block.timestamp
            ) {
                reservAmount += _userPools[proofIndexes[index]].amount;
                _userPools[proofIndexes[index]].reservedToIDO = true;
            }
        }
    }

    function _safeTokenTransfer(address to, uint256 amount) private returns (bool) {
        return IERC20(_stakingToken).transfer(to, amount);
    }

    // withdraw
    function withdraw(uint256 amount, uint256[] calldata proofIndexes) external whenNotPaused nonReentrant {
        // TODO:check marketplace user reserves
        require(stakerTotalStakes[_msgSender()] >= amount, 'Invalid amount');
        userPools[] storage _userPools = stakerPools[_msgSender()];
        uint256 withdrawnAmount = amount;
        for (uint256 index = 0; index < proofIndexes.length; index++) {
            if (withdrawnAmount > 0) {
                require(
                    _userPools[proofIndexes[index]].amount > 0 &&
                        _userPools[proofIndexes[index]].registerBlock + _lockDuration <= block.timestamp,
                    'fund is locked or already released'
                );

                if (withdrawnAmount >= _userPools[proofIndexes[index]].amount) {
                    _userPools[proofIndexes[index]].amount = 0;
                    withdrawnAmount -= _userPools[proofIndexes[index]].amount;
                } else {
                    _userPools[proofIndexes[index]].amount -= withdrawnAmount;
                    withdrawnAmount = 0;
                }
            }
        }
        _safeTokenTransfer(_msgSender(), amount);
        stakerTotalStakes[_msgSender()] = stakerTotalStakes[_msgSender()] - amount;

        emit WithdrawFunds(_msgSender(), amount);
    }

    function emergencyWithdraw(uint256[] calldata proofIndexes) external whenPaused nonReentrant {
        // TODO:check marketplace user reserves
        require(stakerTotalStakes[_msgSender()] >= 0, 'Invalid amount');
        userPools[] storage _userPools = stakerPools[_msgSender()];
        uint256 withdrawnAmount;
        for (uint256 index = 0; index < proofIndexes.length; index++) {
            withdrawnAmount += _userPools[proofIndexes[index]].amount;
             _userPools[proofIndexes[index]].amount = 0;
        }
        _safeTokenTransfer(_msgSender(), withdrawnAmount);
        stakerTotalStakes[_msgSender()] = stakerTotalStakes[_msgSender()] - withdrawnAmount;

        emit WithdrawFunds(_msgSender(), withdrawnAmount);
    }

    function updateLockDuration(uint256 _duration) external onlyOwner whenPaused {
        require(_duration > 1 days,"Lock time must not be less than a day");
        _lockDuration = _duration;
        emit ChangeLockDuration(_duration);
    }

    //getpoolinfo
    function getReserves(address _owner) external view returns (uint256) {
        return stakerTotalStakes[_owner];
    }

    function getUserPoolLenght(address _user) external view returns (uint256) {
        return stakerPools[_user].length;
    }

    function lockDuration() external view returns (uint256) {
        return _lockDuration;
    }

    function stakingToken() external view returns (address) {
        return _stakingToken;
    }

    function getUserPoolDetails(address _user, uint256 index)
        external
        view
        returns (
            uint256 amount,
            bool unlocked,
            bool reservedToIDO
        )
    {
        amount = stakerPools[_user][index].amount;
        unlocked = stakerPools[_user][index].registerBlock + _lockDuration <= block.timestamp;
        reservedToIDO = stakerPools[_user][index].reservedToIDO;
    }

    function _getAllowance(address _owner) private view returns (uint256) {
        return IERC20(_stakingToken).allowance(_owner, address(this));
    }
}
