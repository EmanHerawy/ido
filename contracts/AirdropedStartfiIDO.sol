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

import '@openzeppelin/contracts/utils/Strings.sol';
import './extensions/WithLimitedSupply.sol';
import './extensions/WithTokenPayment.sol';
import './extensions/WithStartTime.sol';
import './extensions/PausableERC20.sol';
import './extensions/WithWhiteListSupport.sol';
import './interface/IStartFiStakes.sol';

contract AirdropedStartfiIDO is
    WithWhiteListSupport,
    WithLimitedSupply,
    WithStartTime,
    PausableERC20,
    WithTokenPayment
{
    /**************************libraries ********** */
    using Strings for uint256;
    /***************************Declarations go here ********** */
    IStartFiStakes stakes;
    uint256 private _baseAllocation = 500000 * 1 ether;
    uint256 _level1 = 2700 * 1 ether;
    uint256 _level2 = 7000 * 1 ether;
    uint256 _level3 = 14000 * 1 ether;
    uint256 _level1Max = _baseAllocation * 1;
    uint256 _level2Max = _baseAllocation * 3;
    uint256 _level3Max = _baseAllocation * 6;
    event AirDropRequested(address beneficiary, uint256 amount, uint256 price);

    // modifier
    /******************************************* constructor goes here ********************************************************* */
    constructor(
        uint256 startTimeSale_,
        uint256 mintPrice_,
        uint256 maxSupply_,
        address[] memory wallets_,
        address _paymentToken,
        address staking,
        address owner_
    )
        WithLimitedSupply(maxSupply_)
        WithTokenPayment(wallets_, _paymentToken, mintPrice_)
        PausableERC20(owner_)
        WithStartTime(startTimeSale_)
    {
        stakes = IStartFiStakes(staking);
    }

    /******************************************* read state functions go here ********************************************************* */

    /// @notice caller should pay the required price
    /// @dev  called only when sale is started
    /// @dev  called only when not paused
    /// @dev  `_amount` can't zero
    /// @dev must not xceed the cap
    /// @param _amount number of token to be minted
    /// @param proofIndexes user pools index to be used, index should only be used once
    /// emit Transfer
    function mint(uint256 _amount, uint256[] calldata proofIndexes)
        external
        whenNotPaused
        isSaleStarted
        isWithinCapLimit(_amount)
    {
        if (whilteListStatus()) {
            require(isWhiteListed(_msgSender()), 'Must be white listed');
        }
        // get max amount user can buy
        require(_amount > 0, 'invalid_amount');
        uint256 tokenAmount;
        uint256 totalStakesForGivenIndexes = stakes.validateStakes(_msgSender(), proofIndexes);
        require(totalStakesForGivenIndexes > 0, 'No Participation with zero stakes');
        if (totalStakesForGivenIndexes <= _level1) {
            tokenAmount = _amount > _level1Max ? _level1Max : _amount;
        } else if (totalStakesForGivenIndexes <= _level2) {
            tokenAmount = _amount > _level2Max ? _level2Max : _amount;
        } else {
            tokenAmount = _amount > _level3Max ? _level3Max : _amount;
        }
        uint256 _price = mintPrice() * tokenAmount;
        require(tokenAmount <= availableTokenCount(), 'Insufficient contract balance');
        require(_price <= _getAllowance(_msgSender()), 'Insufficient price value');
        require(_transferPayment(_msgSender(), _price), 'Payment failed');
        _increase(tokenAmount);
        emit AirDropRequested(_msgSender(), tokenAmount, _price);
    }

    /// @notice Only owner can call it
    /// @dev  `__startTimeURI` must be more than the current time
    /// @param _startTime new _startTime
    function updateSaleStartTime(uint256 _startTime) external onlyOwner isSaleNotStarted {
        _setSaleStartTime(_startTime);
    }

    function update_levelsAllocation(uint256 baseAllocation_) external onlyOwner whenPaused {
        require(baseAllocation_ != 0, 'Zero value is not accepted');
        _baseAllocation = baseAllocation_;
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

    function toggleWhiteListStatus() external onlyOwner {
        _toggleWhiteListStatus();
    }

    function setWhiteList(address[] memory _list) external onlyOwner {
        _setWhiteList(_list);
    }

    function baseAllocation() external view returns (uint256) {
        return _baseAllocation;
    }

    function level1() external view returns (uint256, uint256) {
        return (_level1, _level1Max);
    }

    function level2() external view returns (uint256, uint256) {
        return (_level2, _level2Max);
    }

    function level3() external view returns (uint256, uint256) {
        return (_level3, _level3Max);
    }
}
