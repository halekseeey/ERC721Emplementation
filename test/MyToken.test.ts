import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import type { MyContract } from "../typechain-types";

describe("MyToken", function () {
  const MAX_SUPPLY = 1000;
  const MAX_MINT_PER_TX = 3;
  const TOKEN_PRICE = 2;
  const SET_PRICE = 6;
  const BASE_URI = "ipfs://halekseeey/tokens/";

  async function deployMyToken() {
    const [owner, user] = await ethers.getSigners();

    const MyContract = await ethers.getContractFactory("MyContract");
    const myContract: MyContract = await MyContract.deploy(
      MAX_SUPPLY,
      MAX_MINT_PER_TX,
      TOKEN_PRICE,
      SET_PRICE
    );

    return { myContract, owner, user };
  }

  describe("Deployment", async function () {
    it("Deployment success with correct args", async function () {
      const { myContract } = await loadFixture(deployMyToken);
      expect(await myContract.MAX_SUPPLY()).to.eq(MAX_SUPPLY);
      expect(await myContract.MAX_MINT_PER_TX()).to.eq(MAX_MINT_PER_TX);
      expect(await myContract.TOKEN_PRICE()).to.eq(TOKEN_PRICE);
      expect(await myContract.SET_PRICE()).to.eq(SET_PRICE);
    });
    it("Deployment faild with null max sypply", async function () {
      const MyContract = await ethers.getContractFactory("MyContract");
      await expect(
        MyContract.deploy(0, MAX_MINT_PER_TX, TOKEN_PRICE, SET_PRICE)
      ).revertedWith("The number of tokens must be greater than zero");
    });
  });

  describe("Mint", function () {
    it("Should mint by user", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract
        .connect(user)
        .mint(MAX_MINT_PER_TX, { value: TOKEN_PRICE * MAX_MINT_PER_TX });
      expect(await myContract.ownerOf(1)).to.eq(user);
    });
    it("Should mint certain number of tokens", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract
        .connect(user)
        .mint(MAX_MINT_PER_TX, { value: TOKEN_PRICE * MAX_MINT_PER_TX });
      expect(await myContract.currentTokenId()).to.eq(MAX_MINT_PER_TX);
    });
    it("The user's balance should increase", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      const oldBalance = await myContract.balanceOf(user);
      await myContract
        .connect(user)
        .mint(MAX_MINT_PER_TX, { value: TOKEN_PRICE * MAX_MINT_PER_TX });

      expect(await myContract.balanceOf(user)).to.eq(
        BigInt(MAX_MINT_PER_TX) + oldBalance
      );
    });
    it("attempt to mint more than the mint limit", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      const amount = MAX_MINT_PER_TX + 1;
      await expect(
        myContract.connect(user).mint(amount, {
          value: TOKEN_PRICE * amount,
        })
      ).to.be.revertedWith("Exceeds maximum tokens per transaction");
    });
    it("attempt to sent less money", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await expect(
        myContract.connect(user).mint(MAX_MINT_PER_TX, {
          value: 0,
        })
      ).to.be.revertedWith("Ether value sent is not correct");
    });
    it("attempt to mint more then the max supply", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      for (let i = 0; i < MAX_SUPPLY; i++) {
        await myContract.connect(user).mint(1, {
          value: TOKEN_PRICE,
        });
      }
      await expect(
        myContract.connect(user).mint(1, {
          value: TOKEN_PRICE,
        })
      ).to.be.revertedWith("Exceeds maximum supply of tokens");
    });
  });

  describe("mintSet", function () {
    const setSize = 6;
    it("Should mint by user", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract.connect(user).mintSet({ value: SET_PRICE });
      expect(await myContract.ownerOf(setSize)).to.eq(user);
    });
    it("Should mint certain number of tokens", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract.connect(user).mintSet({ value: SET_PRICE });
      expect(await myContract.currentTokenId()).to.eq(setSize);
    });
    it("The user's balance should increase", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      const oldBalance = await myContract.balanceOf(user);
      await myContract.connect(user).mintSet({ value: SET_PRICE });
      expect(await myContract.balanceOf(user)).to.eq(
        BigInt(setSize) + oldBalance
      );
    });
    it("Emit MintSet", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await expect(myContract.connect(user).mintSet({ value: SET_PRICE }))
        .to.emit(myContract, "MintSet")
        .withArgs(user, [1, 2, 3, 4, 5, 6]);
    });
    it("Attempt to sent incorrect number of money", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await expect(myContract.connect(user).mintSet({ value: 0 })).revertedWith(
        "Incorrect value for minting set"
      );
    });
    it("Attempt to mint second set ", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract.connect(user).mintSet({ value: SET_PRICE });
      await expect(
        myContract.connect(user).mintSet({ value: SET_PRICE })
      ).revertedWith("Address has already minted a set");
    });
    it("attempt to mint more then the max supply", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      for (let i = 0; i < MAX_SUPPLY; i++) {
        await myContract.connect(user).mint(1, { value: TOKEN_PRICE });
      }
      await expect(
        myContract.connect(user).mintSet({ value: SET_PRICE })
      ).to.be.revertedWith("Exceeds maximum supply of tokens");
    });
  });

  describe("signedMint", function () {
    const signature = "PASSWORD";
    it("Should mint by user", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract
        .connect(user)
        .signedMint(ethers.encodeBytes32String(signature));
      expect(await myContract.ownerOf(1)).to.eq(user);
    });
    it("Should mint certain number of tokens", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract
        .connect(user)
        .signedMint(ethers.encodeBytes32String(signature));
      expect(await myContract.currentTokenId()).to.eq(1);
    });
    it("The user's balance should increase", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      const oldBalance = await myContract.balanceOf(user);
      await myContract
        .connect(user)
        .signedMint(ethers.encodeBytes32String(signature));

      expect(await myContract.balanceOf(user)).to.eq(BigInt(1) + oldBalance);
    });

    it("attempt to mint with the same signature", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);

      await myContract
        .connect(user)
        .signedMint(ethers.encodeBytes32String(signature));

      await expect(
        myContract
          .connect(user)
          .signedMint(ethers.encodeBytes32String(signature))
      ).to.be.revertedWith("Signature already used");
    });

    it("attempt to mint more then the max supply", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      for (let i = 0; i < MAX_SUPPLY; i++) {
        await myContract
          .connect(user)
          .signedMint(ethers.encodeBytes32String(signature + i));
      }
      await expect(
        myContract
          .connect(user)
          .signedMint(ethers.encodeBytes32String(signature))
      ).to.be.revertedWith("Max supply reached");
    });
  });

  describe("tokenURI", function () {
    it("Return uri", async function () {
      const { myContract, user } = await loadFixture(deployMyToken);
      await myContract.mint(1, { value: TOKEN_PRICE });
      expect(await myContract.connect(user).tokenURI(1)).to.eq(BASE_URI + 1);
    });
  });
});
