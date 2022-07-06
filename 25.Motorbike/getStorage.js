var Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/4d7440b583e447f7b7d5630b038e0dc7"));

web3.eth.getStorageAt("0x8459D4312807B5eD5444b8b88366CeBDcc56Af9b", '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc')
.then(console.log);

// web3.eth.getCode("0xFF5C8FA1Cb855b6614B0420f9D816F51D89dE1dA")
// .then(console.log);
