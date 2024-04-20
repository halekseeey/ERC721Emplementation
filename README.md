# ERC721 Emplementation

This project implemented the MyContract contract, which supports the ERC721 standard. The contract also implemented three minting functions:
mint - payble, accepts the number of tokens that need to be minted
signedMint - accepts a unique signature and sends one token to the user
setMint - mint for user once a set of 6 tokens

All contracts can be seen in the directory /contracts

To compile the contract, enter

```shell
npx hardhat сompile
```

MyContract is covered in tests, which can be viewed at /test/MyContract.test.ts

To test the contract, enter

```shell
npx hardhat test
```

To view coverage, enter

```shell
npx hardhat coverage
```

then find the file MyContract.sol.html in the folder coverage/contracts and open in a browser
