// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct Deliverable {
    uint16 validatorThreshold;
    uint24 totalSeconds;
    uint payoutAmount;
    string title;
    string description;
}