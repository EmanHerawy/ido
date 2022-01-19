pragma solidity 0.8.4;

//SPDX-License-Identifier: AGPL-3.0-only
/*
        ,                                                                       
  %%%%%%%%%%%%%%                                                      %%%%%%%   
 %%%           ./    %%                                %%%          %%%       %%
%%%   ,,,,,,         %%,,,,,,.    ,,,      ,    ,,,,   %%%,,,,,,   %%%%%%%%%*   
 %%%       ,,,,,     %%       %%%%%%%%%%   %%%%%%%/    %%%      %%%%%%%%%#    %%
  %%%%%*      ,,,    %%      %%%       %%  %%%         %%%         (%%        %%
      ,%%%%%   ,,,   %%%     %%%       %%  %%%         %%%         (%%        %%
  ,           ,,,     %%%%%%  .%%%%%%% %%  %%%          #%%%%%(    (%%        %%
  ,,,,,,,,,,,,,,                                                                */

import './extensions/WithLimitedSupply.sol';
import './extensions/WithTokenPayment.sol';
import './extensions/WithStartTime.sol';
import './extensions/PausableERC20.sol';
import './extensions/WithWhiteListSupport.sol';
import './extensions/WithAllocation.sol';
import './extensions/WithStakingPool.sol';

interface IStartfiIDO {
    function unstakeBatch(address[] memory users) external;
}

contract AirdropedStartfiIDOWithStakingMigrated is
    WithWhiteListSupport,
    WithAllocation,
    WithLimitedSupply,
    WithStartTime,
    PausableERC20,
    WithStakingPool,
    WithTokenPayment
{
    /**************************libraries ********** */

    /***************************Declarations go here ********** */
    IStartfiIDO _idoMigrated;
    mapping(address => uint256) public migrateStaker;
    mapping(address => bool) public isMigratedStaker;
    event AirDropRequested(address beneficiary, uint256 amount, uint256 price);
    event stakerMigrated(address beneficiary, uint256 amount);

    // modifier
    /******************************************* constructor goes here ********************************************************* */
    constructor(
        uint256 startTimeSale_,
        uint256 mintPrice_,
        uint256 maxSupply_,
        uint256 lockDuration_,
        address[] memory wallets_,
        address _paymentToken,
        address token_,
        address owner_
    )
        WithLimitedSupply(maxSupply_)
        WithTokenPayment(wallets_, _paymentToken, mintPrice_)
        PausableERC20(owner_)
        WithStartTime(startTimeSale_)
        WithStakingPool(token_, lockDuration_)
    {}

    /******************************************* read state functions go here ********************************************************* */

    /// @notice caller should pay the required price
    /// @dev  called only when sale is started
    /// @dev  called only when not paused
    /// @dev  `allowance` can't zero
    /// @dev must not xceed the cap
    /// emit Transfer
    function mint() external whenNotPaused isSaleStarted {
        if (whilteListStatus()) {
            require(isWhiteListed(_msgSender()), 'Must be white listed');
        }
        // get max amount user can buy
        uint256 userTotalStakes = getReserves(_msgSender());
        require(userTotalStakes > 0, 'No Participation with zero stakes');

        uint256 totalPrice = _getAllowance(_msgSender());
        require(totalPrice >= mintPrice(), 'Insufficient price value');
        uint256 userTotalAllocation = _userAllocation[_msgSender()] + totalPrice;

        uint256 _amount = (totalPrice * 1 ether) / mintPrice();

        if (userTotalStakes <= _level1) {
            require(userTotalAllocation <= _level1Max, 'allocation exceded');
        } else if (userTotalStakes <= _level2) {
            require(userTotalAllocation <= _level2Max, 'allocation exceded');
        } else {
            require(userTotalAllocation <= _level3Max, 'allocation exceded');
        }
        require(_amount <= availableTokenCount(), 'Insufficient contract balance');
        require(_transferPayment(_msgSender(), totalPrice), 'Payment failed');
        _increase(_amount);
        _userAllocation[_msgSender()] = userTotalAllocation;
        emit AirDropRequested(_msgSender(), _amount, totalPrice);
    }

    /// @notice Only owner can call it
    /// @dev  `__startTimeURI` must be more than the current time
    /// @param _startTime new _startTime
    function updateSaleStartTime(uint256 _startTime) external onlyOwner isSaleNotStarted {
        _setSaleStartTime(_startTime);
    }

    function updatelevelsAllocation(uint256 baseAllocation_) external onlyOwner whenPaused {
        _updatelevelsAllocation(baseAllocation_);
    }

    function setMintPrice(uint256 price_) external onlyOwner whenPaused {
        _setMintPrice(price_);
    }

    /**
     * @dev Withdraw accumulated balance for `wallets`
     *
     */
    function withdraw() external onlyOwner {
        _withdraw();
    }

    function updateLockDuration(uint256 _duration) external onlyOwner whenPaused {
        _updateLockDuration(_duration);
    }

    function toggleWhiteListStatus() external onlyOwner {
        _toggleWhiteListStatus();
    }

    function setWhiteList(address[] memory _list) external onlyOwner {
        _setWhiteList(_list);
    }

    function setMigratedIDO(address idoMigrated) external onlyOwner {
        require(idoMigrated != address(0), 'Zero address is not allowed');
        _idoMigrated = IStartfiIDO(idoMigrated);
    }

    // deposit
    function deposit(uint256 amount) external whenNotPaused {
        require(amount >= _level1, 'Amount is less the minumum');
        _deposit(_msgSender(), amount);
    }

    // withdraw
    function unstake(uint256 amount) external whenNotPaused {
        // if from list , untake from the old contract
        if (migrateStaker[_msgSender()] > 0 && !isMigratedStaker[_msgSender()]) {
            address[] memory stakers = new address[](1);
            stakers[0] = _msgSender();

            _idoMigrated.unstakeBatch(stakers);
            isMigratedStaker[_msgSender()] = true;
        } else {
            require(isUnLockedFund(_msgSender()), 'Fund is locked now');
            _unstake(_msgSender(), amount);
        }
    }

    function unstakeBatch(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            require(users[index] != address(0), 'Zero Address is not allowed');
            _unstake(users[index], getReserves(users[index]));
        }
    }

    function migrateStakers(address[] memory users, uint256[] memory amounts) external onlyOwner {
        require(users.length == amounts.length);
        for (uint256 index = 0; index < users.length; index++) {
            require(users[index] != address(0), 'Zero Address is not allowed');
            require(amounts[index] != 0, 'Zero Address is not allowed');
            migrateStaker[users[index]] = amounts[index];
            stakerTotalStakes[users[index]] += amounts[index];

            emit stakerMigrated(users[index], amounts[index]);
        }
    }

    function emergencyUnstake(address user, uint256 amount) external whenPaused {
        _unstake(user, amount);
    }
}
