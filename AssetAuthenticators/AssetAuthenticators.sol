// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthenticatorsStorage.sol";

/**
* The AssetAuthenticators contract is a proxy contract that wraps a target
* contract, enabling the target to be versioned.
*/
contract AssetAuthenticators is AuthenticatorsStorage {

  constructor(string memory uri, address _currentAddress) {
    // Initial target contract address
    _addressStorage["CURRENT_ADDRESS"] = _currentAddress;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    _setupRole(AUTH_ROLE, _msgSender());

    _stringStorage["DEFAULT_URL"] = uri;
    _uint256Storage["AUTHENTICATOR_ID"] = 0xDECAF;
}

  /**
  * Provides a means forthe contract owner to retrieve the current address.
  * can be used in a deployment scenario to save off the current address
  * so that changes could be rolled back to a previous version if needed.
  */
  function getTargetAddress () public view returns(address) {
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Must be an administrator.");

    return _addressStorage["CURRENT_ADDRESS"];
  }

  /**
  * This method provides a means to update the target contract
  * so that the functionality of the contract is upgradable.
  */
  function upgrade(address _newAddress) public  {
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
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
