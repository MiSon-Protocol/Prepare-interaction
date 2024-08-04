// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAggregationExecutor {
  function callBytes(bytes calldata data) external payable; // 0xd9c45357

  // callbytes per swap sequence
  function swapSingleSequence(bytes calldata data) external;

  function finalTransactionProcessing(
    address tokenIn,
    address tokenOut,
    address to,
    bytes calldata destTokenFeeData
  ) external;
}

interface IAggregationExecutor1Inch {
  function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

interface IAggregationRouter1InchV4 {
  function swap(
    IAggregationExecutor1Inch caller,
    SwapDescription1Inch calldata desc,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}

struct SwapDescription1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver;
  address payable dstReceiver;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}

struct SwapDescriptionExecutor1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver1Inch;
  address payable dstReceiver;
  address[] srcReceivers;
  uint256[] srcAmounts;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}

interface IMetaAggregationRouterV2 {

    struct SwapDescriptionV2 {
        IERC20 srcToken;
        IERC20 dstToken;
        address[] srcReceivers; // transfer src token to these addresses, default
        uint256[] srcAmounts;
        address[] feeReceivers;
        uint256[] feeAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /// @dev  use for swapGeneric and swap to avoid stack too deep
    struct SwapExecutionParams {
        address callTarget; // call this address
        address approveTarget; // approve this address if _APPROVE_FUND set
        bytes targetData;
        SwapDescriptionV2 desc;
        bytes clientData;
    }

    struct SimpleSwapData {
        address[] firstPools;
        uint256[] firstSwapAmounts;
        bytes[] swapDatas;
        uint256 deadline;
        bytes destTokenFeeData;
    }

    function swapGeneric(SwapExecutionParams calldata execution)
        external
        payable
        returns (uint256 returnAmount, uint256 gasUsed);
    
    function swap(SwapExecutionParams calldata execution)
        external
        payable
        returns (uint256 returnAmount, uint256 gasUsed);
    function swapSimpleMode(
        IAggregationExecutor caller,
        SwapDescriptionV2 memory desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external  returns (uint256 returnAmount, uint256 gasUsed);
}