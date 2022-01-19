// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 
 *@title  StartFi WithAllocation
 * [ desc ] : contract to set allocation base and level for IDOs
 */

contract WithAllocation {
    /******************************************* decalrations go here ********************************************************* */
    uint256 private _baseAllocation = 40000 * 1 ether;
    uint256 internal _level1 = 2700 * 1 ether;
    uint256 internal _level2 = 7000 * 1 ether;
    uint256 internal _level3 = 14000 * 1 ether;
    uint256 internal _level1Max = _baseAllocation;
    uint256 internal _level2Max = _baseAllocation * 3;
    uint256 internal _level3Max = _baseAllocation * 6;

    function _updatelevelsAllocation(uint256 baseAllocation_) internal {
        require(baseAllocation_ != 0, 'Zero value is not accepted');
        _baseAllocation = baseAllocation_;
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
