// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAAVEPool} from "./interfaces/IAAVEPool.sol";
import {CallAccess} from "../CallAccess.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AAVEAccessControl is CallAccess {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAAVEPool constant aavePool =
        IAAVEPool(0x6807dc923806fE8Fd134338EABCA509979a7e0cB);
    // 支持的代币地址列表
    EnumerableSet.AddressSet aaveTokenList;

    error notAllowAAVEToken(address);

    constructor() {
    }

    function batchAddAAVEToken (address[] calldata tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            _addAAVEToken(tokens[i]);
        }
    }

    function _addAAVEToken(address token) internal {
        require(!aaveTokenList.contains(token), "already exist");
        bool addSuc = aaveTokenList.add(token);
        require(addSuc, "add token fail");
        // 授权代币合约
        IERC20(token).approve(address(aavePool), type(uint).max);
    }

    function batchRemoveAAVEToken(address[] calldata tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeAAVEToken(tokens[i]);
        }
    }

    function _removeAAVEToken(address token) internal {
        require(aaveTokenList.contains(token), "not exist");
        bool removeSuc = aaveTokenList.remove(token);
        require(removeSuc, "remove token fail");
        // 取消授权代币合约
        IERC20(token).approve(address(aavePool), 0);
    }

    function getAAVETokenList() public view returns (address[] memory) {
        return aaveTokenList.values();
    }

    function getAAVEokenListLength() public view returns (uint256) {
        return aaveTokenList.length();
    }

    function getAAVETokenAt(uint256 index) public view returns (address) {
        return aaveTokenList.at(index);
    }

    function containsAAVEToken(address token) external view returns (bool) {
        return aaveTokenList.contains(token);
    }

    function requireAllowAAVEToken(address _token) public view {
        if (!aaveTokenList.contains(_token)) revert notAllowAAVEToken(_token);
    }
    
    function aaveSupply(
        address asset,
        uint256 amount
    ) external callable {
        // 检查是否支持代币
        requireAllowAAVEToken(asset);
        aavePool.supply(asset, amount, address(this), 0);
    }

    function aaveWithdraw(
        address asset,
        uint256 amount
    ) external callable returns (uint256) {
        // 检查是否支持代币
        requireAllowAAVEToken(asset);
        return aavePool.withdraw(asset, amount, address(this));
    }
}
