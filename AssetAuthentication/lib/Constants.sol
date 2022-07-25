// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Constants {
  bytes32 public constant AUTH_ROLE = keccak256("AUTH_ROLE");
  uint64 public constant RESERVED_CERTIFICATION = 0x0;
  uint64 public constant REGISTRANT_CERTIFICATION = 0xfffffffc;
  uint64 public constant CERT_MAJ_MIN_SUB_MASK = 0xffffffffffff0000;
  uint64 public constant VALUATION_SUB_CERTIFICATION = 0xfffd;
  uint64 public constant AUTHENTICATION_SUB_CERTIFICATION = 0xfffe;
  uint64 public constant CERTIFIER_SUB_CERTIFICATION = 0xffff;
  uint8 public constant PAY_ADD_TAG = 0x1;
  uint8 public constant PAY_EVAL = 0x2;
  uint8 public constant PAY_REG = 0x3;
  uint8 public constant PAY_INV = 0x4;

}