// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Interface defining public, callable functions of an A2P2 Asset
/// @author David B. Goodrich
interface IAssets {
  /// @notice Enable asset owner to link an secondary id to an asset.
  /// @dev Caller must be Asset Owner or ApprovedForAll
  /// @param _aId - main id of the target asset.
  /// @param _tagId - new secondary id to link to the asset.
  function addSecondaryId (uint256 _aId, uint256 _tagId) payable external;
  /// @notice Provides a way to retieve the token's internal data.
  /// @param _aId - main id of the target asset.
  function getAssetMetadata (uint256 _aId) external view
    returns(uint256 inventoryTimestamp, uint256 documentHash, uint256 pr,
      uint256 apr, uint256 prTimestamp, uint256 cfmv, uint256 avgCfmv,
      uint256 cfmvTimestamp, uint64 categoryId, uint32 secondaryIdIndex, bool isFlagged, uint256 uId) ;
  /// @notice Provide a way to retrieve the asset Id of an asset linked with specified secondary Id.
  /// @param _id A secondary id linked to an asset.
  /// @return id of the linked asset
  function getAssetIdBySecondaryId(uint256 _id) external view returns(uint256);
  /// @notice Retrieve a URL (if one exists) that is associated with a secondary id
  /// @param _aId Id of target asset.
  /// @param _id Secondary id linked to an asset.
  /// @return A URL (if on exists) that is associated with the target secondary id.
  function getInventoryUrl (uint256 _aId, uint32 _id) external view returns(string memory);
  /// @notice Flag as asset as being inappropriate in most situations.
  /// @dev Caller must have AUTH_ROLE.
  /// @dev Asset must exist
  /// @param _aId Id of target asset.
  function flagAsset(uint256 _aId) external;
  /// @notice Persists Provernance evaluation and Value evlauations of an asset.
  /// @dev Caller must be certified to perform evaluation for target asset's category.
  /// @dev Asset must exist
  /// @param _aId Id of target asset.
  /// @param _hash keccak-256 hash of the base Metadata document.
  /// @param _provenanceRating Zero value ignored - if GT 0, recorded as the provenance rating for the target
  function performEvaluation(uint256 _aId, uint256 _hash,
    uint256 _provenanceRating, uint256 _averageProvenanceRating,
    uint256 _currentFairMarketValue, uint256 _averageFairMarketValue) payable external;
  /// @notice Creates a new asset NFT.
  /// @dev Asset cannot exists
  /// @param _to Address of the asset owner - enables community the ability to limit registration to certified registars.
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _categoryId Id of the category the asset belongs to.
  /// @param _hash keccak-256 hash of the base Metadata document.
  function register(address _to, uint256 _aId, uint64 _categoryId, uint256 _hash) payable external;
  /// @notice Enables an owner to remove a secondary id previously linked to an asset.
  /// @param _id id of the target secondary id.
  function removeSecondaryId (uint256 _id) external;
  /// @notice Sets a metadata file Uri for a specific asset.
  /// @dev Asset must exist
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _uri uri to metadata files.
   function setAssetUri (uint256 _aId, string memory _uri) external;
  /// @notice Set URL associated with a linked secondary Id
  /// @param _aId Id of target asset.
  /// @param _url Inventory URL to associated with the target asset.
  /// @return new Inventory Url Index.
  function setInventoryUrl (uint256 _aId, string memory _url) payable external returns(uint32);
  /// @notice Update document hash value for asset. 
  /// @dev Sender must be asset owner or ApprovedForAll
  /// @param _aId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _hash keccak-256 hash of the base Metadata document.
  function updateDocumentHash (uint256 _aId, uint256 _hash) external;
}
