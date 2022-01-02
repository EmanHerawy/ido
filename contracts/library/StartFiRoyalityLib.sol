// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import '../interface/IWithRoyalty.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

library StartFiRoyalityLib {
    bytes4 constant RORALTY_INTERFACE = 0x2a55205a;

    /**
     *@notice  only if this contract has royaltyInfo function
     *@dev  call the royaltyInfo function in nft contract
     *@param _NFTContract NFT contract address
     *@param _tokenId token id
     *@param _value  token price
     *@return issuer original issuer address
     *@return royaltyAmount  the issuer total amount of tokens that he should recieve based on his share
     */
    function _getRoyaltyInfo(
        address _NFTContract,
        uint256 _tokenId,
        uint256 _value
    ) internal view returns (address issuer, uint256 royaltyAmount) {
        (issuer, royaltyAmount) = IWithRoyalty(_NFTContract).royaltyInfo(_tokenId, _value);
    }

    /**
     *
     * @dev  interal function to check if any gevin contract has supportsInterface See {IERC165-supportsInterface}.
     * @param _NFTContract NFT contract address
     * @return true if this NFT contract support royalty, false if not
     */
    function _supportRoyalty(address _NFTContract) internal view returns (bool) {
        try IERC165(_NFTContract).supportsInterface(RORALTY_INTERFACE) returns (bool isRoyaltySupported) {
            return isRoyaltySupported;
        } catch {
            return false;
        }
    }
}
