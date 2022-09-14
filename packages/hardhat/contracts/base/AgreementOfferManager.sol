// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.14;

// @title Agreement Offer Manager handles general agreement info about the contract offer
//        Its events are published to the subgraph for index.
// @author Nartey Kodjo-Sarso - <narteysarso@gmail.com>
contract AgreementOfferManager {
    enum OfferType {
        CONTRACT,
        FULL_TIME,
        PART_TIME
    }

    enum Status {
        AVAILABLE,
        UNAVAILABLE
    }

    string public position;

    uint64 public duration;

    uint256 public contractSum;

    Status public status;

    string public title;

    string public location;

    OfferType public offerType;

    address public targetToken;

    event OfferCreated(
        string position,
        uint64 duration,
        uint256 contractSum,
        address targetToken,
        Status status,
        string title,
        string location,
        OfferType offerType
    );

    function setupOffer(
        OfferType _offerType,
        string memory _position,
        uint64 _duration,
        uint _contractSum,
        address _targetToken,
        Status _status,
        string memory _title,
        string memory _location
    ) internal {
        position = _position;
        duration = _duration;
        contractSum = _contractSum;
        targetToken = _targetToken;
        status = _status;
        title = _title;
        location = _location;
        offerType = _offerType;

        emit OfferCreated(
            _position,
            _duration,
            _contractSum,
            _targetToken,
            _status,
            _title,
            _location,
            _offerType
        );
    }
}