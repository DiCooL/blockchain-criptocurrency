// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Election {

    address private owner;

    string[] public electors;

    uint256 private maxVotes;

    uint256 public votes;

    uint256 public electionTime;

    mapping(address => bool) public userVotes;

    mapping(uint256 => uint256) public numberOfVotes;

    event voted(uint256 _index, address _voter);
    event voteStopped();
    event voteResumed();

    error OnlyOwnerAllowed();
    error ElectorsDoesNotExist(uint256 _pickedElector, uint256 totalElectors);
    error YouCantVoteTwice();
    error OwnerCantVote();
    error MaxVotesReach(uint256 _maxVotes);
    error VotingIsOver();

    constructor(string[] memory _electors, uint256 _maxVotes, uint256 _electionTime) {
        maxVotes = _maxVotes;
        electionTime = _electionTime + block.timestamp;
        electors = _electors;
        owner = msg.sender;
    }

    function getLeader() public view returns(uint256) {
        uint256 leaderIndex;

        for(uint i = 0; i < electors.length; i++) {
            if(numberOfVotes[i] > numberOfVotes[leaderIndex]){
                leaderIndex = i;
            }
        }

        return leaderIndex;
    }

    function vote(uint256 _number) public {
        require(userVotes[msg.sender]==false, YouCantVoteTwice());
        require(_number < electors.length, ElectorsDoesNotExist(_number, electors.length));
        require(votes < maxVotes, MaxVotesReach(maxVotes));
        require(owner != msg.sender, OwnerCantVote());
        require(block.timestamp <= electionTime, VotingIsOver());

        userVotes[msg.sender] = true;
        numberOfVotes[_number] += 1;
        votes += 1;

        emit voted(_number, msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, OnlyOwnerAllowed());
        _;
    }

    function stopVote() public onlyOwner {
        electionTime = block.timestamp;

        emit voteStopped();
    }

    function resetMaxVotes(uint256 _maxVotes) public onlyOwner {
        maxVotes = _maxVotes;

        emit voteResumed();
    }

    function resetEndTime(uint256 _newEndTime) public onlyOwner {
        electionTime = _newEndTime;

        emit voteResumed();
    }

}