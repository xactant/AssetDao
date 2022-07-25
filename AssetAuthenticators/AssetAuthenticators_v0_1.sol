// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Pausable.sol";
import "./lib/SafeMath64.sol";
import "./interfaces/IAuthenticators.sol";
import "./interfaces/ICategories.sol";
import "./AuthenticatorsStorage.sol";

/// @title Implementation of an A2P2 Authenticators contract
/// @author David B. Goodrich
contract AssetAuthenticators_v0_1 is IAuthenticators, AuthenticatorsStorage {
  using SafeMath for uint256;
  using SafeMath64 for uint64;

  /// @dev Emitted when the default URL of the contract is changed.
  event DefaultUrlChanged(string oldUrl, string newUrl);

  /// @dev Emitted
  event AuthenticatorUpdated(uint256 certifierId, uint256 authenticatorId, uint256 documentHash, string url, string reason);

  /// @dev Emitted when an authenticator is certified.
  event AuthenticatorCertified(uint256 certifierId, uint256 authenticatorId, uint64 certificationId);

  /// @dev Emitted when an authenticator loses a certification.
  event AuthenticatorDecertified(uint256 certifierId, uint256 authenticatorId, uint64 certificationId);

  /// @dev Grant a certification to an authenticator.
  /// @dev Caller must be an administrator.
  /// @param _id Id of the target authenticator
  /// @param _certificationId Certification to be added to authenticaator.
  /// @param _documentHash keccak-256 hash of the base Metadata document.
  function certify(uint256 _id, uint64 _certificationId, uint256 _documentHash) public {
    // Cannot be paused.
    require(!paused(), "Cannot add certification while paused");
    // Require certifier is registered and
    require(isRegistered(_metaData[_id].owner), "The authenticator must be registered.");

    // Get sender's registration Id.
    uint256 senderRegistrationId = _senderRegistration();
	
    // Sender must have Authentication role for specified certification.
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
      hasRole(AUTH_ROLE, msg.sender) ||
      _certifications[senderRegistrationId][_certifierCertification(_certificationId, true)] == true,
      "Must have authentication certification or be an administrator to certify");

    // Certification must be defined.
    require(_certificationExists(_certificationId) == true, "Certification must be defined.");

    // Set certification as true for specified authenticatior.
    _certifications[_id][_certificationId] = true;
    // Update authenticator's docuemnt hash.
    _metaData[_id].documentHash = _documentHash;

    emit AuthenticatorCertified(senderRegistrationId, _id, _certificationId);

    emit AuthenticatorUpdated(senderRegistrationId, _id, _documentHash, _metaData[_id].url, "CERTIFIED");
  }

  /// @notice Remove a certification to an authenticator.
  /// @dev Caller must be an administrator.
  /// @param _id Id of the target authenticators
  /// @param _certificationId Certification to be removed from authenticaator.
  /// @param _documentHash keccak-256 hash of the base Metadata document.
  function decertify(uint256 _id, uint64 _certificationId, uint256 _documentHash) public {
    // Cannot be paused.
    require(!paused(), "Cannot add certification while paused");
    // Require certifier is registered and
    require(isRegistered(_metaData[_id].owner), "The authenticator must be registered.");
    // Get sender's registration Id.
    uint256 senderRegistrationId = _senderRegistration();
    // Sender must have Authentication role for specified certification.
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        hasRole(AUTH_ROLE, msg.sender), "Must be an administrator.");

    // Set certification as true for specified authenticatior.
    _certifications[_id][_certificationId] = false;
    // Update authenticator's docuemnt hash.
    _metaData[_id].documentHash = _documentHash;

    emit AuthenticatorCertified(senderRegistrationId, _id, _certificationId);

    emit AuthenticatorUpdated(senderRegistrationId, _id, _documentHash, _metaData[_id].url, "DECERTIFIED");
  }

  /// @notice Retrieve authenticator id by addresses
  /// @param _addr Address of target authenticator.
  /// @return Record Id of target authenticator.
  function getAuthenticatorIdByAddress(address _addr) public override view returns(uint256) {
    return _authenticatorByOwner[_addr];
  }

  /// @notice Retrive internal data for target authenticators.
  /// @param _id The target authenticator's Id.
  function getAuthenticatorData(uint256 _id) public view returns (uint256 id, address  owner, uint avgRating, uint256 documentHash, string memory url) {
    id = _metaData[_id].id;
	owner = _metaData[_id].owner;
	avgRating = _metaData[_id].avgRating;
    documentHash = _metaData[_id].documentHash;
	url = _metaData[_id].url;
  }

  /// @notice Returns authenticator id for msg.sender address.
  function getMyRegistrationId() public view returns(uint256) {
    return _authenticatorByOwner[msg.sender];
  }

  /// @notice Retrive the metadata url for the specified registrant.
  /// @param _id Id of target authenticator.
  function getUrl(uint256 _id) public view returns(string memory) {
      string memory rsp = _stringStorage["DEFAULT_URL"];

      if (_metaData[_id].id == _id) {
        rsp = _metaData[_id].url;
      }

      return rsp;
  }

  /// @notice Determines if Autenticator is certified for specifried CERTIFICATION
  /// @param _id Id of the the target certifier.
  /// @param _certificationId the certification (also asset category) that is being checked.
  /// @return True or False
  function isCertified(uint256 _id, uint64 _certificationId) public override view returns (bool) {
    // Short cut incase a certifier Id is passed as _certificationId.
    if (_certifications[_id][_certificationId]) {
      return true;
    }

    // Define certifier certification for the majore/minor part of target certificationId
    uint64 certifierCertId = _certifierCertification(_certificationId, true);

    if (_certifications[_id][certifierCertId]) {
      // Has certification
      return true;
    }
    // IF configured to allow authenticors with only the major of a certification
    // to decertify, check if the target has Major certification
    else if (_uint256Storage["ALLOW_MAJOR_HOLDER_AUTHENTICATION"] == 1) {
      certifierCertId = _certifierCertification(_certificationId, false);

      return _certifications[_id][certifierCertId];
    }

    // Target not certified.
    return false;
  }

  /// @notice Determines if specified address is registered as an authenticator.
  /// @return True or False
  function isRegistered(address _registrant) public override view returns (bool) {
      bool rsp = false;

      if (_metaData[_authenticatorByOwner[_registrant]].id > 0) {
        rsp = true;
      }

      return rsp;
  }

   /// @notice Registers a potential authetnicator / certifier.
   /// @dev the caller must have the Registrant Certification
   /// @dev cannot be paused.
   /// @param _to Address of entity to register as an authenticator.
  function register(address _to) public virtual {
    // Cannot be paused.
    require(!paused(), "Cannot register while paused");
    // Find sender registration
    uint256 senderId = _senderRegistration();

    // Sender must have registrant certification.
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
      hasRole(AUTH_ROLE, msg.sender) ||
      _certifications[senderId][REGISTRANT_CERTIFICATION] == true,
      "Must have authentication role to register");

    // Define new id
    _uint256Storage["AUTHENTICATOR_ID"] = _uint256Storage["AUTHENTICATOR_ID"].add(1);
    uint256 id = _uint256Storage["AUTHENTICATOR_ID"];

    // Link address to authenticator Id.
    _authenticatorByOwner[_to] = id;

    // Define new authenticor's data.
    _metaData[id] = MetaData (
      id,
      _to,
      0,
      0,
      _stringStorage["DEFAULT_URL"]
    );

    emit AuthenticatorUpdated(senderId, id, 0, _stringStorage["DEFAULT_URL"], "REGISTRATION");
  }

  /// @notice Sets the metadata url for the specified registrant. Enables authenticator to contol and host their own metadata.
  /// @dev The caller must be the registrant or admin.
  /// @param _id Id of the target authenticator.
  /// @param _url Url to set as authenticator's metadata Url.
  function setRegistrantUrl(uint256 _id, string memory _url) public {
      address _expectedOwner = _metaData[_id].owner;
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        _expectedOwner == msg.sender, "Must be owner or Administrator.");

      // Find sender registration
      uint256 senderId = _senderRegistration();

      _metaData[_id].url = _url;

      emit AuthenticatorUpdated(senderId, _id, _metaData[_id].documentHash, _metaData[_id].url, "URL_CHANGED");
  }

  /// @notice Sets the default url.
  /// @dev The caller must be an administrator.
  function setUrl(string memory _url) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be Administrator.");

    string memory _oldUrl = _stringStorage["DEFAULT_URL"];

    _stringStorage["DEFAULT_URL"] = _url;

    emit DefaultUrlChanged(_oldUrl, _url);
  }

  /// @dev Calculates the certifier Id for the specified certification. If
  ///      _includeMinor is true The full certification major minor
  function _certifierCertification(uint64 _certificationId, bool _includeSub) internal pure returns (uint64) {
    uint64 rsp = 0x0;

    if (_includeSub) {
      rsp = _certificationId & Constants.CERT_MAJ_MIN_SUB_MASK;
    } else {
      rsp = _certificationId & Constants.CERT_MAJ_MIN_MASK;
    }

    // Define a certifier category by adding major minor to the certifier mask.
    rsp.add(Constants.CERTIFIER_SUB_CERTIFICATION);

    return rsp;
  }

  /// @dev Determines if certification is defined.
  /// @dev this function calls a seperate contracct instance.
  function _certificationExists(uint64 _certificationId) public view returns (bool) {
    ICategories cats = ICategories(_addressStorage["AssetCategories"]);

    return cats.isCertification(_certificationId);
  }

  /// @dev Retrieves the registration associated with msg.sender
  function _senderRegistration() internal view returns (uint256) {
    return _authenticatorByOwner[msg.sender];
  }

}
