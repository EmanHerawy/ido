// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title mange start time for sale
abstract contract WithStartTime {
    uint256 private _startTimeSale;

    constructor(uint256 startTime_) {
        _startTimeSale = startTime_;
    }

    modifier isSaleStarted() {
        require(_startTimeSale <= block.timestamp && _startTimeSale != 0, 'Sale did not start yet');

        _;
    }
    modifier isSaleNotStarted() {
        require(_startTimeSale > block.timestamp || _startTimeSale == 0, 'Sale has started');

        _;
    }

    /// @notice Only woner can call it
    /// @dev  `__startTimeURI` must be more than the current time
    /// @param _startTime new _startTime
    function _setSaleStartTime(uint256 _startTime) internal {
        require(_startTime > block.timestamp, 'Can not set time back');
        _startTimeSale = _startTime;
    }

    function startTimeSale() external view returns (uint256) {
        return _startTimeSale;
    }
}
