// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    constructor(uint256 minDelay, address multiSignAddress)
        TimelockController(
            minDelay,
            _constructArray(multiSignAddress),
            _constructArray(multiSignAddress),
            address(0)
        )
    {
        
    }

    // Helper function to create an array with a single address
    function _constructArray(address addr)
        private
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](1);
        array[0] = addr;
        return array;
    }
}
