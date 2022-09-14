// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// @title Agreement Info section represents that part of a contract that provides
//        textual (non-executable) information. This can include disclamer, copyright,
//        introductions, etc
// @author Nartey Kodjo-Sarso - <narteysarso@gmail.com>

/// @dev It is likely the best to make this an nft (gated by lit protocol)
///       and not store it directly on the blockchain.
contract AgreementInfoManager {
    event SectionAdded(uint16 indexed sectionIndex, string content);
    uint16 sectionIndex;

    mapping(uint16 => string) public sections;

    function addSection(string memory _content) public {
        sections[sectionIndex] = _content;
        emit SectionAdded(sectionIndex, _content);
        sectionIndex++;
    }
}