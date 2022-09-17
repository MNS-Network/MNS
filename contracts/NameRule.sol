//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Strings.sol";

interface IRule {
    function validateName(string memory str) external view returns (bool);
    function toLower(string memory str) external view returns (string memory);
}

contract NameRule {
    using SafeMath for uint256;
    using Strings for uint256;
    
    function validateName(string memory str) public view returns (bool){
        bytes memory b = bytes(str);
       // if(b.length < _nftMinLength[coinType]) return false;
        //if(b.length > _nftMaxLength[coinType]) return false; // Cannot be longer than 25 characters
        if (b.length > 21) return false;
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space
        if(b[0] == 0x2d) return false; // Leading space
        if (b[b.length - 1] == 0x2d) return false; // Trailing space

        bytes1 lastChar = b[0];

        if (3 == b.length) {
            for(uint i; i<b.length; i++){
                bytes1 char = b[i];
                if(
                    !(char >= 0x30 && char <= 0x39) && //9-0
                    !(char >= 0x41 && char <= 0x5A) && //A-Z
                    !(char >= 0x61 && char <= 0x7A) //a-z
                )
                return false;
            }
        }else {
            for(uint i; i<b.length; i++){
                bytes1 char = b[i];
                //if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces
                if (char == 0x2d && lastChar == 0x2d) return false;
                if(
                    !(char >= 0x30 && char <= 0x39) && //9-0
                    !(char >= 0x41 && char <= 0x5A) && //A-Z
                    !(char >= 0x61 && char <= 0x7A) && //a-z
                    //!(char == 0x20) && //space
                    !(char == 0x2d)    //-号
                )
                return false;

                lastChar = char;
            }
        }
        
        return true;
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
}