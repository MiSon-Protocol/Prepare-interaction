// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {CallAccess} from "../CallAccess.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract NonfungiblePositionManagerAccessControl is
    CallAccess,
    ERC721Holder
{
    using EnumerableSet for EnumerableSet.AddressSet;

    INonfungiblePositionManager constant nonfungiblePositionManager =
        INonfungiblePositionManager(0x46A15B0b27311cedF172AB29E4f4766fbE7F4364);
    // 支持的代币地址列表
    EnumerableSet.AddressSet lpTokenList;

    error notAllowLPToken(address);  

    constructor() {}

    function batchAddLPToken(address[] calldata tokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            _addLPToken(tokens[i]);
        }
    }

    function _addLPToken(address token) internal {
        require(!lpTokenList.contains(token), "already exist");
        bool addSuc = lpTokenList.add(token);
        require(addSuc, "add token fail");
        // 授权代币合约
        IERC20(token).approve(
            address(nonfungiblePositionManager),
            type(uint256).max
        );
    }

    function batchRemoveLPToken(address[] calldata tokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeLPToken(tokens[i]);
        }
    }

    function _removeLPToken(address token) internal {
        require(lpTokenList.contains(token), "not exist");
        bool removeSuc = lpTokenList.remove(token);
        require(removeSuc, "remove token fail");
        // 取消授权代币合约
        IERC20(token).approve(address(nonfungiblePositionManager), 0);
    }

    function getLPTokenList() public view returns (address[] memory) {
        return lpTokenList.values();
    }

    function getLPTokenListLength() public view returns (uint256) {
        return lpTokenList.length();
    }

    function getLPTokenAt(uint256 index) public view returns (address) {
        return lpTokenList.at(index);
    }

    function containsLPToken(address token) external view returns (bool) {
        return lpTokenList.contains(token);
    }

    function requireAllowLPToken(address _token) public view {
        if (!lpTokenList.contains(_token)) revert notAllowLPToken(_token);
    }

    function uniV3LPMint(
        INonfungiblePositionManager.MintParams calldata mintParams
    )
        external
        callable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // 检查是否支持代币
        requireAllowLPToken(mintParams.token0);
        requireAllowLPToken(mintParams.token1);
        require(mintParams.recipient == address(this), "invalid recipient");
        return nonfungiblePositionManager.mint(mintParams);
    }

    function uniV3LPDecrease(
        INonfungiblePositionManager.DecreaseLiquidityParams
            calldata decreaseParams
    ) external callable returns (uint256 amount0, uint256 amount1) {
        return nonfungiblePositionManager.decreaseLiquidity(decreaseParams);
    }

    function uniV3LPCollect(
        INonfungiblePositionManager.CollectParams calldata params
    ) external callable returns (uint256 amount0, uint256 amount1) {
        require(params.recipient == address(this), "invalid recipient");
        return nonfungiblePositionManager.collect(params);
    }

    function uniV3LPNFTBurn(uint256 tokenId) external callable {
        nonfungiblePositionManager.burn(tokenId);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) external callable {
        require(recipient == address(this), "invalid recipient");
        nonfungiblePositionManager.unwrapWETH9(amountMinimum, recipient);
    }

    function refundETH() external callable {
        nonfungiblePositionManager.refundETH();
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external callable {
        requireAllowLPToken(token);
        require(recipient == address(this), "invalid recipient");
        nonfungiblePositionManager.sweepToken(token, amountMinimum, recipient);
    }
}
