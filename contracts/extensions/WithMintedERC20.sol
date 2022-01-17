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

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/// @title  WithTokenPayment contract
//
contract WithMintedERC20 is ReentrancyGuard {
    /**************************libraries ********** */

    /***************************Declarations go here ********** */
    // stat var
 
    IERC20 private immutable _erc20Token;
 
   
    // modifier

    /******************************************* constructor goes here ********************************************************* */
    constructor(
        address token_
    ) {
 
        _erc20Token = IERC20(token_);
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* modify state functions go here ********************************************************* */
   



    function _transferToken(address sender, uint256 amount) internal nonReentrant returns (bool) {
        return _erc20Token.transfer(sender, amount);
    }
    function _balance() internal nonReentrant returns (uint256) {
        return _erc20Token.balanceOf(address(this));
    }

   

}
