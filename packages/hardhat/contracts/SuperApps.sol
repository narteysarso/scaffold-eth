//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

error Unauthorized();

contract SuperApps {
    // ---------------------------------------------------------------------------------------------
    // STATE VARIABLES

    /// @notice Owner.
    address public owner;

    /// @notice CFA Library.
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1;

    /// @notice Allow list.
    mapping(address => bool) public accountList;

    uint public lastTimestamp;

    uint96 public flowRate;

    uint public totalsecs;

    uint public totalAmount;

    event StreamCreated(
        ISuperfluidToken token,
        address receiver,
        uint totalAmount,
        uint totalsecs,
        int96 flowRate
    );

    constructor(ISuperfluid host, address _owner) {
        assert(address(host) != address(0));
        owner = _owner;

        // Initialize CFA Library
        cfaV1 = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(
                address(
                    host.getAgreementClass(
                        keccak256(
                            "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                        )
                    )
                )
            )
        );
    }

    /// @notice Add account to allow list.
    /// @param _account Account to allow.
    function allowAccount(address _account) external {
        if (msg.sender != owner) revert Unauthorized();

        accountList[_account] = true;
    }

    /// @notice Removes account from allow list.
    /// @param _account Account to disallow.
    function removeAccount(address _account) external {
        if (msg.sender != owner) revert Unauthorized();

        accountList[_account] = false;
    }

    /// @notice Transfer ownership.
    /// @param _newOwner New owner account.
    function changeOwner(address _newOwner) external {
        if (msg.sender != owner) revert Unauthorized();

        owner = _newOwner;
    }

    /// @notice Send a lump sum of super tokens into the contract.
    /// @dev This requires a super token ERC20 approval.
    /// @param _token Super Token to transfer.
    /// @param _amount Amount to transfer.
    function sendLumpSumToContract(ISuperToken _token, uint256 _amount) public {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        _token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Withdraw funds from the contract.
    /// @param _token Token to withdraw.
    /// @param _amount Amount to withdraw.
    function withdrawFunds(ISuperToken _token, uint256 _amount) external {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        _token.transfer(msg.sender, _amount);
    }

    /// @notice Create flow from contract to specified address.
    /// @param _token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param _flowRate Flow rate per second to stream.
    function createFlowFromContract(
        ISuperfluidToken _token,
        address receiver,
        int96 _flowRate
    ) public {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        cfaV1.createFlow(receiver, _token, _flowRate);
    }

    /// @notice Update flow from contract to specified address.
    /// @param _token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param _flowRate Flow rate per second to stream.
    function updateFlowFromContract(
        ISuperfluidToken _token,
        address receiver,
        int96 _flowRate
    ) external {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        cfaV1.updateFlow(receiver, _token, _flowRate);
    }

    /// @notice Delete flow from contract to specified address.
    /// @param _token Token to stop streaming.
    /// @param receiver Receiver of stream.
    function deleteFlowFromContract(ISuperfluidToken _token, address receiver)
        public
    {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        cfaV1.deleteFlow(address(this), receiver, _token);
    }

    function clearFlowDetails()
        public
    {
        if (!accountList[msg.sender] && msg.sender != owner)
            revert Unauthorized();

        lastTimestamp = 0;
        flowRate = 0;
        totalsecs = 0;
        totalAmount = 0;
    }

    function createDeliverableFlow(
        ISuperfluidToken _token,
        address _receiver,
        uint _totalAmount,
        uint _totalsecs
    ) external returns (bool, bytes memory) {
        // get flow information getFlow(_token, receiver, sender);
        (, int96 cflowRate, , ) = cfaV1.cfa.getFlow(
            _token,
            address(this),
            _receiver
        );

        uint amountSpent = 0;

        if (cflowRate > 0) {
            amountSpent = (block.timestamp - lastTimestamp) * uint96(cflowRate);

            totalAmount = _totalAmount + (totalAmount - amountSpent);

            uint96 _flowRate = uint96(totalAmount / _totalsecs);

            lastTimestamp = block.timestamp;

            deleteFlowFromContract(_token, _receiver);

            createFlowFromContract(_token, _receiver, int96(_flowRate));

            emit StreamCreated(
                _token,
                _receiver,
                totalAmount,
                _totalsecs,
                int96(_flowRate)
            );

            return (true, bytes(""));
        }

        totalAmount = _totalAmount;

        lastTimestamp = block.timestamp;

        uint96 _flowRate = uint96(_totalAmount / _totalsecs);

        createFlowFromContract(_token, _receiver, int96(_flowRate));

        emit StreamCreated(
            _token,
            _receiver,
            _totalAmount,
            _totalsecs,
            int96(_flowRate)
        );

        return (true, bytes(""));
    }
}
