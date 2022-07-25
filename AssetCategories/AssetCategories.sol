// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CategoriesStorage.sol";
import "./lib/SafeMath64.sol";

/**
* The AssetCategories contract is a proxy contract that wraps a target
* contract, enabling the target to be versioned.
*/
contract AssetCategories is CategoriesStorage {
  using SafeMath for uint256;
  //using Constants for Constants;

  constructor(address _currentAddress) {
    // Initial target contract address
    _addressStorage["CURRENT_ADDRESS"] = _currentAddress;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);

    // Setup initial Reserved Categories
    _categoryIds.push(RESERVED_CERTIFICATION);
    _categoryIds.push(REGISTRANT_CERTIFICATION);
    _categoryLabels[RESERVED_CERTIFICATION] = "RESERVED";
    _categoryLabels[REGISTRANT_CERTIFICATION] = "REGISTRAR CERTIFICATION";
}

  /**
  * Provides a means forthe contract owner to retrieve the current address.
  * can be used in a deployment scenario to save off the current address
  * so that changes could be rolled back to a previous version if needed.
  */
  function getTargetAddress () public view returns(address) {
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Must be an administrator.");

    return _addressStorage["CURRENT_ADDRESS"];
  }

  /**
  * This method provides a means to update the target contract
  * so that the functionality of the contract is upgradable.
  */
  function upgrade(address _newAddress) public  {
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Must be an administrator.");

    _addressStorage["CURRENT_ADDRESS"] = _newAddress;
  }

  /**
  * FALLBACK FUNCTION. All other calls are forwarded to the target contract.
  */
  fallback () external payable {
    address implementation = _addressStorage["CURRENT_ADDRESS"];
    require(implementation != address(0));
    bytes memory data = msg.data;

    //DELEGATECALL EVERY FUNCTION CALL
    assembly {
      let result := delegatecall(gas(), implementation, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize()
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 {revert(ptr, size)}
      default {return(ptr, size)}
    }
  }
}
