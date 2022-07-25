// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Interface defining public, callable operations for an A2P2 Authenticators contract.
/// @author David B. Goodrich
interface IAuthenticators {
  /// @notice Retrieve authenticator id by addresses
  /// @param _addr Address of target authenticator.
  /// @return Record Id of target authenticator.
  function getAuthenticatorIdByAddress(address _addr) external view returns(uint256);
  /// @notice Determines if Autenticator is certified for specifried CERTIFICATION
  /// @param _id Id of the the target certifier.
  /// @param _certificationId the certification (also asset category) that is being checked.
  /// @return True or False
  function isCertified(uint256 _id, uint64 _certificationId) external view returns (bool);
  /// @notice Determines if specified address is registered as an authenticator.
  /// @param _registrant Address to determine is registered to be an authenticator.
  /// @return True or False
  function isRegistered(address _registrant) external view returns (bool);
}
