// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CallAccess} from "./CallAccess.sol";

abstract contract WithdrawAccessControl is CallAccess {
    using SafeERC20 for IERC20;

    //代币接收者角色
    bytes32 constant public TOKEN_RECIPIENT_ROLE = keccak256("TOKEN_RECIPIENT_ROLE");

    event WithdrawFTTokenToRecipientRole(address indexed _tokenAddress, address indexed _to, uint256 _amount);
    event AdminWithdrawFTToken(address indexed _tokenAddress, address indexed _to, uint256 _amount);
    event AdminWithdrawERC721(address indexed _tokenAddress, address indexed _to, uint256[] _tokenIdList);

    constructor() {
    }

    function withdrawFTTokenToRecipientRole(address _tokenAddress, address _to, uint256 _amount) external callable {
        _checkRole(TOKEN_RECIPIENT_ROLE, _to);
        uint256 _realAmount;
        if(_tokenAddress == address(0)){
            _realAmount = _withdrawETH(_to, _amount);
        }else {
            _realAmount = _withdrawERC20(_tokenAddress, _to, _amount);
        }
        emit WithdrawFTTokenToRecipientRole(_tokenAddress, _to, _realAmount);
    }

    function _withdrawERC20(address _tokenAddress, address _to, uint256 _amount) private returns(uint256 _realAmount){
        IERC20 _token = IERC20(_tokenAddress);
        if (_amount == 0) {
            _amount = _token.balanceOf(address(this));
        }
        if(_amount > 0){
            _token.safeTransfer(_to, _amount);
        }
        _realAmount = _amount;
    }

    function _withdrawETH(address _to, uint256 _amount) private returns(uint256 _realAmount){
        if (_amount == 0) {
            _amount = address(this).balance;
        }
        if(_amount > 0){
            (bool _suc, ) = _to.call{gas: 23000, value: _amount}("");
            require(_suc, "ETH transfer fail");
        }
        _realAmount = _amount;
    }

    function adminWithdrawFTToken(address _tokenAddress, address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _realAmount;
        if(_tokenAddress == address(0)){
            _realAmount = _withdrawETH(_to, _amount);
        }else {
            _realAmount = _withdrawERC20(_tokenAddress, _to, _amount);
        }
        emit AdminWithdrawFTToken(_tokenAddress, _to, _realAmount);
    }

    function adminWithdrawERC721 (address _tokenAddress, address _to, uint256[] calldata _tokenIdList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721Enumerable _token = IERC721Enumerable(_tokenAddress);
        uint256[] memory _transferTokenIdList = _tokenIdList;
        if (_tokenIdList.length == 0){
            uint256 _bal = _token.balanceOf(address(this));
            _transferTokenIdList = new uint256[](_bal);
            for (uint i = 0; i < _bal; i++){
                _transferTokenIdList[i] = _token.tokenOfOwnerByIndex(address(this), i);
            }
        }
        for (uint i = 0; i < _transferTokenIdList.length; i++){
            _token.safeTransferFrom(address(this), _to, _transferTokenIdList[i]);
        }
        emit AdminWithdrawERC721(_tokenAddress, _to, _transferTokenIdList);
    }


}