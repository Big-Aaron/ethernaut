//初始化基本对象
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));

web3.eth.getStorageAt("0x299B8a1409Ae37F0ABBe5470e6694cFB7b39Eb2a", 5)
.then(console.log);