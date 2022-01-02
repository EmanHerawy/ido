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
import '../../extensions/WithLimitedSupply.sol';
import '../../extensions/WithTokenPayment.sol';
import '../../extensions/WithStartTime.sol';
import '../../extensions/PausableERC20.sol';

contract AnyERC20Launchpad is WithLimitedSupply, WithStartTime, PausableERC20, WithTokenPayment {
    /**************************libraries ********** */
    using Strings for uint256;
    /***************************Declarations go here ********** */

    // event
    event AirDropRequested(address beneficiary, uint256 amount);

    // modifier
    /******************************************* constructor goes here ********************************************************* */
    constructor(
        uint256 startTimeSale_,
        uint256 mintPrice_,
        uint256 maxSupply_,
        address[] memory wallets_,
        address _token,
        address owner_
    )
        WithLimitedSupply(maxSupply_)
        WithTokenPayment(wallets_, _token, mintPrice_)
        PausableERC20(owner_)
        WithStartTime(startTimeSale_)
    {
    }

    /******************************************* read state functions go here ********************************************************* */

    /// @notice caller should pay the required price
    /// @dev  called only when sale is started
    /// @dev  called only when not paused
    /// @dev  `_numberOfERC20s` can't zero
    /// @dev must not xceed the cap
    /// @param _numberOfERC20s number of ERC20 to be minted
    /// emit Transfer
    function mint(uint256 _numberOfERC20s) external whenNotPaused isSaleStarted isWithinCapLimit(_numberOfERC20s) {
        require(_numberOfERC20s > 0, 'invalid_amount');
        uint256 _price = mintPrice() * _numberOfERC20s;
        require(_price <= _getAllowance(_msgSender()), 'ERC20 value not correct');
        _increase(_numberOfERC20s);
        require(_transferPayment(_msgSender(), _price), 'Payment failed');
        emit AirDropRequested(_msgSender(), _numberOfERC20s);
    }

    /// @notice Only owner can call it
    /// @dev  `__startTimeURI` must be more than the current time
    /// @param _startTime new _startTime
    function updateSaleStartTime(uint256 _startTime) external onlyOwner isSaleNotStarted {
        _setSaleStartTime(_startTime);
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
}
