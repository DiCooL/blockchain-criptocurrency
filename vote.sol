// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Election {

    address private owner;

    string[] public electors;
    //["trampe","piton","frs","bisos"]

    uint256 private maxVotes;

    uint256 public votes;

    uint256 public electionTime;

    mapping(address => bool) public userVotes;

    mapping(uint256 => uint256) public numberOfVotes;

    constructor(string[] memory _electors, uint256 _maxVotes, uint256 _electionTime) {
        maxVotes = _maxVotes;
        electionTime = _electionTime + block.timestamp;
        electors = _electors;
        owner = msg.sender;
    }

    function vote(uint256 _number) public {
        require(userVotes[msg.sender]==false, "Your address can't vote");
        require(_number < electors.length, "Elector does not exist");
        require(votes < maxVotes, "Too much votes");
        require(owner != msg.sender, "You can't vote");
        require(block.timestamp <= electionTime, "Time the end");

        userVotes[msg.sender] = true;
        numberOfVotes[_number] += 1;
        votes += 1;
    }

    function stopVote() public {
        require(msg.sender == owner, "Voting continue");
        electionTime = block.timestamp;
    }

    function resetMaxVotes( uint256 _maxVotes) public {
        require(msg.sender == owner, "You can't do it");
        maxVotes = _maxVotes;
    }

}