// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/Pausable.sol";
import "./lib/Constants.sol";

contract AuthenticatorsStorage is
  AccessControl,
  Constants,
  Pausable {

  /*
  Define general use named variable holders
  */
  mapping (string => uint256) _uint256Storage;
  mapping (string => uint32) _uint32Storage;
  mapping (string => address) _addressStorage;
  mapping (string => bool) _boolStorage;
  mapping (string => string) _stringStorage;
  mapping (string => bytes4) _bytesStorage;

  /**
  * @dev Various internally used uint256 variables
  */
  //mapping (string => uint256) _uint256Variables;

  /**
  * @dev Dependant contract addresses by key.
  */
  //mapping (string => address) _addressVariables;

  /**
  * @dev Category Ids. Expected that first 16 bytes are major category /
  * sub-category where as second 16 bytes are the category.
  * For example 10000000 might be major category fine art, 10010000 might be
  * sub-category classical paintings, 100F000 could be sub-category
  * sculptures, etc. These are just examples.
  */
  uint64 [] _categoryIds;

  struct MetaData {
    // Authenticator's Id for ease of cross reference.
    uint256 id;
    // Owner for ease of cross reference.
    address owner;
    // Authenticator rating.
    uint32 avgRating;
    // Current document hash code
    uint256 documentHash;
    // URL
    string url;
  }

  /**
  * @dev Authenticator's certifications.
  */
  mapping (uint256 => mapping (uint64 => bool)) _certifications;

  /**
  * @dev MetaData by Authenticator Id
  */
  mapping (uint256 => MetaData) _metaData;

  /**
  * @dev Authenticator Id by owner address.
  */
  mapping (address => uint256) _authenticatorByOwner;

  /**
  * @dev Get configuration value for key.
  *
  * Requirements:
  * - The caller must have admin role.
  */
  function getConfigurationValue (string memory _key) public view returns (uint256){
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AssetAuthenticators: must have admin role to set configuration.");

    return _uint256Storage[_key];
  }
  
  /**
  * @dev Get dependancy contract address for contract associated with _key.
  */
  function getDependancyAddress(string memory _key) public view returns(address){
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an administrator.");

    return _addressStorage[_key];
  }
  
  /**
  * @dev Set configuration value for key.
  *
  * Requirements:
  * - The caller must have admin role.
  */
  function setConfigurationValue (string memory _key, uint256 _val) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AssetAuthenticators: must have admin role to set configuration.");

    _uint256Storage[_key] = _val;
  }


  /**
  * @dev Set dependancy contract address for contract associated with _key.
  */
  function setDependancyAddress(string memory _key, address _addr) public {
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an administrator.");

    _addressStorage[_key] = _addr;
  }
}
