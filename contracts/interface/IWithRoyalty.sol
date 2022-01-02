// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IWithRoyalty {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address issuer, uint256 royaltyAmount);
}
