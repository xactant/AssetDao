// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IAuthenticators.sol";
import "../interfaces/ICategories.sol";
import "./SafeMath64.sol";
import "./Constants.sol";

contract InterContractService is Constants {
  using SafeMath64 for uint64;

  /**
  * @dev Determines if certification is defined.
  *
  * Note - this function calls a seperate contracct instance.
  */
  function categoryExists(uint64 _certificationId, address categoryAddr) public view returns (bool) {
    ICategories cats = ICategories(categoryAddr);

    return cats.isCertification(_certificationId);
  }


  /**
  * @dev Determines if authenticator is certified.
  *
  * Note - this function calls a seperate contracct instance.
  */
  function _authenticatorCertified(uint256 _id, uint64 _certificationId, uint64 _authType, address _authenticatorsAddr) public view returns (bool) {
    IAuthenticators auths = IAuthenticators(_authenticatorsAddr);

    uint64 majMin = (_certificationId & CERT_MAJ_MIN_SUB_MASK);
    uint64 val = majMin.add(_authType);

    return auths.isCertified(_id, val);
  }

  /**
  * @dev Determines sender's authenticator ID.
  *
  * Note - this function calls a seperate contracct instance.
  */
  function _authenticatorId(address _authenticatorsAddr, address _msgSender) public view returns (uint256) {
    IAuthenticators auths = IAuthenticators(_authenticatorsAddr);

    return auths.getAuthenticatorIdByAddress(_msgSender);
  }
}
