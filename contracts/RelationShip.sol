pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Ownable.sol";

interface IRelationShipStore {
    function addUserFirstItem(uint256 invitorId, address user, uint256 nftId) external returns (bool);
    function addUserSecItem(uint256 firstInvitor, address user, uint256 nftId) external returns (bool);
    function setFirstInvitor(uint256 nftId, uint256 invitorId) external returns(bool);
    function setSecInvitor(uint256 nftId) external returns(bool);
    function getFirstInvitor(uint256 nftId) external view returns(uint256);
    function getSecInvitor(uint256 nftId) external view returns(uint256);
}

contract RelationShip is Ownable {
    struct UserInfo {
        uint256 time;
        address user;
        uint256 nftId;
    }
    
    address private _contractAddress;
    mapping (uint256 => uint256) private _firstInvitors;  //一级邀请
    mapping (uint256 => uint256) private _secInvitors;    //二级邀请
    //mapping (address => uint256) private _reword;         //奖励
    mapping (uint256 => UserInfo[]) public _userFirst;  //用户的直推列表
    mapping (uint256 => UserInfo[]) public _userSec;    //用户的间推列表
    
    function setContract(address newAddress) public onlyOwner {
        _contractAddress = newAddress;
    }
    
    function addUserFirstItem(uint256 invitorId, address user, uint256 nftId) public returns (bool) {
        require(msg.sender == _contractAddress, "only owner can use");
        _userFirst[invitorId].push(UserInfo({
            time: block.timestamp,
            user: user,
            nftId: nftId
        }));
        return true;
    }
    
    function addUserSecItem(uint256 firstInvitor, address user, uint256 nftId) public returns (bool) {
        require(msg.sender == _contractAddress, "only owner can use");
        _userSec[firstInvitor].push(UserInfo(block.timestamp, user, nftId));
        return true;
    }
    
    function setFirstInvitor(uint256 nftId, uint256 invitorId) public returns(bool) {
        require(msg.sender == _contractAddress, "only owner can use");
        _firstInvitors[nftId] = invitorId;
        return true;
    }
    
    function setSecInvitor(uint256 nftId, uint256 invitorId) public returns(bool) {
        require(msg.sender == _contractAddress, "only owner can use");
        _secInvitors[nftId] = invitorId;
        return true;
    }
    
    function getFirstInvitor(uint256 nftId) public view returns(uint256) {
        return _firstInvitors[nftId];
    }
    
    function getSecInvitor(uint256 nftId) public view returns(uint256){
        return _secInvitors[nftId];
    }
    
    function userFirstList(uint256 nftId) public view returns(UserInfo[] memory) {
        return _userFirst[nftId];
    }

    function userSecondList(uint256 nftId) public view returns(UserInfo[] memory) {
        return _userSec[nftId];
    }
    
    function nftInvitor(uint256 nftId) public view returns(uint256) {
        return _firstInvitors[nftId];
    }
}