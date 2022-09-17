//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IBadge {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function canMint(uint256 nftId) external view returns(bool);
    function getWishName(uint256 nftId) external view returns(string memory);
}

interface IRule {
    function validateName(string memory str) external view returns (bool);
   // function toLower(string memory str) external view returns (string memory);
}

interface IMasks {
    function ownerOf(uint256 index) external view returns (address);
    function getNftName(uint256 nftId) external view returns(string memory);
    function getNftByName(string memory name) external view returns (uint256);
}

interface ITNS {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
   // function approve(address to, uint256 tokenId) external;
}

interface IRelationShipStore {
    function addUserFirstItem(uint256 invitorId, address user, uint256 nftId) external returns (bool);
    function addUserSecItem(uint256 firstInvitor, address user, uint256 nftId) external returns (bool);
    function setFirstInvitor(uint256 nftId, uint256 invitorId) external returns(bool);
    function setSecInvitor(uint256 nftId, uint256 invitorId) external returns(bool);
    function getFirstInvitor(uint256 nftId) external view returns(uint256);
    function getSecInvitor(uint256 nftId) external view returns(uint256);
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
}

pragma experimental ABIEncoderV2;

contract TronMNS is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI;
    
    address public _relationAddress;
    address public _ruleContract;
    address public _badgeAddress;
    mapping (uint256 => uint256) private _nft2UriId;
    uint256 public _saleCount = 0;
    uint256 public _supplyCount = 10000;
    uint256 public _raleCount = 0;
    uint256 public _raleSupply = 302;
    mapping (address => uint256) private _tnsWhite;
    mapping (address => uint256) private _whiteList;
    mapping (string => uint256) private _lockName;
    mapping (uint256 => string) private _tokenName;
    mapping (string => uint256) private _nameToken;
    mapping (string => uint256) private _nameReserved;
    uint256 public NAME_CHANGE_PRICE = 1000 * (10 ** 6);
    bool public nameEnable = false;
    uint256 public _firstRate = 25;
    uint256 public _secRate = 10;
    uint256 public _whiteRate = 30;
    bool public _openTns = true;
    bool public _preSale = false;

    mapping (address => uint256) private _bnbReword; 

    address public _nctAddress;
    address public _tnsAddress;
    AggregatorInterface internal priceFeed;

    event BuyNftWithTrx(uint256 time, address owner, uint256 nftId, uint256 price, uint256 invitorId, uint256 secId);
    event NameChange(uint256 nftId, string newName, address owner, uint256 time);
    event Transfer(uint256 nftId, address from, address to, uint256 time);

    constructor(address relationAddress, address tnsAddress, address ruleAddress, address badgeAddress)
        ERC721A("Metaverse Name Service", "MNS")

    {
         _relationAddress = relationAddress;
         _ruleContract = ruleAddress;
         _badgeAddress = badgeAddress;
         _tnsAddress = tnsAddress;  //TQs6pqT88fr5q2oMoXRQTbfifHuaMmayUy
        //TXwZqjjw4HtphG4tAm5i1j1fGHuXmYKeeP mainNet
        //priceFeed = AggregatorInterface(0xf10354C1BE7A8b015aA9152132cfD4B620c67775); //主网
        priceFeed = AggregatorInterface(0x03F33E70Ecb0FD68d64C8190128BdC0F17511B89);
        // @dev make sure to keep baseUri as empty string to avoid your metadata being sniped
        setBaseURI("https://api.mns.network/mns/metadata/");
    }
    
    function getUriId(uint256 nftId) public view returns(uint256) {
        return _nft2UriId[nftId];
    }
    
    function getTnsOpen() public view returns(bool) {
        return _openTns;
    }
    
    function setTnsOpen() public onlyOwner {
        _openTns = !_openTns;
    }
    
    function setPreSale() public onlyOwner {
        _preSale = !_preSale;
    }
    
    function setFirstRate(uint256 rate) public onlyOwner {
        _firstRate = rate;
    }
    
    function setSecondRate(uint256 rate) public onlyOwner {
        _secRate = rate;
    }
    
    function setBadgeContract(address badgeAddress) public onlyOwner {
        _badgeAddress = badgeAddress;
    }
    
    function setRelationContract(address relationAddress) public onlyOwner {
        _relationAddress = relationAddress;
    }
    
    function setTnsContract(address tnsAddress) public onlyOwner {
        _tnsAddress = tnsAddress;
    }
    
    function setRuleContract(address ruleAddress) public onlyOwner {
        _ruleContract = ruleAddress;
    }
    
    function setTnsWhite(address user, uint256 amount) public onlyOwner {
        //require(_tnsWhite[user]==0, "already")
        _tnsWhite[user] = _tnsWhite[user].add(amount);
    }
    
    function nameReserved(string memory name) public view returns(uint256) {
        return _nameReserved[name];
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setSingleWhite(address whiteAddress) public onlyOwner {
        require(_whiteList[whiteAddress]==0, "already set white.");
        _whiteList[whiteAddress] = _whiteList[whiteAddress]+1;
    }
    
    function checkWhite(address whiteAddress) public view returns(uint256) {
        return _whiteList[whiteAddress];
    }
    
    function mintWhite(string memory newName) public returns(uint256) {
        require(_whiteList[msg.sender] > 0, "do not have permssion.");
        require(_saleCount.add(1) < _supplyCount, "coin not enough to sell");
        require(IRule(_ruleContract).validateName(newName) == true, "Not a valid new name");
        require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
        require(bytes(newName).length>=9 && bytes(newName).length<=21, "name length error.");
        require(block.timestamp-_lockName[newName]>48*3600 || msg.sender == ownerOf(_nameToken[newName]));
        
        uint256 nftId = totalSupply();
        _safeMint(msg.sender, 1);
        _nft2UriId[nftId] = _saleCount.add(302);
        _saleCount = _saleCount.add(1);
        
        _whiteList[msg.sender] = 0;
        _nameReserved[toLower(newName)] = nftId;
        _tokenName[nftId] = newName;
        _nameToken[newName] = nftId;
        emit NameChange(nftId, newName, msg.sender, block.timestamp);
        emit BuyNftWithTrx(block.timestamp, msg.sender, nftId, 0, 0, 0);
        
        return nftId;
    }

    // FACTORY
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory currentBaseURI = baseURI;
       // uint256 uriId = _nft2UriId[_tokenId];
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    
    function isNameLocked(string memory name) public view returns(uint256) {
        return _lockName[name];
    }

    function getLatestPrice() public view returns (int) {
        // require(priceFeed.latestTimestamp() > 0, "Round not complete");
        // return priceFeed.latestAnswer();
        return 65950;
    }

    function setNftName(uint256 nftId, string memory newName) internal {
        require(_msgSender() == ownerOf(nftId), "ERC721: caller is not the owner");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[nftId])), "New name is same as the current one");
        require(IRule(_ruleContract).validateName(newName) == true, "Not a valid new name");
        require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
        require(block.timestamp-_lockName[newName]>48*3600 || msg.sender== ownerOf(_nameToken[newName]), "name is locked.");

        // If already named, dereserve old name
        if (bytes(_tokenName[nftId]).length > 0) {
            //toggleReserveName(_tokenName[nftId], 0);
            _nameReserved[toLower(_tokenName[nftId])] = 0;

        }
        //toggleReserveName(newName, nftId);
        _nameToken[_tokenName[nftId]] = 0;
        _nameReserved[toLower(newName)] = nftId;
        _tokenName[nftId] = newName;
        _nameToken[newName] = nftId;
        emit NameChange(nftId, newName, msg.sender, block.timestamp);
    }

    function changeName(uint256 nftId, string memory newName) public {
        require(nameEnable, "not open");            

        uint256 changePrice = getChangePrice(bytes(newName).length);
        IERC20(_nctAddress).transferFrom(msg.sender, address(this), changePrice);
        setNftName(nftId, newName);
    }
    
    function getTnsWhiteCount(address user) public view returns(uint256) {
        return _tnsWhite[user];
    }

    function setNameChangePrice(uint256 price) public onlyOwner {
        NAME_CHANGE_PRICE = price;
    }
    
    function getChangePrice(uint256 nameLength) public view returns(uint256) {
        if (3 == nameLength) {
            return 35000*1000000;
        }else if (4 == nameLength) {
            return 10000*1000000;
        }else if (nameLength>=5 && nameLength <= 8) {
            return 3000*100000;
        }else if (nameLength>=9 && nameLength <= 21) {
            return 1000*100000;
        }else {
            return 0;
        }
    }

    function getNFTPrice(uint256 nameLength) public view returns (uint256) {
        if (3 == nameLength) {
            return 699*1000000;
        }else if (4 == nameLength) {
            return 199*1000000;
        }else if (nameLength>=5 && nameLength <= 8) {
            return 599*100000;
        }else if (nameLength>=9 && nameLength <= 21) {
            return 159*100000;
        }else {
            return 0;
        }
    }

    function getReword(address user) public view returns(uint256) {
        return _bnbReword[user];
    }

    function claim() public returns(bool) {
        require(_bnbReword[msg.sender]>0, "balance empty");

        uint256 amount = _bnbReword[msg.sender];
        payable(msg.sender).transfer(amount);
        _bnbReword[msg.sender] = 0;
        return true;
    }

    function getBuyPrice( uint256 nameLength) public view returns(uint256) {
        uint256 price = getNFTPrice(nameLength);
        return price.mul(10**6).div(uint256(getLatestPrice()));
    }
    
    function checkPriceList(string[] memory newNameList) private returns(uint256) {
        uint256 price = getNFTPrice(bytes(newNameList[0]).length);
        string memory name = newNameList[0];
        if (!IRule(_ruleContract).validateName(name) || _nameReserved[toLower(name)] > 0) {return 0;}
        if(block.timestamp-_lockName[name]<=48*3600 && msg.sender != ownerOf(_nameToken[name])){return 0;}
        if (newNameList.length > 1) {
            for (uint256 i = 0; i < newNameList.length; ++i) {
                name = newNameList[i];
                if (!IRule(_ruleContract).validateName(name) || _nameReserved[toLower(name)] > 0) {return 0;}
                if(block.timestamp-_lockName[name]<=48*3600 && msg.sender!= ownerOf(_nameToken[name])){return 0;}
                uint256 curPrice = getNFTPrice(bytes(name).length);
                if (curPrice != price) {return 0;}
            }
        }
        return price.mul(newNameList.length).mul(10**6).div(uint256(getLatestPrice()));
    }
    
    function setSaleCount(uint256 totalCount) public onlyOwner {
        _supplyCount = totalCount;
    }
  
    function buyWithName(uint256 invitorId, string[] memory newNameList) public payable returns(uint256) {
        uint256 amount = newNameList.length;
        require(amount>0&&amount<21, "nameList must have something.");
        require(_saleCount.add(amount) < _supplyCount, "coin not enough to sell");
       
        uint256 buyPrice = checkPriceList(newNameList);
        require(buyPrice > 0 && buyPrice <= msg.value, "TRX value sent is not correct or name not correct.");
   
        uint256 supply = totalSupply();
        _safeMint(msg.sender, amount);

        uint256 firstId = IRelationShipStore(_relationAddress).getFirstInvitor(invitorId);
        for (uint i = 0; i < amount; i++) {
            uint256 nftId = supply.add(i);
            //ownerOf(nftId) = msg.sender;
            _nft2UriId[nftId] = _saleCount.add(302).add(i);
            if (invitorId > 0) {
                IRelationShipStore(_relationAddress).setFirstInvitor(nftId, invitorId);
                IRelationShipStore(_relationAddress).addUserFirstItem(invitorId, msg.sender, nftId);

                uint256 firstInvitorId = IRelationShipStore(_relationAddress).getFirstInvitor(invitorId);
                if (firstInvitorId > 0) {
                    IRelationShipStore(_relationAddress).setSecInvitor(nftId, firstInvitorId);
                    IRelationShipStore(_relationAddress).addUserSecItem(firstInvitorId, msg.sender, nftId);
                }
            }

            uint256 nftInvitor = IRelationShipStore(_relationAddress).getFirstInvitor(nftId);
            if (nftInvitor > 0) {
                _bnbReword[ownerOf(nftInvitor)] = _bnbReword[ownerOf(nftInvitor)].add(msg.value.mul(_firstRate).div(100));
                uint256 secInvitor = IRelationShipStore(_relationAddress).getSecInvitor(nftId);
                if (secInvitor > 0) {
                    _bnbReword[ownerOf(secInvitor)] = _bnbReword[ownerOf(secInvitor)].add(msg.value.mul(_secRate).div(100));
                }
            }
            
            string memory newName = newNameList[i];
            _nameReserved[toLower(newName)] = nftId;
            _tokenName[nftId] = newName;
            _nameToken[newName] = nftId;
            emit NameChange(nftId, newName, msg.sender, block.timestamp);
            emit BuyNftWithTrx(block.timestamp, msg.sender, nftId, msg.value.div(amount), invitorId, firstId);
        }
        _saleCount = _saleCount.add(amount);

        return _saleCount;
    }
    
    function useBadgeToMint() public payable returns(uint256) {
        require(_preSale, "preSale mns is close.");
        require(IBadge(_badgeAddress).balanceOf(msg.sender)>0, "do not have any tns.");
        require(_saleCount.add(1) < _supplyCount, "coin not enough to sell");
        
        uint256 tokenId = IBadge(_badgeAddress).tokenOfOwnerByIndex(msg.sender, 0);
        require(IBadge(_badgeAddress).canMint(tokenId), "this badge can not mint.");
        string memory newName = IBadge(_badgeAddress).getWishName(tokenId);
        require(IRule(_ruleContract).validateName(newName) == true, "Not a valid new name");
        require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
        
        uint256 price = getNFTPrice(bytes(newName).length);
        uint256 needPay = price.mul(10**6).mul(_whiteRate).div(100).div(uint256(getLatestPrice()));
        require(needPay<=msg.value, "pay not enough.");
        
       // require(bytes(newName).length>=5 && bytes(newName).length<=8, "name length error.");
        require(block.timestamp-_lockName[newName]>48*3600 || msg.sender == ownerOf(_nameToken[newName]));
        
        // ITNS(_tnsAddress).approve(address(this), tokenId);
        IBadge(_badgeAddress).transferFrom(msg.sender, address(this), tokenId);
        
        uint256 nftId = totalSupply();
        _safeMint(msg.sender, 1);
        _nft2UriId[nftId] = _saleCount.add(302);
        _saleCount = _saleCount.add(1);
        
        _nameReserved[toLower(newName)] = nftId;
        _tokenName[nftId] = newName;
        _nameToken[newName] = nftId;
        
        emit NameChange(nftId, newName, msg.sender, block.timestamp);
        emit BuyNftWithTrx(block.timestamp, msg.sender, nftId, 0, 0, 0);
        
        return nftId;
    }
    
    function mintForSpecial(address user, string memory newName) public onlyOwner returns(uint256) {
        require(_raleCount.add(1) < _raleSupply, "coin not enough to sell");
        require(IRule(_ruleContract).validateName(newName), "Not a valid new name");
        require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
        require(bytes(newName).length>=4 && bytes(newName).length<=8, "name length error");
        require(block.timestamp-_lockName[newName]>48*3600 || msg.sender == ownerOf(_nameToken[newName]));
        
        uint256 nftId = totalSupply();
        _safeMint(user, 1);
        
        _nft2UriId[nftId] = _raleCount;
        _raleCount = _raleCount.add(1);

        _nameReserved[toLower(newName)] = nftId;
        _tokenName[nftId] = newName;
        _nameToken[newName] = nftId;
        emit NameChange(nftId, newName, user, block.timestamp);
        emit BuyNftWithTrx(block.timestamp, user, nftId, 0, 0, 0);
        
        return nftId;
    }
    
    function mintForOwn(address user, string[] memory newNameList) public onlyOwner returns(bool) {
        uint256 amount = newNameList.length;
        require(amount > 0, "name list cannot be empty.");
        require(_saleCount.add(amount) < _supplyCount, "coin not enough to sell");
        
        for (uint256 i = 0; i < amount; i++) {
            string memory newName = newNameList[i];
            require(IRule(_ruleContract).validateName(newName) == true, "Not a valid new name");
            require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
            // require(bytes(newName).length>=5 && bytes(newName).length<=8, "name length error.");
            require(block.timestamp-_lockName[newName]>48*3600 || msg.sender == ownerOf(_nameToken[newName]));
        
            uint256 nftId = totalSupply();
            _safeMint(user, 1);
            _nft2UriId[nftId] = _saleCount.add(302);
            _saleCount = _saleCount.add(1);
        
            _nameReserved[toLower(newName)] = nftId;
            _tokenName[nftId] = newName;
            _nameToken[newName] = nftId;
            emit NameChange(nftId, newName, user, block.timestamp);
            emit BuyNftWithTrx(block.timestamp, user, nftId, 0, 0, 0);
        }
       
        
        return true;
    } 
    
    function useTnsToMint(string memory newName) public returns(uint256) {
        require(_openTns, "tns transfer mns is close.");
        require(ITNS(_tnsAddress).balanceOf(msg.sender)>0, "do not have any tns.");
        require(_saleCount.add(1) < _supplyCount, "coin not enough to sell");
        require(IRule(_ruleContract).validateName(newName) == true, "Not a valid new name");
        require(_nameReserved[toLower(newName)] <= 0, "Name already reserved");
        require(bytes(newName).length>=5 && bytes(newName).length<=8, "name length error.");
        require(block.timestamp-_lockName[newName]>48*3600 || msg.sender == ownerOf(_nameToken[newName]));
        
        uint256 tokenId = ITNS(_tnsAddress).tokenOfOwnerByIndex(msg.sender, 0);
        // ITNS(_tnsAddress).approve(address(this), tokenId);
        ITNS(_tnsAddress).transferFrom(msg.sender, address(this), tokenId);
        
        uint256 nftId = totalSupply();
        _safeMint(msg.sender, 1);
        _nft2UriId[nftId] = _saleCount.add(302);
        _saleCount = _saleCount.add(1);
        
        _nameReserved[toLower(newName)] = nftId;
        _tokenName[nftId] = newName;
        _nameToken[newName] = nftId;
        
        emit NameChange(nftId, newName, msg.sender, block.timestamp);
        emit BuyNftWithTrx(block.timestamp, msg.sender, nftId, 0, 0, 0);
        
        return nftId;
    }
    
    function setRaleName(uint256 nftId, string memory name) public onlyOwner {
        require(_nameReserved[toLower(name)] <= 0, "Name already reserved");
        require(block.timestamp-_lockName[name]>48*3600 || msg.sender == ownerOf(_nameToken[name]));
        
         if (bytes(_tokenName[nftId]).length > 0) {
            //toggleReserveName(_tokenName[nftId], 0);
            _nameReserved[toLower(_tokenName[nftId])] = 0;

        }
        //toggleReserveName(newName, nftId);
        _nameToken[_tokenName[nftId]] = 0;
        _nameReserved[toLower(name)] = nftId;
        _tokenName[nftId] = name;
        _nameToken[name] = nftId;
        emit NameChange(nftId, name, msg.sender, block.timestamp);
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        (bool r1, ) = payable(msg.sender).call{value: balance}("");
        require(r1);
    }

    function getNftName(uint256 nftId) public view returns(string memory) {
        return string(abi.encodePacked(_tokenName[nftId], ".trx"));
       // return _tokenName[nftId];
    }

    function getNftByName(string memory name) public view returns (uint256) {
        return _nameToken[name];
    }

    function setNameEnable(bool state) public onlyOwner {
        nameEnable = state;
    }

    function setNameChangeContract(address nctAddress) public onlyOwner {
        _nctAddress = nctAddress;
    }

    function toLower(string memory str) private pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
       /* 
        @dev override transferOwnership from Ownable
         transfer ownership with multisig
    */
    function transferOwnership(address newOwner) public virtual override(Ownable) onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

}
