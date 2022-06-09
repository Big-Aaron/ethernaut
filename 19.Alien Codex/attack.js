//初始化基本对象
const Web3 = require('web3');
const BN = require('bn.js');
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));


var index = web3.utils.sha3('0x0000000000000000000000000000000000000000000000000000000000000001');
console.log("index = ", index);


web3.eth.getStorageAt("0xeD227794238143eb41B3D9803b38eB1E206E988B", 0)
.then(console.log);
