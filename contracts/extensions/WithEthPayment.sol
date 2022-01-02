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

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title  WithEthPayment contract
//
/// @author startfi team
contract WithEthPayment is ReentrancyGuard {
    /**************************libraries ********** */
    using Address for address payable;
    uint256 private _mintPrice;

    /***************************Declarations go here ********** */
    // stat var

    address[] private _wallets;

    // event
    event UpdateMintPrice(uint256 newParice);
    event Withdrawn(address payee, uint256 amount);

    // modifier
    /******************************************* constructor goes here ********************************************************* */
    constructor(address[] memory wallets_, uint256 mintPrice_) {
        _wallets = wallets_;
        _mintPrice = mintPrice_;
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* modify state functions go here ********************************************************* */

    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function getWallets() external view returns (address[] memory) {
        return _wallets;
    }

    /**
     * @dev Withdraw accumulated balance for a wallet 1 and wallet 2, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     */
    function _withdraw() internal virtual nonReentrant {
        uint256 share = address(this).balance / _wallets.length;
        require(share > 0, "Can't split zero shares");
        for (uint256 index = 0; index < _wallets.length; index++) {
            emit Withdrawn(_wallets[index], share);
            payable(_wallets[index]).sendValue(share);
        }
    }

    function _setMintPrice(uint256 mintPrice_) internal {
        require(mintPrice_ > 0, 'Zero value is not allowed');
        _mintPrice = mintPrice_;
        emit UpdateMintPrice(mintPrice_);
    }
}
