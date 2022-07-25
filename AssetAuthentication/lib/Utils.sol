// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Utils {

  function adjustUint256Array(uint256[] memory _target, uint256 _targetValue) public pure returns (uint256[] memory) {

    bool moving = false;

    // Remove tag id from asset metadata array.
    for(uint256 i = 0; i < _target.length; i++) {
      // If the tag was found shift tags down the array.
      if (moving) {
        // If the end of the array has been reached, set current position to 0.
        if (i == _target.length - 1) {
          _target[i] = 0;
        }
        else {
          // Shift tagids toward the front of the array.
          _target[i] = _target[i+1];
        }
      }
      else {
        // Have not found tag id yet, look for match.
        if (_target[i] == _targetValue) {
          // Match found!
          moving = true;
          _target[i] = _target[i+1];
        }
      }
    }

    return _target;
  }
}
