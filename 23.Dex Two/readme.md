# Dex Two

> This level will ask you to break `DexTwo`, a subtlely modified `Dex` contract from the previous level, in a different way.
>
> You need to drain all balances of token1 and token2 from the `DexTwo` contract to succeed in this level.
>
> You will still start with 10 tokens of `token1` and 10 of `token2`. The DEX contract still starts with 100 of each token.
>
>  Things that might help:
>
> - How has the `swap` method been modified?
> - Could you use a custom token contract in your attack?

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract DexTwo is Ownable {
  using SafeMath for uint;
  address public token1;
  address public token2;
  constructor() public {}

  function setTokens(address _token1, address _token2) public onlyOwner {
    token1 = _token1;
    token2 = _token2;
  }

  function add_liquidity(address token_address, uint amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
  }
  
  function swap(address from, address to, uint amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  } 

  function getSwapAmount(address from, address to, uint amount) public view returns(uint){
    return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
  }

  function approve(address spender, uint amount) public {
    SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
    SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
  }

  function balanceOf(address token, address account) public view returns (uint){
    return IERC20(token).balanceOf(account);
  }
}

contract SwappableTokenTwo is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
  }

  function approve(address owner, address spender, uint256 amount) public returns(bool){
    require(owner != _dex, "InvalidApprover");
    super._approve(owner, spender, amount);
  }
}
```



## 攻击思路

swap的逻辑
$$
((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)))
$$
我初始有10个token1，10个token2，合约有100个token1，100个token2。

我另外有token3(usdt => 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02).

给合约转100个token3

第一次swap，我用100个token3换100个token1，因为
$$
(100*100)/100 = 100
$$
第一次swap后，我就有100个token1，0个token2，损失100个token3；合约有0个token1，110个token2，200个token3。



第二次swap，我用200个token3换100个token2，因为
$$
(200*100)/200 = 100
$$
第二次swap后，我就有100个token1，100个token2，损失200个token3；合约有0个token1，0个token2，400个token3。

至此，经过2轮，合约中的token1与token2已经被掏空了。

## 攻击流程

首先，在USDT代币中授权300给Dex,并且给DEX转100代币

```js
await contract.swap(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02, await contract.token1(),100)
```

```
await contract.swap(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02, await contract.token2(),200)
```

成功！



As we've repeatedly seen, interaction between contracts can be a source of unexpected behavior.

Just because a contract claims to implement the [ERC20 spec](https://eips.ethereum.org/EIPS/eip-20) does not mean it's trust worthy.

Some tokens deviate from the ERC20 spec by not returning a boolean value from their `transfer` methods. See [Missing return value bug - At least 130 tokens affected](https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca).

Other ERC20 tokens, especially those designed by adversaries could behave more maliciously.

If you design a DEX where anyone could list their own tokens without the permission of a central authority, then the correctness of the DEX could depend on the interaction of the DEX contract and the token contracts being traded.
