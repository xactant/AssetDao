// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetStorage.sol";
//import "./lib/Constants.sol";

contract AssetAuthentication is AssetStorage {
  //Constants constants = new Constants();
  /**
   * @dev Grants `AUTH_ROLE` to the account that
   * deploys the contract.
   */
  constructor(string memory uri, address _currentAddress) AssetStorage(uri) {
    // Initial target contract address
    _addressVariables[T_CURRADDR] = _currentAddress;

    _roles[AUTH_ROLE][msg.sender] = true;

    _addressVariables[T_PAYMENT] = msg.sender;
  }

  /**
  * Provides a means for the contract owner to retrieve the current address.
  * can be used in a deployment scenario to save off the current address
  * so that changes could be rolled back to a previous version if needed.
  */
  function getTargetAddress () public view returns(address) {
    // Must be an administrator
    require(hasRole(AUTH_ROLE, msg.sender),
      T_NOTAUTH);

    return _addressVariables[T_CURRADDR];
  }


  /**
    * @dev Grants `role` to `account`.
    *
    * If `account` had not been already granted `role`, emits a {RoleGranted}
    * event.
    *
    * Requirements:
    *
    * - the caller must have admin role.
    */
  function grantRole(bytes32 role, address account) public {
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);

    if (!_roles[role][account]) {
      _roles[role][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  /**
    * @dev Revokes `role` from `account`.
    *
    * If `account` had been granted `role`, emits a {RoleRevoked} event.
    *
    * Requirements:
    *
    * - the caller must have admin role.
    */
  function revokeRole(bytes32 role, address account) public {
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);

    if (_roles[role][account]) {
      _roles[role][account] = false;
      emit RoleRevoked(role, account, msg.sender);
    }
  }

  /**
  * This method provides a means to update the target contract
  * so that the functionality of the contract is upgradable.
  */
  function upgrade(address _newAddress) public  {
    // Must be an administrator
    require(hasRole(AUTH_ROLE, msg.sender),
      T_NOTAUTH);

    _addressVariables[T_CURRADDR] = _newAddress;
  }

  /**
  * FALLBACK FUNCTION. All other calls are forwarded to the target contract.
  */
  fallback () external payable {
    address implementation = _addressVariables[T_CURRADDR];
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
