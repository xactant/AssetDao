// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Interface of the AssetCategories.
/// @author David B. Goodrich
interface ICategories {
  /// @notice Retrieves the label for the specified category Id
  /// @param _categoryId id to get label for.
  /// @return Category Label
  function getCategoryLabel(uint256 _categoryId) external view returns(string memory);

  /// @notice Retrieves the list of category Ids.
  /// @return Array of category Ids
  function getCategoryList() external view returns(uint256 [] memory);

  function getMajorCategoryList() external view returns(uint256 [] memory);
  function getMinorCategoryList(uint256 _maj) external view returns(uint256 [] memory);
  function getSubCategoryList(uint256 _majmin) external view returns(uint256 [] memory);
  function getCategoriesForSub(uint256 _majminsub) external view returns(uint256 [] memory);

  /// @notice Indicates if certification is valid.
  /// @param _categoryId Category Id to test.
  /// @return True or False.
  function isCertification(uint256 _categoryId) external view returns(bool);

  /// @notice Create / Update category.
  /// @dev The caller must have admin role.
  /// @param _categoryId Category being created / updated.
  /// @param _label Descriptive text used to describe the category.
  function updateCreateCategory(uint256 _categoryId, string memory _label) external ;

  /// @notice Batch process for categories. If category exists, updates label
  ///         of category, otherwise creates category. Length of both arrays must match.
  /// @dev The caller must have admin role.
  /// @param _categoryIds Ids of categories to process
  /// @param _labels Labels of categories to process.
  function updateCreateCategoryBatch(uint256[] memory _categoryIds, string[] memory _labels) external ;
}
