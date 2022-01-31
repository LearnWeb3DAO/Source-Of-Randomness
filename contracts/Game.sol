// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Game {
    constructor() payable {}
    /**
        Randomly picks a number out of `0 to 2²⁵⁶–1`.
        `abi.encodePacked` takes in the two params - blockhash and block.timestamp 
    */
    function pickACard() private view returns(uint) {
        uint pickedCard = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)));
        return pickedCard;
    }

    function guess(uint _guess) public {
        uint _pickedCard = pickACard();
        if(_guess == _pickedCard){
            (bool sent,) = msg.sender.call{value: 0.1 ether}("");
            require(sent, "Failed to send ether");
        }
    }

      function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}