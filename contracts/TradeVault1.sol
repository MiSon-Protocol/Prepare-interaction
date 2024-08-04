// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VenusAccessControl} from "./venus/VenusAccessControl.sol";
import {AAVEAccessControl} from "./aave/AAVEAccessControl.sol";
import {WithdrawAccessControl} from "./WithdrawAccessControl.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

contract TradeVault1 is
    VenusAccessControl,
    AAVEAccessControl,
    WithdrawAccessControl,
    Multicall
{
    using SafeERC20 for IERC20;

    constructor(address _traderAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantCallRole(_traderAddress);
    }

    receive() external payable {
        // revert("no receive ETH");
    }
}
