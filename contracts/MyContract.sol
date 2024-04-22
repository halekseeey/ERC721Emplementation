//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract MyContract is ERC721 {
    uint public currentTokenId;
    //who can sign transactions
    address private owner;

    //nonce is already used
    mapping(address => mapping(uint => bool)) nonces;

    // Maximum number of tokens
    uint256 public immutable MAX_SUPPLY;
    // Maximum number of tokens per transaction
    uint256 public immutable MAX_MINT_PER_TX ; 
    // Price per token
    uint256 public immutable TOKEN_PRICE; 
    // Mining price for a set of six tokens
    uint256 public immutable SET_PRICE; 
    // Tracking signatures used
    mapping(bytes => bool) public usedSignatures; 
    // Tracking who has already minted a set
    mapping(address => bool) public hasMintedSet; 

    event MintSet(address indexed owner, uint256[] tokenIds);

    //mint function
    function mint(uint256 numberOfTokens) public payable {
        require(numberOfTokens <= MAX_MINT_PER_TX, "Exceeds maximum tokens per transaction");
        require(msg.value == TOKEN_PRICE * numberOfTokens, "Ether value sent is not correct");
        require(currentTokenId + numberOfTokens <= MAX_SUPPLY, "Exceeds maximum supply of tokens");

        //mint each token one by one
        for (uint256 i = 0; i < numberOfTokens; i++) {
            currentTokenId++;
            _safeMint(msg.sender, currentTokenId);
        }
    }

    function signedMint(uint256 numberOfTokens, uint nonce, bytes memory signature) public {
        require(numberOfTokens <= MAX_MINT_PER_TX, "Exceeds maximum tokens per transaction");
        require(!usedSignatures[signature], "Signature already used");
        require(!nonces[msg.sender][nonce], "Nonce already used");
        require(currentTokenId + numberOfTokens <= MAX_SUPPLY, "Exceeds maximum supply of tokens");

        //form a message
        bytes32 message = withPrefix(keccak256(abi.encodePacked(
            msg.sender,
            numberOfTokens,
            nonce,
            address(this)
        )));

        //check that the message is signed by the owner
        require(
            recoverSigner(message, signature) == owner, "Invalid signature!"
        );
    
        //record that this signature is used
        usedSignatures[signature] = true;
        //record that this nonce is used
        nonces[msg.sender][nonce] = true;

        //mint each token one by one
        for (uint256 i = 0; i < numberOfTokens; i++) {
            currentTokenId++;
            _safeMint(msg.sender, currentTokenId);
        }
    }

    function mintSet() public payable {
        require(msg.value == SET_PRICE, "Incorrect value for minting set");
        require(!hasMintedSet[msg.sender], "Address has already minted a set");
        require(currentTokenId + 6 <= MAX_SUPPLY, "Exceeds maximum supply of tokens");

        //an array to pass it to the event
        uint256[] memory tokenIds = new uint256[](6);

        //mint each token one by one
        for (uint i = 0; i < 6; i++) {
            currentTokenId++;
            _safeMint(msg.sender, currentTokenId);
            tokenIds[i] = currentTokenId;
        }

        //save information that this user minted a set of tokens
        hasMintedSet[msg.sender] = true;
        emit MintSet(msg.sender, tokenIds);
    }

    constructor(uint _MAX_SUPPLY, uint _MAX_MINT_PER_TX, uint _TOKEN_PRICE, uint _SET_PRICE) ERC721("MyToken", "HALEKSEEEY") {
        require(_MAX_SUPPLY > 0, "The number of tokens must be greater than zero");
        MAX_SUPPLY = _MAX_SUPPLY;
        MAX_MINT_PER_TX = _MAX_MINT_PER_TX;
        TOKEN_PRICE = _TOKEN_PRICE;
        SET_PRICE = _SET_PRICE;
        owner = msg.sender;
    }

    function _baseURI() internal pure override returns(string memory) {
        return "ipfs://halekseeey/tokens/";
    }

    function recoverSigner(bytes32 message, bytes memory signature) private pure returns(address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory signature) private pure returns(uint8 v, bytes32 r, bytes32 s) {
        //checking the correctness of the transmitted data
        require(signature.length == 65, 'Incorrect signature length');

        assembly {
            r := mload(add(signature, 32))

            s := mload(add(signature, 64))

            v := byte(0, mload(add(signature, 96)))
        }

        return(v, r, s);
    }

    function withPrefix(bytes32 _hash) private pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _hash
            )
        );
    }
}