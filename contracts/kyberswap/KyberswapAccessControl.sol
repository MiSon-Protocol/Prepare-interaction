// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMetaAggregationRouterV2} from "./interfaces/IMetaAggregationRouterV2.sol";
import {CallAccess} from "../CallAccess.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract KyberswapAccessControl is CallAccess {
    using EnumerableSet for EnumerableSet.AddressSet;

    IMetaAggregationRouterV2 constant metaAggregationRouterV2 =
        IMetaAggregationRouterV2(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5);
    // 支持的代币地址列表
    EnumerableSet.AddressSet swapTokenList;

    error notAllowSwapToken(address);

    constructor() {
    }

    function batchAddSwapToken (address[] calldata tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            _addSwapToken(tokens[i]);
        }
    }

    function _addSwapToken(address token) internal {
        require(!swapTokenList.contains(token), "already exist");
        bool addSuc = swapTokenList.add(token);
        require(addSuc, "add token fail");
        // 授权代币合约
        IERC20(token).approve(address(metaAggregationRouterV2), type(uint).max);
    }

    function batchRemoveSwapToken(address[] calldata tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeSwapToken(tokens[i]);
        }
    }

    function _removeSwapToken(address token) internal {
        require(swapTokenList.contains(token), "not exist");
        bool removeSuc = swapTokenList.remove(token);
        require(removeSuc, "remove token fail");
        // 取消授权代币合约
        IERC20(token).approve(address(metaAggregationRouterV2), 0);
    }

    function getSwapTokenList() public view returns (address[] memory) {
        return swapTokenList.values();
    }

    function getSwapTokenListLength() public view returns (uint256) {
        return swapTokenList.length();
    }

    function getSwapTokenAt(uint256 index) public view returns (address) {
        return swapTokenList.at(index);
    }

    function containsSwapToken(address token) external view returns (bool) {
        return swapTokenList.contains(token);
    }

    function requireAllowSwapToken(address _token) public view {
        if (!swapTokenList.contains(_token)) revert notAllowSwapToken(_token);
    }

    function swap(
        IMetaAggregationRouterV2.SwapExecutionParams calldata execution
    ) external callable returns (uint256 returnAmount, uint256 gasUsed) {
        // 检查是否支持代币
        requireAllowSwapToken(address(execution.desc.srcToken));
        requireAllowSwapToken(address(execution.desc.dstToken));
        require(execution.desc.dstReceiver == address(this), "invalid dstReceiver");
        
        return metaAggregationRouterV2.swap(execution);
    }
}
