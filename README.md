# Source of Randomness

Today we would learn how using `blockhash` and `block.timestamp` is a false source of randomness

## Requirements

- We would build a game where there is a pack of cards.
- Each card has a number associated with it which ranges from `0 to 2²⁵⁶–1`
- There is a dealer who would at random pick up a card from the pack.
- If someone correctly guesses the number, they win `0.1 ETH`
- We would hack this game today :)

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

- Lets first understand what `abi.encodedPacked` does, For that please do ahead and read this [article](https://medium.com/@libertylocked/what-are-abi-encoding-functions-in-solidity-0-4-24-c1a90b5ddce8)

-
