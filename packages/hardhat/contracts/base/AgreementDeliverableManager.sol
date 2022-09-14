// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./AgreementDeliverableExecuteManager.sol";

// @title Agreement Deliverable Manager handles create, update, validators and validate actions on deliverables
// @author Nartey Kodjo-Sarso - <narteysarso@gmail.com>
contract AgreementDeliverableManager is AgreementDeliverableExecuteManager {
    enum ValidatorVote {
        NO,
        YES
    }

    struct Validators {
        address _user;
    }

    address internal constant SENTINEL_VALIDATORS = address(0x1);

    uint16 constant MINIMUM_NUM_VERIFIERS = 1;
    uint16 index;
    uint16 deliverablesCount;

    // Mappint to keep track of all deliverables added to the contract
    mapping(uint16 => Deliverable) public deliverables;

    // Mapping to keep track of all `validator`s that has casted their `validatorVote`
    mapping(address => mapping(uint16 => bool)) hasVoted;

    // Mapping to keep track of total number of (positive) `validatorVote` casted per deliverable
    mapping(uint16 => uint16) public validateCounts;

    // Mapping to keep track of `validator`s assigned to a deliverable
    mapping(uint16 => mapping(address => address)) public validators;

    // Mapping to keep track of all `validator` vote per deliverable
    mapping(uint16 => mapping(address => ValidatorVote)) public validatorVotes;

    // Mapping to keep track of the number of `validators` for each `deliverable`
    mapping(uint16 => uint16) public validatorsCount;

    event DeliverableSetup(uint numOfDeliverables, Deliverable[] deliverables);
    event DeliverableAdded(uint16 deliverableIndex, address user);
    event DeliverableRemoved(uint16 deliverableIndex, address user);
    event DeliverableValidated(uint16 deliverableIndex, uint16 validatorIndex);
    event ValidatorAdded(
        uint16 deliverableIndex,
        address _user,
        address validator
    );
    event ValidatorRemoved(
        uint16 deliverableIndex,
        address _user,
        address validator
    );
    event ValidatorVoted(
        uint16 deliverableIndex,
        address _validator,
        ValidatorVote _validatorVote
    );

    // modifiers;

    function setupDeliverables(
        Deliverable[] memory _deliverables,
        Executor[] memory _executors
    ) internal {
        for (uint i = 0; i < _deliverables.length; i++) {
            _addDeliverable(_deliverables[i]);
        }

        for (uint i = 0; i < _executors.length; i++) {
            _addExecutor(_executors[i]);
        }

        emit DeliverableSetup(_deliverables.length, _deliverables);
    }

    function addDeliverable(Deliverable memory _deliverable) public {
        _addDeliverable(_deliverable);
        emit DeliverableAdded(deliverablesCount, msg.sender);

        deliverablesCount += 1;
    }

    function _addDeliverable(Deliverable memory _deliverable) internal {
        Deliverable storage deliverable = deliverables[deliverablesCount];
        deliverable.title = _deliverable.title;
        deliverable.description = _deliverable.description;
        deliverable.payoutAmount = _deliverable.payoutAmount;
        deliverable.validatorThreshold = _deliverable.validatorThreshold;
        deliverable.totalSeconds = _deliverable.totalSeconds;

        deliverablesCount += 1;
    }

    function addValidator(uint16 _deliverableIndex, address _validator) public {
        _addValidator(_deliverableIndex, _validator);

        emit ValidatorAdded(_deliverableIndex, msg.sender, _validator);
    }

    function _addValidator(uint16 _deliverableIndex, address _validator)
        internal
    {
        // Check if deliverable exists
        require(deliverableExists(_deliverableIndex), "EC404");

        // Validator address cannot be null, this contract, or the sentinel
        require(
            _validator != address(0) &&
                _validator != address(this) &&
                _validator != SENTINEL_VALIDATORS,
            "EC400"
        );

        // No duplicate validator allowed
        require(
            validators[_deliverableIndex][_validator] == address(0),
            "EC409"
        );

        if (validators[_deliverableIndex][SENTINEL_VALIDATORS] == address(0)) {
            validators[_deliverableIndex][SENTINEL_VALIDATORS] = _validator;
            validators[_deliverableIndex][_validator] = SENTINEL_VALIDATORS;
        } else {
            validators[_deliverableIndex][_validator] = validators[
                _deliverableIndex
            ][SENTINEL_VALIDATORS];
            validators[_deliverableIndex][SENTINEL_VALIDATORS] = _validator;
        }

        validatorsCount[_deliverableIndex] += 1;
    }

    function removeValidator(
        uint16 _deliverableIndex,
        address _validator,
        address _prevValidator
    ) public {
        // Check if deliverable exists
        require(deliverableExists(_deliverableIndex), "EC404");

        // Validator address cannot be null, this contract, or the sentinel
        require(
            _validator != address(0) &&
                _validator != address(this) &&
                _validator != SENTINEL_VALIDATORS,
            "EC400"
        );

        require(
            validators[_deliverableIndex][_prevValidator] == _validator,
            "EC404"
        );

        validators[_deliverableIndex][_prevValidator] = validators[
            _deliverableIndex
        ][_validator];
        validators[_deliverableIndex][_validator] = address(0);

        validatorsCount[_deliverableIndex] -= 1;

        if (
            validatorVotes[_deliverableIndex][_validator] == ValidatorVote.YES
        ) {
            delete validatorVotes[_deliverableIndex][_validator];
            validateCounts[_deliverableIndex] -= 1;
        }

        emit ValidatorRemoved(_deliverableIndex, msg.sender, _validator);
    }

    function validatorVote(uint16 _deliverableIndex, ValidatorVote _vote)
        public
    {
        // Validator must be registered.
        require(isValidator(_deliverableIndex, msg.sender), "EC401");

        // Validator cannot vote twice
        require(!hasVoted[msg.sender][_deliverableIndex], "EC403");

        validatorVotes[_deliverableIndex][msg.sender] = _vote;
        hasVoted[msg.sender][_deliverableIndex] = true;

        if (_vote == ValidatorVote.YES) {
            validateCounts[_deliverableIndex] += 1;
        }

        emit ValidatorVoted(_deliverableIndex, msg.sender, _vote);

        // If number of validators is equal to (or more than) validator threshold.
        if (
            validateCounts[_deliverableIndex] >=
            deliverables[_deliverableIndex].validatorThreshold
        ) {
            // TODO: Initiate timelock of 10 mins
            _execute(_deliverableIndex, deliverables[_deliverableIndex]);
            emit DeliverableValidated(
                _deliverableIndex,
                validateCounts[_deliverableIndex]
            );
        }
    }

    function getValidators(uint16 _deliverableIndex)
        external
        view
        returns (address[] memory)
    {
        require(deliverableExists(_deliverableIndex), "EC404");

        address[] memory _array = new address[](
            validatorsCount[_deliverableIndex]
        );
        uint _index = 0;
        address currentValidator = validators[_deliverableIndex][
            SENTINEL_VALIDATORS
        ];
        while (currentValidator != SENTINEL_VALIDATORS) {
            _array[_index] = currentValidator;
            currentValidator = validators[_deliverableIndex][currentValidator];
            _index++;
        }

        return _array;
    }

    function isValidator(uint16 _deliverableIndex, address _validator)
        internal
        view
        returns (bool)
    {
        return
            _validator != SENTINEL_VALIDATORS &&
            validators[_deliverableIndex][_validator] != address(0);
    }

    function deliverableExists(uint16 _deliverableIndex)
        internal
        view
        returns (bool)
    {
        return _deliverableIndex < deliverablesCount;
    }
}
