# DoubleEntryPoint

> This level features a `CryptoVault` with special functionality, the `sweepToken` function. This is a common function to retrieve tokens stuck in a contract. The `CryptoVault` operates with an `underlying` token that can't be swept, being it an important core's logic component of the `CryptoVault`, any other token can be swept.
>
> The underlying token is an instance of the DET token implemented in `DoubleEntryPoint` contract definition and the `CryptoVault` holds 100 units of it. Additionally the `CryptoVault` also holds 100 of `LegacyToken LGT`.
>
> In this level you should figure out where the bug is in `CryptoVault` and protect it from being drained out of tokens.
>
> The contract features a `Forta` contract where any user can register its own `detection bot` contract. Forta is a decentralized, community-based monitoring network to detect threats and anomalies on DeFi, NFT, governance, bridges and other Web3 systems as quickly as possible. Your job is to implement a `detection bot` and register it in the `Forta` contract. The bot's implementation will need to raise correct alerts to prevent potential attacks or bug exploits.
>
> Things that might help:
>
> - How does a double entry point work for a token contract ?

## 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface DelegateERC20 {
  function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract Forta is IForta {
  mapping(address => IDetectionBot) public usersDetectionBots;
  mapping(address => uint256) public botRaisedAlerts;

  function setDetectionBot(address detectionBotAddress) external override {
      require(address(usersDetectionBots[msg.sender]) == address(0), "DetectionBot already set");
      usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
  }

  function notify(address user, bytes calldata msgData) external override {
    if(address(usersDetectionBots[user]) == address(0)) return;
    try usersDetectionBots[user].handleTransaction(user, msgData) {
        return;
    } catch {}
  }

  function raiseAlert(address user) external override {
      if(address(usersDetectionBots[user]) != msg.sender) return;
      botRaisedAlerts[msg.sender] += 1;
  } 
}

contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) public {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    /*
    ...
    */

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}

contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}

contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) public {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        if(forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
    }

    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) public override onlyDelegateFrom fortaNotify returns (bool) {
        _transfer(origSender, to, value);
        return true;
    }
}
```

## 攻击思路

题目说`CryptoVault`合约中有bug。经过查找：定位到`CryptoVault`合约将`DoubleEntryPointToken`代币设置为`underlying`不可sweep。但是如果使用`LegacyToken`代币进行sweep操作`transfer`时，`LegacyToken`代币会调用`DoubleEntryPointToken`代币进行`transfer`.这样`CryptoVault`合约设置`DoubleEntryPointToken`代币为`underlying`的操作就变得无效。

bug找到，如何避免。

`Forta`提供了一种预警方法。在`DoubleEntryPointToken`代币进行`delegateTransfer`时，会进行`fortaNotify`检测。`notify`函数中对外部函数调用采取了`try-catch`操作,所以在`notify`中进行`revert`等操作，是没有办法结束交易的.

但`fortaNotify`中会检测`botRaisedAlerts`是否进行了增加。所以可以通过增加`botRaisedAlerts`,达到结束交易的工作

## 攻击流程

当检测到转`CryptoVault`中的代币时，增加`botRaisedAlerts`,结束交易。

```solidity
contract Attack is IDetectionBot{
    event Debug(address to, uint256 value, address origSender);
    address public cryptoVault;
    Forta public forta; 

    function setForta(address _forta) public {
        forta = Forta(_forta);
    }

    function setCryptoVault(address _cryptoVault) public {
        cryptoVault = _cryptoVault;
    }
    function handleTransaction(address user, bytes calldata msgData) public override {
        (address to, uint256 value, address origSender) = abi.decode(msgData[4:],(address,uint256,address));
        emit Debug(to, value, origSender);
        if(origSender == cryptoVault){
           forta.raiseAlert(user);
        }
    }
}
```

Congratulations!

This is the first experience you have with a [Forta bot](https://docs.forta.network/en/latest/).

Forta comprises a decentralized network of independent node operators who scan all transactions and block-by-block state changes for outlier transactions and threats. When an issue is detected, node operators send alerts to subscribers of potential risks, which enables them to take action.

The presented example is just for educational purpose since Forta bot is not modeled into smart contracts. In Forta, a bot is a code script to detect specific conditions or events, but when an alert is emitted it does not trigger automatic actions - at least not yet. In this level, the bot's alert effectively trigger a revert in the transaction, deviating from the intended Forta's bot design.

Detection bots heavily depends on contract's final implementations and some might be upgradeable and break bot's integrations, but to mitigate that you can even create a specific bot to look for contract upgrades and react to it. Learn how to do it [here](https://docs.forta.network/en/latest/quickstart/).

You have also passed through a recent security issue that has been uncovered during OpenZeppelin's latest [collaboration with Compound protocol](https://compound.finance/governance/proposals/76).

Having tokens that present a double entry point is a non-trivial pattern that might affect many protocols. This is because it is commonly assumed to have one contract per token. But it was not the case this time :) You can read the entire details of what happened [here](https://blog.openzeppelin.com/compound-tusd-integration-issue-retrospective/).
