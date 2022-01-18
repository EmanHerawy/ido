// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';

/// @author 1001.digital - edit mhjey - edit
/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;

    // Keeps track of how many we have minted
    uint256 private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private immutable _maxSupply;

    modifier isWithinCapLimit(uint256 tokenAmount) virtual {
        require((_tokenCount + tokenAmount) <= _maxSupply, 'Purchase exceeds max supply');
        _;
    }
    /// @dev Check whether another token is still available
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, 'No more tokens available');
        _;
    }

    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, 'Requested number of tokens not available');
        _;
    }

    /// Instanciate the contract
    /// @param totalSupply_ how many tokens this collection should hold
    constructor(uint256 totalSupply_) {
        _maxSupply = totalSupply_;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount() public view returns (uint256) {
        return _tokenCount;
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount() public view returns (uint256) {
        return maxSupply() - tokenCount();
    }


      /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function _increase(uint256 amount) internal virtual ensureAvailabilityFor(amount) returns (uint256) {
        _tokenCount += amount;

        return _tokenCount;
    }
}
