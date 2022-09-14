// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
interface IExecuteManager {
    function execute(
        uint index,
        uint totalSeconds,
        uint payoutAmount
    ) external returns (bool, bytes memory);
}
