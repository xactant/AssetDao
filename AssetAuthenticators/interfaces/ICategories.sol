// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Interface of the AssetCategories.
/// @author David B. Goodrich
interface ICategories {
  /// @notice Retrieves the label for the specified category Id
  /// @param _categoryId id to get label for.
  /// @return Category Label
  function getCategoryLabel(uint64 _categoryId) external view returns(string memory);

  /// @notice Retrieves the list of category Ids.
  /// @return Array of category Ids
  function getCategoryList() external view returns(uint64 [] memory);

  /// @notice Indicates if certification is valid.
  /// @param _categoryId Category Id to test.
  /// @return True or False.
  function isCertification(uint64 _categoryId) external view returns(bool);
}
