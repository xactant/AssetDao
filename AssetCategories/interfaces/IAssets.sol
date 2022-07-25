// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Interface defining public, callable functions of an A2P2 Asset
/// @author David B. Goodrich
interface IAssets {
  /// @notice Enable asset owner to link an secondary id to an asset.
  /// @dev Caller must be Asset Owner or ApprovedForAll
  /// @param _assetId - main id of the target asset.
  /// @param _tagId - new secondary id to link to the asset.
  function addInventoryTag (uint256 _assetId, uint256 _tagId) external;
  /// @notice Provides a way to retieve the token's internal data.
  /// @param _assetId - main id of the target asset.
  function getAssetMetadata (uint256 _assetId) external view
    returns(uint256 inventoryTimestamp, uint256 documentHash, uint256 pr,
      uint256 apr, uint256 prTimestamp, uint256 cfmv, uint256 avgCfmv,
      uint256 cfmvTimestamp, uint64 categoryId, uint256 [] memory inventoryTagIds) ;
  /// @notice Provide a way to retrieve the asset Id of an asset linked with specified secondary Id.
  /// @param _tagId A secondary id linked to an asset.
  /// @return id of the linked asset
  function getAssetIdByInventoryTag(uint256 _tagId) external view returns(uint256);
  /// @notice Retrieve a URL (if one exists) that is associated with a secondary id
  /// @param _tagId Secondary id linked to an asset.
  /// @return A URL (if on exists) that is associated with the target secondary id.
  function getInventoryUrl (uint256 _tagId) external view returns(string memory);
  /// @notice Persists Provernance evaluation and Value evlauations of an asset.
  /// @dev Caller must be certified to perform evaluation for target asset's category.
  /// @dev Asset must exist
  /// @param _assetId Id of target asset.
  /// @param _documentHash keccak-256 hash of the base Metadata document.
  /// @param _provenanceRating Zero value ignored - if GT 0, recorded as the provenance rating for the target
  function performEvaluation(uint256 _assetId, uint256 _documentHash,
    uint256 _provenanceRating, uint256 _averageProvenanceRating,
    uint256 _currentFairMarketValue, uint256 _averageFairMarketValue) external;
  /// @notice Creates a new asset NFT.
  /// @dev Asset cannot exists
  /// @param _to Address of the asset owner - enables community the ability to limit registration to certified registars.
  /// @param _assetId id that corresponds to the RFID Tag associated to the physical asset.
  /// @param _categoryId Id of the category the asset belongs to.
  /// @param _data see ERC1155 for _data.
  function register(address _to, uint256 _assetId, uint64 _categoryId, bytes memory _data) external;
  /// @notice Enables an owner to remove a secondary id previously linked to an asset.
  /// @param _tagId id of the target secondary id.
  function removeInventoryTag (uint256 _tagId) external;
  /// @notice Set URL associated with a linked secondary Id
  /// @param _tagId Target linked secondary Id
  /// @param url URL to associated with the target secondary id.
  function setInventoryUrl (uint256 _tagId, string memory url) external;
}
