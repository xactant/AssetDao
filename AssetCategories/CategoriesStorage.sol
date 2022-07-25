// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Pausable.sol";
import "./lib/Constants.sol";

contract CategoriesStorage is
  AccessControl,
  Constants,
  Pausable {

  /**
  * @dev Category Ids. Expected that first 16 bytes are major category /
  * sub-category where as second 16 bytes are the category.
  * For example 10000000 might be major category fine art, 10010000 might be
  * sub-category classical paintings, 100F000 could be sub-category
  * sculptures, etc. These are just examples.
  *
  * Major / Minor 0x0 is reserverd for internal categories.
  */
  uint256 [] _categoryIds;

  /**
  * @dev Category labels these will be in default language internationization
  * should be accomplished by dApp developers.
  */
  mapping (uint256 => string) _categoryLabels;

  /*
  Define general use named variable holders
  */
  mapping (string => uint256) _uint256Storage;
  mapping (string => uint32) _uint32Storage;
  mapping (string => address) _addressStorage;
  mapping (string => bool) _boolStorage;
  mapping (string => string) _stringStorage;
  mapping (string => bytes4) _bytesStorage;

  mapping (uint256 => bool) _cat_exist;
  mapping (uint256 => bool) _majors_exist;
  mapping (uint256 => mapping(uint256 => bool)) _major_minors_exist;
  mapping (uint256 => mapping(uint256 => bool)) _majorminor_subs_exist;
  mapping (uint256 => mapping(uint256 => bool)) _majorminorsub_cats_exist;

  uint256 [] _majors;
  mapping (uint256 => uint256[]) _major_minors;
  mapping (uint256 => uint256[]) _majorminor_subs;
  mapping (uint256 => uint256[]) _majorminorsub_cats;

  /**
  * @dev Get configuration value for key.
  *
  * Requirements:
  * - Configuration key must exist.
  * - The caller must have admin role.
  */
  function setConfigurationValue (string memory _key, uint256 _val) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AssetAuthentication: must have admin role to set configuration.");

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

  function getMajor(uint256 _cat) internal pure returns(uint256) {
    return _cat & CERT_MAJ_MASK;
  }

  function getMajorMinor(uint256 _cat) internal pure returns(uint256) {
    return _cat & CERT_MAJ_MIN_MASK;
  }

  function getMajorMinorSub(uint256 _cat) internal pure returns(uint256) {
    return _cat & CERT_MAJ_MIN_SUB_MASK;
  }
}
