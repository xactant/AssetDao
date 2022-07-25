// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CategoriesStorage.sol";
import "./interfaces/ICategories.sol";
//import "./lib/SafeMath64.sol";

/// @title Implementation of an A2P2 Asset Category contract
/// @author David B. Goodrich
contract AssetCategories_v0_2 is ICategories, CategoriesStorage {
  using SafeMath for uint256;

  /// @dev Emitted when a category is created or changed.
  event CategoryCreatedUpdated(uint256 categoryId, string label, address _changedBy);

  /// @notice Retrieves the label for the specified category Id
  /// @param _categoryId id to get label for.
  /// @return Category Label
  function getCategoryLabel(uint256 _categoryId) public override view returns(string memory) {
      return _categoryLabels[_categoryId];
  }

  /// @notice Retrieves the list of category Ids.
  /// @return Array of category Ids
  function getCategoryList() public override view returns(uint256 [] memory) {
      return _categoryIds;
  }

  function getMajorCategoryList() public override view returns(uint256 [] memory) {
      return _majors;
  }

  function getMinorCategoryList(uint256 _maj) public override view returns(uint256 [] memory) {
    return _major_minors[_maj];
  }
  
  function getSubCategoryList(uint256 _majmin) public override view returns(uint256 [] memory) {
    return _majorminor_subs[_majmin];
  }
  
  function getCategoriesForSub(uint256 _majminsub)  public override view returns(uint256 [] memory) {
    return _majorminorsub_cats[_majminsub];
  } 

  /// @notice Indicates if certification is valid.
  /// @param _categoryId Category Id to test.
  /// @return True or False.
  function isCertification(uint256 _categoryId) public override view returns(bool) {
    bool rsp = (bytes(_categoryLabels[_categoryId]).length > 0);

    return rsp;
  }

  /// @notice Pause the contract.
  function pause () public {
    // Cannot be paused.
    require(!paused(), "Cannot already be paused.");
    // Must be an administrator
    require(hasRole(PAUSER_ROLE, msg.sender),
      "Must be have pauser role.");

    _pause();
  }

  /// @notice Unpause the contract.
  function unpause () public {
    // Cannot be paused.
    require(paused(), "Must already be paused.");
    // Must be an administrator
    require(hasRole(PAUSER_ROLE, msg.sender),
      "Must be have pauser role.");

    _unpause();
  }

  /// @notice Create / Update category.
  /// @dev The caller must have admin role.
  /// @param _categoryId Category being created / updated.
  /// @param _label Descriptive text used to describe the category.
  function updateCreateCategory(uint256 _categoryId, string memory _label) public override {
    // Cannot be paused.
    require(!paused(), "Cannot update category while paused");
    // Must be an administrator
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Must be an administrator.");

    // If category label exists, update the label. Otherwise create then new
    // category.
    if (_cat_exist[_categoryId]) {
      _categoryLabels[_categoryId] = _label;
    }
    else {
      uint256 maj = getMajor(_categoryId);
      uint256 majMin = getMajorMinor(_categoryId);
      uint256 majMinSub = getMajorMinorSub(_categoryId);

      uint256 auth = majMinSub.add(Constants.AUTHENTICATION_SUB_CERTIFICATION);
      uint256 val = majMinSub.add(Constants.VALUATION_SUB_CERTIFICATION);
      uint256 cert = majMinSub.add(Constants.CERTIFIER_SUB_CERTIFICATION);

      _categoryIds.push(_categoryId);
      _categoryLabels[_categoryId] = _label;
      _cat_exist[_categoryId] = true;
      buildCategoryTrees(maj, majMin, majMinSub, _categoryId);

      if ((_categoryId & Constants.CERT_CAT_MASK) == 0x0) {
        // If authenticator certification does not exist, create it.
        if (!isCertification(auth)) {
            _categoryIds.push(auth);
            _categoryLabels[auth] = string(abi.encodePacked(_label, " AUTHENTICATOR"));

            emit CategoryCreatedUpdated (auth, _categoryLabels[auth], msg.sender);
        }

        // If authenticator certification does not exist, create it.
        if (!isCertification(val)) {
            _categoryIds.push(val);
            _categoryLabels[val] = string(abi.encodePacked(_label, " VALUATOR"));

            emit CategoryCreatedUpdated (val, _categoryLabels[val], msg.sender);
        }

        // If certifier certification does not exist, create it.
        if (!isCertification(cert)) {
            _categoryIds.push(cert);
            _categoryLabels[cert] = string(abi.encodePacked(_label, " CERTIFIER"));

            emit CategoryCreatedUpdated(cert, _categoryLabels[cert], msg.sender);
        }
      }
    }

    emit CategoryCreatedUpdated(_categoryId, _label, msg.sender);
  }

  /// @notice Batch process for categories. If category exists, updates label
  ///         of category, otherwise creates category. Length of both arrays must match.
  /// @dev The caller must have admin role.
  /// @param _categoryIds Ids of categories to process
  /// @param _labels Labels of categories to process.
  function updateCreateCategoryBatch(uint256[] memory _categoryIds, string[] memory _labels)  public override {
    // Array lengths must match
    require(_categoryIds.length == _labels.length, "Categories: categoryId and label array lengths must match.");

    for (uint i = 0; i < _categoryIds.length; i++) {
      updateCreateCategory(_categoryIds[i], _labels[i]);
    }
  }

  function buildCategoryTrees(uint256 _maj, uint256 _majmin, uint256 _majminsub, uint256 _cat) internal {
    if(_maj > 0 && !_majors_exist[_maj]) {
      _majors_exist[_maj] = true;
      _majors.push(_maj);
    }

    if(_majmin > 0 &&!_major_minors_exist[_maj][_majmin]) {
      _major_minors_exist[_maj][_majmin] = true;
      _major_minors[_maj].push(_majmin);
    }

    if(_majminsub > 0 && !_majorminor_subs_exist[_majmin][_majminsub]) {
      _majorminor_subs_exist[_majmin][_majminsub] = true;
      _majorminor_subs[_majmin].push(_majminsub);
    }

    if(!_majorminorsub_cats_exist[_majminsub][_cat]) {
      _majorminorsub_cats_exist[_majminsub][_cat] = true;
      _majorminorsub_cats[_majminsub].push(_cat);
    }
  }
}
