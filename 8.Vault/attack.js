//初始化基本对象
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));

web3.eth.getStorageAt("0x0b8D3e77A426537E467F797a46C61F6CF6476790", 1)
.then(console.log);