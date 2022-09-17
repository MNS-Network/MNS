// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";

interface IMasks {
    function ownerOf(uint256 index) external view returns (address);
    function getNftName(uint256 nftId) external view returns(string memory);
    function getNftByName(string memory name) external view returns (uint256);
}

contract Parse is Ownable {
    struct Single {
        string key;
        string text;
        string wallet;
        uint256 itype;
    }

    struct DeleteTag {
        string key;
        uint256 itype;
    }

    struct BnsInfo {
        mapping(string=>uint256) chainMap;
        string[] chainList;
        string[] walletList;
        mapping(string=>uint256) textMap;
        string[] nameList;
        string[] textList;
    }
    mapping(uint256 => BnsInfo) private infoMap;
    address public _punkAddress = 0xE1A19A88e0bE0AbBfafa3CaE699Ad349717CA7F2;
    mapping(string => string) private _addToName;
    mapping(string => string) private _nameToAdd;
    mapping(string => mapping(string => uint256)) private _addPList;
    mapping(string => string[]) private _addKeyMap;
    
    event SetSingle(uint256 nftId, string key, string value, uint256 itype);
   // event SetBatch(uint256 nftId, Single[] list);
    event SetBatch(uint256 nftId, string[] keys, string[] infos, uint256[] types);
    event DeleteSingle(uint256 nftId, string key, uint256 itype);
   // event DeleteBatch(uint256 nftId, DeleteTag[] list);
    event DeleteBatch(uint256 nftId, string[] keys, uint256[] types);

    function setPunkContract(address punk) public onlyOwner {
        _punkAddress = punk;
    }
    
    function getAddressNameList(string memory user) public view returns(string[] memory) {
        string[] memory keyList = _addKeyMap[user];
        require(keyList.length > 0, "do not have info.");
        //if (keyList.length < 1) {return [];}
        string[] memory nameList = new string[](keyList.length);
        for (uint256 i = 0; i < keyList.length; i++) {
            uint256 res = _addPList[user][keyList[i]];
            if (res > 1) {
                nameList[i] = keyList[i];
            }else {
                nameList[i] = "";
            }
        }
        return nameList;
    }

    function getOwner(uint256 nftId) public view returns(address) {
        return IMasks(_punkAddress).ownerOf(nftId);
    }
    
    function addressToHost(string memory user) public view returns(string memory) {
        return _addToName[user];
    }

    function named(uint256 nftId) public view returns(bool) {
        string memory nftName = IMasks(_punkAddress).getNftName(nftId);
        return bytes(nftName).length>0;
    }
    
    function setHostAddress(string memory name, string memory user) public {
        string memory trxName = getSlice(1, bytes(name).length-4, name);
        uint256 nftId = IMasks(_punkAddress).getNftByName(trxName);
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        
        require(keccak256(abi.encodePacked(_nameToAdd[name])) == keccak256(abi.encodePacked(user)), "name not parse to address.");
        
        _addToName[user] = name;
    }
    
    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns(string memory) {
         bytes memory a = new bytes(end-begin + 1);
         for(uint256 i = 0; i <= end-begin; i++) {
             a [i] = bytes(text)[i + begin-1];
         }
         return string(a);
     }
    
    function setBatchInfos(uint256 nftId, string[] memory keys, string[] memory infos, uint256[] memory types) public {
        require(keys.length > 0, "list can not be empty");
        require(keys.length == infos.length && infos.length == types.length, "params error");
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(named(nftId), "not set host name.");
        
         for (uint i = 0; i < keys.length; i++) {
            //Single memory item = Single("", "", "", 0);
            string memory key = toLower(keys[i]);
            uint256 itype = types[i];
            if (itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.chainMap[key] > 0) {
                    uint256 pos = itemInfo.chainMap[key]-1;
                    itemInfo.walletList[pos] = infos[i];
                }else {
                    itemInfo.chainMap[key] = itemInfo.walletList.length+1;
                    itemInfo.walletList.push(infos[i]);
                    itemInfo.chainList.push(key);
                }
                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("tron"))) {
                    string memory name = IMasks(_punkAddress).getNftName(nftId);
                    string memory oldAdd = _nameToAdd[name];
                    _nameToAdd[name] = infos[i];
                    if (_addPList[infos[i]][name] < 1) {
                        _addKeyMap[infos[i]].push(name);
                    }
                    _addPList[infos[i]][name] = 6;
                    if (bytes(oldAdd).length > 1) {
                        _addPList[oldAdd][name] = 1;
                    }
                }
               // emit SetSingle(nftId, key, item.wallet, 1);
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                if (itemInfo.textMap[key] > 0) {
                    uint256 pos = itemInfo.textMap[key]-1;
                    itemInfo.textList[pos] = infos[i];
                }else {
                    itemInfo.textMap[key] = itemInfo.textList.length+1;
                    itemInfo.textList.push(infos[i]);
                    itemInfo.nameList.push(key);
                }
                //emit SetSingle(nftId, key, item.text, 2);
            }
        }
        emit SetBatch(nftId, keys, infos, types);
    }

   
    function deleteBatch(uint256 nftId, string[] memory keys, uint256[] memory types) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(keys.length > 0, "list can not be empty");
        require(keys.length == types.length, "length not same.");

        for (uint i = 0; i < keys.length; i++) {
            string memory key = toLower(keys[i]);
            uint256 itype = types[i];
            if (itype == 1) {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.chainMap[key]-1;
                itemInfo.walletList[pos] = "";
                itemInfo.chainMap[key] = 0;
               // emit DeleteSingle(nftId, key, 1);
               
                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("tron"))) {
                    string memory name = IMasks(_punkAddress).getNftName(nftId);
                    string memory oldAdd = _nameToAdd[name];
                    if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(_addToName[oldAdd]))) {
                        _addToName[oldAdd] = "";
                    }
                    _nameToAdd[name] = "";
                    _addPList[oldAdd][name] = 1;
                }
            }else {
                BnsInfo storage itemInfo = infoMap[nftId];
                uint256 pos = itemInfo.textMap[key]-1;
                itemInfo.textList[pos] = "";
                itemInfo.textMap[key] = 0;
              //  emit DeleteSingle(nftId, key, 2);
            }
        }

       emit DeleteBatch(nftId, keys, types);
    }

    function deleteText(uint256 nftId, string memory keyName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        
        keyName = toLower(keyName);
        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.textMap[keyName]-1;
        itemInfo.textList[pos] = "";
        itemInfo.textMap[keyName] = 0;

        emit DeleteSingle(nftId, keyName, 2);
    }

    function deleteWallet(uint256 nftId, string memory chainName) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");

        chainName = toLower(chainName);
        BnsInfo storage itemInfo = infoMap[nftId];
        uint256 pos = itemInfo.chainMap[chainName]-1;
        itemInfo.walletList[pos] = "";
        itemInfo.chainMap[chainName] = 0;
        
        if (keccak256(abi.encodePacked(chainName)) == keccak256(abi.encodePacked("tron"))) {
            string memory name = IMasks(_punkAddress).getNftName(nftId);
            string memory oldAdd = _nameToAdd[name];
            if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(_addToName[oldAdd]))) {
                _addToName[oldAdd] = "";
            }
            _nameToAdd[name] = "";
            _addPList[oldAdd][name] = 1;
        }

        emit DeleteSingle(nftId, chainName, 1);
    }

    function setWallet(uint256 nftId, string memory chainName, string memory wallet) public returns(uint256) {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(named(nftId), "not set host name.");

        BnsInfo storage itemInfo = infoMap[nftId];
        chainName = toLower(chainName);
        if (itemInfo.chainMap[chainName] > 0) {
            uint256 pos = itemInfo.chainMap[chainName]-1;
            itemInfo.walletList[pos] = wallet;
        }else {
            itemInfo.chainMap[chainName] = itemInfo.walletList.length+1;
            itemInfo.walletList.push(wallet);
            itemInfo.chainList.push(chainName);
        }
        if (keccak256(abi.encodePacked(chainName)) == keccak256(abi.encodePacked("tron"))) {
            string memory name = IMasks(_punkAddress).getNftName(nftId);
            string memory oldAdd = _nameToAdd[name];
            _nameToAdd[name] = wallet;
            //_addPList[wallet][name] = 6;
            //_addKeyMap[wallet].push(name);
            if (_addPList[wallet][name] < 1) {
                _addKeyMap[wallet].push(name);
            }
            _addPList[wallet][name] = 6;
            if (bytes(oldAdd).length > 1) {
                _addPList[oldAdd][name] = 1;
            }
        }

        emit SetSingle(nftId, chainName, wallet, 1);
        return itemInfo.chainMap[chainName];
    }

    function setTextItem(uint256 nftId, string memory keyName, string memory textInfo) public {
        require(IMasks(_punkAddress).ownerOf(nftId) == msg.sender, "not the Owner");
        require(named(nftId), "not set host name.");

        BnsInfo storage itemInfo = infoMap[nftId];
        keyName = toLower(keyName);
        if (itemInfo.textMap[keyName] > 0) {
            uint256 pos = itemInfo.textMap[keyName]-1;
            itemInfo.textList[pos] = textInfo;
        }else {
            itemInfo.textMap[keyName] = itemInfo.textList.length+1;
            itemInfo.textList.push(textInfo);
            itemInfo.nameList.push(keyName);
        }

        emit SetSingle(nftId, keyName, textInfo, 2);
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

    function getNftTextInfo(uint256 nftId) public view returns(string[] memory nameList, string[] memory textList) {
        return (infoMap[nftId].nameList, infoMap[nftId].textList);
    }

    function getNftWallet(uint256 nftId) public view returns(string[] memory chainList, 
        string[] memory walletList) {
        return (infoMap[nftId].chainList, infoMap[nftId].walletList);
    }
}