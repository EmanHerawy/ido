// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

 
 /// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupply {
 
    // Keeps track of how many we have minted
    uint256 private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private immutable _maxSupply;

    modifier isWithinCapLimit(uint256 _numberOfERC20s) virtual {
        require((tokenCount() + _numberOfERC20s) <= _maxSupply, 'Purchase exceeds max supply');
        _;
    }


    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, 'Requested number of tokens not available');
        _;
    }

    /// Instanciate the contract
    /// @param maxSupply_ how many tokens this collection should hold
    constructor(uint256 maxSupply_) {
        _maxSupply = maxSupply_;
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
 
        _tokenCount+=amount;

        return _tokenCount;
    }
}
