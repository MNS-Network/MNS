//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IRule {
    function validateName(string memory str) external view returns (bool);
    function toLower(string memory str) external view returns (string memory);
}

contract MNSBadge is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI;
    address public _ruleContract;
    mapping (uint256 => string) private _tokenName;
    mapping (string => uint256) private _repeatName;
    mapping (string => uint256) private _nameReserved;
    
    event mintBadge(uint256 time, address owner, uint256 nftId);
    event wishName(uint256 nftId, string name, address owner, uint256 time);
    
    constructor(address ruleContract)
        ERC721A("MNS Badge", "BMNS")

    {
        baseURI = "";
        _ruleContract = ruleContract;
    }
    
    function getWishName(uint256 nftId) public view returns(string memory) {
        return _tokenName[nftId];
    }
    
    function setRuleContract(address ruleContract) public onlyOwner {
        _ruleContract = ruleContract;
    }
    
    function setBaseUri(string memory url) public onlyOwner {
        baseURI = url;
    }
    
    function mintFor(address[] memory whiteList) public onlyOwner {
        require(whiteList.length >0, "data can not ne empty");
        for (uint256 i = 0; i < whiteList.length; i++) {
            address whiteUser = whiteList[i];
            uint256 nftId = totalSupply();
            _safeMint(whiteUser, 1);
            emit mintBadge(block.timestamp, whiteUser, nftId);
        }
    }
    
    function makeWish(uint256 nftId,string memory name) public {
        require(_msgSender() == ownerOf(nftId), "ERC721: caller is not the owner");
        require(IRule(_ruleContract).validateName(name) == true, "Not a valid new name");
        
        _tokenName[nftId] = name;
        string memory lowName = IRule(_ruleContract).toLower(name);
        if (_nameReserved[lowName] > 0) {
            _repeatName[lowName] = 1;
        }
        _nameReserved[lowName] += 1;
        emit wishName(nftId, name, _msgSender(), block.timestamp);
    }
    
    function canMint(uint256 nftId) public view returns(bool) {
        string memory lowName = IRule(_ruleContract).toLower(_tokenName[nftId]);
        if (_repeatName[lowName] > 0) {
            return false;
        }else {
            return true;
        }
    }
    
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

}