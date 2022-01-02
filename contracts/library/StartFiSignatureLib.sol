// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 * @author Eman Herawy, StartFi Team
 *@title  Singature library.
 *
 */
library StartFiSignatureLib {
    ///  see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].

    function verifyEIP712(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) internal pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    ///  see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].

    function verifyPersonalSign(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) internal pure returns (bool) {
        bytes32 hash = prefixed(hashStruct, DOMAIN_SEPARATOR);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash, bytes32 DOMAIN_SEPARATOR) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', DOMAIN_SEPARATOR, hash));
    }
}
