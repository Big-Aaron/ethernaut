// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract MagicNum {

  address public solver;

  constructor() public {}

  function setSolver(address _solver) public {
    solver = _solver;
  }

  /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}

contract Attack{
  constructor() public {
    assembly {

      // This is the bytecode we want the program to have:
      // 00 PUSH1 2a /* push dec 42 (hex 0x2a) onto the stack */
      // 03 PUSH1  0 /* store 42 at memory position 0 */
      // 05 MSTORE
      // 06 PUSH1 20 /* return 32 bytes in memory */
      // 08 PUSH1 0
      // 10 RETURN
      // Bytecode: 0x604260005260206000f3 (length 0x0a or 10)
      // Bytecode within a 32 byte word:
      // 0x00000000000000000000000000000000000000000000604260005260206000f3 (length 0x20 or 32)
      //                                               ^ (offset 0x16 or 22)
      
      mstore(0, 0x602a60005260206000f3)
      return(0x16, 0x0a)
    }
  }
}

contract Attack{
    function whatIsTheMeaningOfLife() public pure returns (bytes32){
        return bytes1(int8(42));
    }
}

contract Help{
  function helper(address _attack) public view returns (uint){
    Attack target = Attack(_attack);
    uint256 size;
    assembly {
      size := extcodesize(target)
    }
    return size;
  }
}