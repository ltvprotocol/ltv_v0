// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

contract Ownable {

  address public owner;

  //error IvalidOwner(address user);

  //error UserRestricted(address user);

  event OwnerUpdated(address oldOwner, address newOwner);

  constructor(address initialOwner) {
    require(initialOwner != address(0), "");
    _transferOwnership(initialOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "");
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "");
    _transferOwnership(newOwner);
  }

  function renounceOwnership() public onlyOwner {
    _transferOwnership(address(0));
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnerUpdated(oldOwner, newOwner);
  }
}