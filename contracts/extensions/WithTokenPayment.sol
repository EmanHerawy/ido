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
contract WithTokenPayment is ReentrancyGuard {
    /**************************libraries ********** */

    /***************************Declarations go here ********** */
    // stat var
    uint256 private _mintPrice;

    IERC20 private immutable _erc20Token;
    address[] private _wallets;

    // event
    event UpdateMintPrice(uint256 newParice);
    event Withdrawn(address payee, uint256 amount);

    // modifier

    /******************************************* constructor goes here ********************************************************* */
    constructor(
        address[] memory wallets_,
        address token_,
        uint256 mintPrice_
    ) {
        _wallets = wallets_;
        _mintPrice = mintPrice_;

        _erc20Token = IERC20(token_);
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* modify state functions go here ********************************************************* */
    function _getAllowance(address owner) internal view returns (uint256) {
        return _erc20Token.allowance(owner, address(this));
    }

    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function _transferPayment(address sender, uint256 amount) internal nonReentrant returns (bool) {
        return _erc20Token.transferFrom(sender, address(this), amount);
    }

    function getWallets() external view returns (address[] memory) {
        return _wallets;
    }

    function getBalanceOf(address user) internal view returns (uint256) {
        return _erc20Token.balanceOf(user);
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
        uint256 share = _erc20Token.balanceOf(address(this)) / _wallets.length;
        require(share > 0, "Can't split zero shares");
        for (uint256 index = 0; index < _wallets.length; index++) {
            emit Withdrawn(_wallets[index], share);

            require(_erc20Token.transfer(_wallets[index], share), "Couldn't transfer token");
        }
    }

    function _setMintPrice(uint256 mintPrice_) internal {
        require(mintPrice_ > 0, 'Zero value is not allowed');
        _mintPrice = mintPrice_;
        emit UpdateMintPrice(mintPrice_);
    }
}
