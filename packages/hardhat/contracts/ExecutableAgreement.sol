// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.14;

import "./base/AgreementDeliverableManager.sol";
import "./base/AgreementInfoManager.sol";
import "./base/AgreementOfferManager.sol";

// @title Executable Agreement is an smart contract implementation of legal agreement.
// @author Nartey Kodjo-Sarso - <narteysarso@gmail.com>
contract ExecutableAgreement is
    AgreementOfferManager,
    AgreementInfoManager,
    AgreementDeliverableManager
{
    function createAgreement(
        OfferType _offerType,
        string memory _position,
        uint64 _duration,
        uint _contractSum,
        address _targetToken,
        Status _status,
        string memory _description,
        string memory _location,
        Deliverable[] memory _deliverables,
        Executor[] memory _executors
    ) public {
        require(msg.sender != address(0), "EC500");

        setupOffer(
            _offerType,
            _position,
            _duration,
            _contractSum,
            _targetToken,
            _status,
            _description,
            _location
        );

        setupDeliverables(_deliverables, _executors);
    }
}


//---------------------------Second Part -------------------------------------------
// @title Arbiter specifies and handle staking and arbitration, and realese of stake 
//        in cases of: 
//        - Agreement termination by any party
//        - Agreement expiration without contract completion:
//              - any party failed to deliver on promise
//              - all party fulfilled their promise
//              - unforseen natural disasters, events beyond control of any party
//              - declared liabilities, vulnerabilities, risks, and limitations.
//        
contract Arbiter {

}

contract AgreementSigningManager {

}


contract AgreementSBT {

}
