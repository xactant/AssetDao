// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Constants.sol";

contract AssetStorage is Constants, ERC1155 {
  using SafeMath for uint256;

  string T_PAUSED = "PAUSED";

  mapping (bytes32 => mapping(address => bool)) _roles;

  /**
  * @dev Various internally used uint256 variables
  */
  mapping (string => uint256) _uint256Variables;

  /**
  * @dev Dependant contract addresses by key.
  */
  mapping (string => address) _addressVariables;

  mapping (string => bool) _boolVariables;

  // Asset Registered event.
  event AssetRegistered (uint256 assetId, uint64 categoryId, uint256 documentHash, address to);
  // Evaluation performed event.
  event EvaluationPerformed(uint256 assetId, uint256 documentHash,
    uint256 provenanceRating, uint256 averageProvenanceRating,
    uint256 currentFairMarketValue, uint256 averageFairMarketValue, uint256 authId );
  // Secondary Id added to Asset Event.
  event SecondaryIdAdded (uint256 assetId, uint256 id);
  // Secondary Id removed from Asset Event.
  event SecondaryIdRemoved (uint256 assetId, uint256 id);
  event HashUpdated (uint256 assetId, uint256 documentHash, address from);
  /**
  * @dev Emitted when `account` is granted `role`.
  *
  * `sender` is the account that originated the contract call, an admin role
  * bearer except when using {_setupRole}.
  */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
  * @dev Emitted when `account` is revoked `role`.
  *
  * `sender` is the account that originated the contract call:
  *   - if using `revokeRole`, it is the admin role bearer
  *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
  */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  event DebendancyUpdated(string key, address old, address addr, address by);

  event SettingUpdated(string key, uint256 prevVal, uint256 newVal, address by);

  event FlagUpdated(string key, bool prevVal, bool newVal, address by);

  event AssetFlagToggled(uint256 aId, bool flagged, address by);

  /**
   * @dev Define structure of Asset
   */
  struct Asset {
    // NFC Id for ease of cross reference.
    uint256 id;
    // Owner for ease of cross reference.
    address owner;
    // Last inventory timestamp
    uint256 inventoryTimestamp;
    // Current document hash code
    uint256 documentHash;
    // Last Provenance Rating
    uint256 pr;
    // Average Provenance Rating
    uint256 apr;
    // Last Provenance Rating timestamp
    uint256 prTimestamp;
    // Current Fair Market Value in WEI
    uint256 cfmv;
    // Average Current Fair Market Value in WEI
    uint256 avgCfmv;
    // Last Current Fair Market Value timestamp
    uint256 cfmvTimestamp;
    // Asset category
    uint64 categoryId;
    // Number of authenticators
    uint32 authenticators;
    // Keep a list of inventory tags asscociated with the asset.
    // The number should always be limited to 'MAX_INVENTORY_IDS' (configurable)
    // so that storage and gas fees are limited.
    // Current insert index.
    uint32 inventoryLinkIndex;
  }

  /**
   * @dev Asset discriptive data by Id.
   */
  mapping (uint256 => Asset) _assetMetaData;

  /**
   * @dev asset by secondary Id, used to lookup asset by secondary ID.
   */
  mapping (uint256 => uint256) _secondaryIds;

  /**
   * @dev Netadata URIs for assets
   */
  mapping (uint256 => string) _assetUri;

  /**
   * @dev inventory url by RFID Tag - optional used to allow an owner /
   * lender to associated a urls with each RFID tag associated with an asset. This
   * URL could trigger an RFID read, return last read information, link to a live
   * stream, etc.
   */
  mapping (uint256 => mapping(uint32 => string)) _inventoryUrls;

  /**
  * @dev Indicates which assets have been flagged a having inappropriate contact/
   */
  mapping (uint256 => bool) _flaggedAssets;

  constructor (string memory uri) ERC1155(uri) {

  }

  /**
   * @dev See {ERC1155-safeTransferFrom}.
   */
  function safeTransferFrom (
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  )
      public
      virtual
      override
  {
    // Perform transfer
    super.safeTransferFrom(from, to, id, amount, data);

    // Transfer complete - if this is an asset token (do not want to assume)
    // adjust metadata. Check asset id - if this is not an asset the ids will
    // not match.
    if (_assetMetaData[id].id == id) {
      _assetMetaData[id].owner = to;
    }
  }

  /**
   * @dev See {ERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom (
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  )
      public
      virtual
      override
  {
    // Perform batch transfer
    super.safeBatchTransferFrom(from, to, ids, amounts, data);

    // Update asset meta data.
    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      // Transfer complete - if this is an asset token (do not want to assume)
      // adjust metadata. Check asset id - if this is not an asset the ids will
      // not match.
      if (_assetMetaData[id].id == id) {
        _assetMetaData[id].owner = to;
      }
    }
  }


  /**
  * @dev Get configuration value for key.
  */
  function getConfigurationValue(string memory _key) public view returns (uint256) {
    return _uint256Variables[_key];
  }
  
  /**
  * @dev Get boolean value for key.
  */
  function getFlagValue(string memory _key) public view returns (bool) {
    return _boolVariables[_key];
  }
  
  /**
  * @dev Get dependancy contract address for contract associated with _key.
  */
  function getDependancyAddress(string memory _key) public view returns(address){
    return _addressVariables[_key];
  }
  
  /**
    * @dev Returns `true` if `account` has been granted `role`.
    */
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return _roles[role][account];
  }

  function confirmNotPaused() public view {
    bool v = getFlagValue("PAUSED");
    require(v == false, T_PAUSED);
  }

  /**
  * @dev Get configuration value for key.
  *
  * Requirements:
  * - Configuration key must exist.
  * - The caller must have admin role.
  */
  function setConfigurationValue (string memory _key, uint256 _val) public {
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);
    uint256 prevVal = _uint256Variables[_key]; 
    _uint256Variables[_key] = _val;

    emit SettingUpdated(_key, prevVal, _val, msg.sender);
  }
  
  /**
  * @dev Get boolean value for key.
  *
  * Requirements:
  * - Configuration key must exist.
  * - The caller must have admin role.
  */
  function setFlagValue (string memory _key, bool _val) public {
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);
    bool prevVal = _boolVariables[_key];
    _boolVariables[_key] = _val;

    emit FlagUpdated(_key, prevVal, _val, msg.sender);
  }

  /**
  * @dev Set dependancy contract address for contract associated with _key.
  */
  function setDependancyAddress(string memory _key, address _addr) public {
    // Must be an administrator
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);
    address oldVal = _addressVariables[_key];
    _addressVariables[_key] = _addr;

    emit DebendancyUpdated(_key, oldVal, _addr, msg.sender);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
      return interfaceId == type(IERC1155).interfaceId
          || super.supportsInterface(interfaceId);
  }

  /**
  * @dev Withdraw funds from the contract.
  * Requirements:
  *   Sender must be a designated payee
  *   Available balance must be greater to or equal to amount specified.
  */
  function withdraw(uint256 _amt) public {
    confirmNotPaused();
    require (_addressVariables[T_PAYADDRESS] == msg.sender, "PAYEE");
    require (_uint256Variables[T_PAYMENT] >= _amt, T_AMOUNT);

    if (_amt > 0) {
      _uint256Variables[T_PAYMENT] = _uint256Variables[T_PAYMENT].sub(_amt);

      // Unlike Send or Transfer this forwards all available gas. Be sure to check the return value!
      (bool success, ) = _addressVariables[T_PAYADDRESS].call{value:_amt}("");
      require(success, "FAILED");
    }
  }

  function uri(uint256 _aId) public view virtual override returns (string memory) {
    if (bytes(_assetUri[_aId]).length > 0) {
      return _assetUri[_aId];
    }

    return uri(_aId);
  }

  function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  )
      internal virtual override(ERC1155) //, ERC1155Pausable)
  {
      confirmNotPaused();
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  

  function processPayment(bool _key, uint256 _amt) internal {
    uint256 remainder = msg.value;
    uint256 amtPaid = 0;
    
    if (_key && _amt > 0) {
      require (remainder >= _amt, T_AMOUNT);
      remainder = remainder.sub(_amt);
      amtPaid = amtPaid.add(_amt);
    
      _uint256Variables[T_PAYMENT] = _uint256Variables[T_PAYMENT].add(amtPaid);

      if (remainder > 0) {
        // Unlike Send or Transfer this forwards all available gas. Be sure to check the return value!
        (bool success, ) = msg.sender.call{value: remainder}("");
        require(success, "REFUND");
      }
    }
  }

  function vetPayment (uint8 _payKey) internal {
    if (_payKey == PAY_REG) {
      processPayment(_boolVariables["REQ_REG_CHARGE"], _uint256Variables["REG_PRICE"]);
    }
    else if (_payKey == PAY_ADD_TAG) {
      processPayment(_boolVariables["REQ_ADD_TAG_CHARGE"], _uint256Variables["ADD_TAG_PRICE"]);
    }
    else if (_payKey == PAY_EVAL) {
      processPayment(_boolVariables["REQ_PERF_EVAL_CHARGE"], _uint256Variables["PERF_EVAL_PRICE"]);
    }
    else if (_payKey == PAY_INV) {
      processPayment(_boolVariables["REQ_PERF_INV_CHARGE"], _uint256Variables["PERF_INV_PRICE"]);
    }
  }
}
