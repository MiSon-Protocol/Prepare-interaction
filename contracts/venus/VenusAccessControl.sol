// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVToken} from "./interfaces/IVToken.sol";
import {CallAccess} from "../CallAccess.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract VenusAccessControl is CallAccess {
    using EnumerableSet for EnumerableSet.AddressSet;
    // 支持的vToken地址列表
    EnumerableSet.AddressSet vTokenList;

    error notAllowVToken(address);
    error notAllowFunction(bytes4);

    constructor() {}

    function batchAddVToken(address[] calldata vtokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < vtokens.length; i++) {
            _addVToken(vtokens[i]);
        }
    }

    function _addVToken(address vtoken) internal {
        require(!vTokenList.contains(vtoken), "already exist");
        bool addSuc = vTokenList.add(vtoken);
        require(addSuc, "add token fail");
        // 授权代币合约
        IVToken vtokenContract = IVToken(vtoken);
        require(vtokenContract.isVToken(), "invalid vToken");
        address baseToken = vtokenContract.underlying();
        IERC20(baseToken).approve(vtoken, type(uint256).max);
    }

    function batchRemoveVToken(address[] calldata vtokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < vtokens.length; i++) {
            _removeVToken(vtokens[i]);
        }
    }

    function _removeVToken(address vtoken) internal {
        require(vTokenList.contains(vtoken), "not exist");
        bool removeSuc = vTokenList.remove(vtoken);
        require(removeSuc, "remove token fail");
        // 取消授权代币合约
        IVToken vtokenContract = IVToken(vtoken);
        address baseToken = vtokenContract.underlying();
        IERC20(baseToken).approve(vtoken, 0);
    }

    function getVTokenList() public view returns (address[] memory) {
        return vTokenList.values();
    }

    function getVTokenListLength() public view returns (uint256) {
        return vTokenList.length();
    }

    function getVTokenAt(uint256 index) public view returns (address) {
        return vTokenList.at(index);
    }

    function containsVToken(address _vtoken) external view returns (bool) {
        return vTokenList.contains(_vtoken);
    }

    function requireAllowVToken(address _vtoken) public view {
        if (!vTokenList.contains(_vtoken)) revert notAllowVToken(_vtoken);
    }

    function requireAllowVenusFunction(bytes4 functionSelector) public pure {
        if (
            !(functionSelector == IVToken.mint.selector ||
                functionSelector == IVToken.redeem.selector ||
                functionSelector == IVToken.redeemUnderlying.selector)
        ) {
            revert notAllowFunction(functionSelector);
        }
    }

    function callVenus(address vTokenAddress, bytes calldata data)
        external
        callable
        returns (bytes memory result)
    {
        requireAllowVToken(vTokenAddress);
        requireAllowVenusFunction(bytes4(data[0:4]));
        bool _succ;
        (_succ, result) = vTokenAddress.call(data);
        require(_succ, "Call failed");
    }
}
