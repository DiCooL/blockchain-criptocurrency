// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DAOGallery is ERC721, Ownable {
    uint256 private _nextTokenId;
    uint256 private _priceInWei;
    uint256 private _maxSupply;

    error maxSupplyReached();
    error notEnoughMoney();
    error alreadyHaveNFT();

    constructor(address initialOwner, uint256 price, uint256 maxSupply)
        ERC721("DAO-gallery", "DAOG")
        Ownable(initialOwner)
    {
        _priceInWei = price;
        _maxSupply = maxSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/";
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        require(_nextTokenId < _maxSupply, maxSupplyReached());
        require(super.balanceOf(to) == 0, alreadyHaveNFT());

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function buy(address) public payable {
        require(_nextTokenId < _maxSupply, maxSupplyReached());
        require(msg.value >= _priceInWei, notEnoughMoney());
        require(super.balanceOf(msg.sender) == 0, alreadyHaveNFT());

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, notEnoughMoney());
        payable(msg.sender).transfer(balance);
    }
}
