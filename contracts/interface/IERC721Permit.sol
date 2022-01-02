// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC721Permit {
    function permit(
        address target,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);
}
