// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface Fallback {
    function contributions(address) external view returns(uint);
}

contract Attack {
    using SafeMath for uint256;

    Fallback constant private target = Fallback(0xa02cc8BF671DB599F07CB426290d3f995a3960dA);

    function getContributions(address _address) public view returns (uint){
        return target.contributions(_address);
    }

}