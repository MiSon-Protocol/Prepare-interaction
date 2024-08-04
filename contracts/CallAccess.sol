// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

abstract contract CallAccess is AccessControlEnumerable {

    //调用者角色
    bytes32 constant public CALL_ROLE = keccak256("CALL_ROLE");

    constructor() {
    }

    function _grantCallRole (address account) internal {
        _grantRole(CALL_ROLE, account);
    }

    // 调用者权限
    modifier callable() {
        require(hasRole(CALL_ROLE, msg.sender), "Caller role is not set");
        _;
    }


}