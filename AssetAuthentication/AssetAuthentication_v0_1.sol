// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetStorage.sol";
import "./lib/SafeMath32.sol";
import "./lib/InterContractService.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IAuthenticators.sol";
import "./interfaces/ICategories.sol";

/// @title Implementation of an A2P2 Asset contract
/// @author David B. Goodrich
contract AssetAuthentication_v0_1 is AssetStorage, InterContractService, IAssets {
  using SafeMath32 for uint32;

  constructor() AssetStorage("not used") {
  }

  /// @notice Enable asset owner to link an secondary id to an asset.
  /// @dev Caller must be Asset Owner or ApprovedForAll
  /// @param _aId - main id of the target asset.
  /// @param _id - new secondary id to link to the asset.
  function addSecondaryId (uint256 _aId, uint256 _id) public payable override {
    confirmNotPaused();
    // Asset must exist.
    assetMustExist (_aId);

    // Sender must be asset owner or approved for all.
    isApproved(_aId);

    // Process Payment
    vetPayment(PAY_ADD_TAG);

    // Map assett to new inventory Tag Id.
    _secondaryIds[_id] = _aId;

    emit SecondaryIdAdded (_aId, _id);
  }

  /// @notice Provides a way to retieve the token's internal data.
  /// @param _aId - main id of the target asset.
  function getAssetMetadata (uint256 _aId) public override view
    returns(uint256 inventoryTimestamp, uint256 documentHash, uint256 pr,
      uint256 apr, uint256 prTimestamp, uint256 cfmv, uint256 avgCfmv,
      uint256 cfmvTimestamp, uint64 categoryId, uint32 secondaryIdIndex, bool isFlagged, uint256 uId) {

      inventoryTimestamp = _assetMetaData[_aId].inventoryTimestamp;
      documentHash = _assetMetaData[_aId].documentHash;
      pr = _assetMetaData[_aId].pr;
      apr = _assetMetaData[_aId].apr;
      prTimestamp = _assetMetaData[_aId].prTimestamp;
      cfmv = _assetMetaData[_aId].cfmv;
      avgCfmv = _assetMetaData[_aId].avgCfmv;
      cfmvTimestamp = _assetMetaData[_aId].cfmvTimestamp;
      categoryId = _assetMetaData[_aId].categoryId;
      secondaryIdIndex = _assetMetaData[_aId].inventoryLinkIndex;
      isFlagged = _flaggedAssets[_aId];
      uId = _assetMetaData[_aId].id;
  }

  //// @notice Provide a way to retrieve the asset Id of an asset linked with specified secondary Id.
  /// @param _id A secondary id linked to an asset.
  /// @return id of the linked asset
  function getAssetIdBySecondaryId(uint256 _id) public override view returns(uint256) {
    return _secondaryIds[_id];
  }

  /// @notice Retrieve a URL (if one exists) that is associated with a secondary id
  /// @param _aId Id of target asset.
  /// @param _id Secondary id linked to an asset.
  /// @return A URL (if on exists) that is associated with the target secondary id.
  function getInventoryUrl (uint256 _aId, uint32 _id) public override view returns(string memory) {
    return _inventoryUrls[_aId][_id];
  }

  /// @notice Flag as asset as being inappropriate in most situations.
  /// @dev Caller must have AUTH_ROLE.
  /// @dev Asset must exist
  /// @param _aId Id of target asset.
  function flagAsset(uint256 _aId) public override {
    confirmNotPaused();
    // Must have AUTH_ROLE
    require(hasRole(AUTH_ROLE, msg.sender), T_NOTAUTH);
    // Asset must exist.
    assetMustExist (_aId);
    // Toggle asset flag
    _flaggedAssets[_aId] = !_flaggedAssets[_aId];

    emit AssetFlagToggled(_aId, _flaggedAssets[_aId], msg.sender);
  }

  /// @notice Persists Provernance evaluation and Value evlauations of an asset.
  /// @dev Caller must be certified to perform evaluation for target asset's category.
  /// @dev Asset must exist
  /// @param _aId Id of target asset.
  /// @param _hash keccak-256 hash of the base Metadata document.
  /// @param _provenanceRating Zero value ignored - if GT 0, recorded as the provenance rating for the target
  function performEvaluation(uint256 _aId, uint256 _hash,
    uint256 _provenanceRating, uint256 _averageProvenanceRating,
    uint256 _currentFairMarketValue, uint256 _averageFairMarketValue) public payable override {
    confirmNotPaused();
    // Asset must not exist.
    assetMustExist(_aId);
    uint64 categoryId = _assetMetaData[_aId].categoryId;

    // Process Payment
    vetPayment(PAY_EVAL);

    // Get Authenticator Id
    uint authId = InterContractService._authenticatorId(_addressVariables[T_CATKEY], msg.sender);

    // Update the token's metadata record
    _assetMetaData[_aId].inventoryTimestamp = block.timestamp;
    _assetMetaData[_aId].documentHash = _hash;

    if(_provenanceRating > 0) {
      // Authenticator must be certified
      checkCertified(_boolVariables["REQ_PERF_EVAL_AUTH"], authId, categoryId, AUTHENTICATION_SUB_CERTIFICATION);

      _assetMetaData[_aId].pr = _provenanceRating;
      _assetMetaData[_aId].apr = _averageProvenanceRating;
      _assetMetaData[_aId].prTimestamp = block.timestamp;
    }

    if(_currentFairMarketValue > 0) {
      // Authenticator must be certified
      checkCertified(_boolVariables["REQ_PERF_EVAL_AUTH"], authId, categoryId, VALUATION_SUB_CERTIFICATION);

      _assetMetaData[_aId].cfmv = _currentFairMarketValue;
      _assetMetaData[_aId].avgCfmv = _averageFairMarketValue;
      _assetMetaData[_aId].cfmvTimestamp = block.timestamp;
    }

    emit EvaluationPerformed(_aId, _hash, _provenanceRating, _averageProvenanceRating, _currentFairMarketValue, _averageFairMarketValue, authId );
  }

  /// @notice Creates a new asset NFT.
  /// @dev Asset cannot exists
  /// @param _to Address of the asset owner - enables community the ability to limit registration to certified registars.
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _categoryId Id of the category the asset belongs to.
  /// @param _hash keccak-256 hash of the base Metadata document.
  function register(address _to, uint256 _aId, uint64 _categoryId, uint256 _hash) public payable override virtual {
    confirmNotPaused();
    // Asset must not exist.
    require(_assetMetaData[_aId].id == 0, "EXISTS");

    // Get Authenticator Id
    uint authId = InterContractService._authenticatorId(_addressVariables[T_CATKEY], msg.sender);

    // If REQ_REG_AUTH true, require sender is a registart.
    checkCertified(_boolVariables["REQ_REG_AUTH"], authId, RESERVED_CERTIFICATION, REGISTRANT_CERTIFICATION);

    // Process Payment
    vetPayment(PAY_REG);

    bytes memory _data = '0';
    // ERC1155 _mint single token. As sender could be a registar, owner is _to,
    // _aId should be the RFID Tag's Identifier.
    _mint(_to, _aId, 1, _data);

    // Create asset metadata object.
    _assetMetaData[_aId] = Asset (
        // NFC Id
        _aId,
        // Owner for ease of cross reference.
        _to,
        // Last inventory timestamp
        0,
        // Current document hash code
        _hash,
        // Last Provenance Rating
        0,
        // Average Provenance Rating
        0,
        // Last Provenance Rating timestamp
        0,
        // Current Fair Market Value in WEI
        0,
        // Average Current Fair Market Value in WEI
        0,
        // Last Current Fair Market Value timestamp
        0,
        // Asset category
        _categoryId,
        // Number of authenticators
        0,
        // Current link index.
        0
      );

      emit AssetRegistered (_aId, _categoryId, _hash, _to);
  }

  /// @notice Enables an owner to remove a secondary id previously linked to an asset.
  /// @param _id id of the target secondary id.
  function removeSecondaryId (uint256 _id) public override {
    confirmNotPaused();
    uint256 targetAssetId = _secondaryIds[_id];
    // Asset must exist.
    require(targetAssetId > 0, "NOT_EXIST");
    // Sender must be asset owner or approved for all.
    isApproved(targetAssetId);

    // Set map element back to default.
    _secondaryIds[_id] = 0;

    // Announce the inventory tag Id has been removed.
    emit SecondaryIdRemoved (targetAssetId, _id);
  }

  /// @notice Set URL associated with a linked secondary Id
  /// @param _aId Id of target asset.
  /// @param _url Inventory URL to associated with the target asset.
  /// @return new Inventory Url Index.
  function setInventoryUrl (uint256 _aId, string memory _url) public payable override returns (uint32) {
    confirmNotPaused();
    // Asset must exist.
    assetMustExist(_aId);
    // Sender must be asset owner or approved for all.
    isApproved(_aId);
    // If payment required, handle
    vetPayment(PAY_INV);

    // Increment index
    _assetMetaData[_aId].inventoryLinkIndex = _assetMetaData[_aId].inventoryLinkIndex.add(1);

    _inventoryUrls[_aId][_assetMetaData[_aId].inventoryLinkIndex] = _url;

    return _assetMetaData[_aId].inventoryLinkIndex;
  }

  /// @notice Sets a metadata file Uri for a specific asset.
  /// @dev Asset must exist
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _uri uri to metadata files.
  function setAssetUri (uint256 _aId, string memory _uri) public override {
    confirmNotPaused();
    // Asset must exist.
    assetMustExist(_aId);
    
    // Get Authenticator Id
    uint authId = InterContractService._authenticatorId(_addressVariables[T_CATKEY], msg.sender);

    // Sender must be asset owner or approved for all or registar.
    isApprovedOrCertified(_aId, authId, RESERVED_CERTIFICATION, REGISTRANT_CERTIFICATION );

    _assetUri[_aId] = _uri;
  }

  /// @notice Update document hash value for asset. 
  /// @dev Sender must be asset owner or ApprovedForAll
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _hash keccak-256 hash of the base Metadata document.
  function updateDocumentHash (uint256 _aId, uint256 _hash) public override {
    confirmNotPaused();
    // Asset must exist.
    assetMustExist(_aId);
    // Sender must be asset owner or approved for all.
    isApproved(_aId);
    // Update hash
    _assetMetaData[_aId].documentHash = _hash;

    emit HashUpdated (_aId, _hash, msg.sender);
  }

  function assetMustExist(uint256 _aId) internal view {
    require(_assetMetaData[_aId].id == _aId, T_MUSTEXIST);
  }
  
  function checkCertified(bool _check, uint256 _id, uint64 _certificationId, uint64 _authType) internal view {
    require(!_check ||
          InterContractService._authenticatorCertified(_id, _certificationId, _authType, _addressVariables[T_CATKEY]),
          T_NOTAUTH);
  }

  function isApproved(uint256 _aId) internal view {
    require(
      hasRole(AUTH_ROLE, msg.sender) ||
      balanceOf(msg.sender, _aId) > 0 || 
      isApprovedForAll(_assetMetaData[_aId].owner, msg.sender),
      T_NOTAUTH
    );
  }

  function isApprovedOrCertified(uint256 _aId, uint256 _id, uint64 _certificationId, uint64 _authType) internal view {
    require(
      hasRole(AUTH_ROLE, msg.sender) ||
      balanceOf(msg.sender, _aId) > 0 || 
      isApprovedForAll(_assetMetaData[_aId].owner, msg.sender) ||
      InterContractService._authenticatorCertified(_id, _certificationId, _authType, _addressVariables[T_CATKEY]),
      T_NOTAUTH
    );
  }
  
}
