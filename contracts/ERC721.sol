//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "hardhat/console.sol";

contract ERC721 is IERC721, IERC721Metadata {
    using Strings for uint;

    string private _name;
    string private _symbol;

    //how many tokens are on the balance of a certain address
    mapping(address => uint) private _balances;
    //who owns what
    mapping(uint => address) private _owners;
    //permission to dispose of a specific token
    mapping(uint => address) private _tokenApprovals;
    //can the operator manage tokens of a specific owner
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    

    //is there a token in circulation?
    modifier _requireMinted(uint tokenId) {
        require(_exists(tokenId), "not minted!");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function transferFrom(address from, address to, uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved or owner!");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");
        _safeTransfer(from, to, tokenId, "");
    }

    //safeTransferFrom with data
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");
        _safeTransfer(from, to, tokenId, data);
    }

    //get name
    function name() external view returns(string memory) {
        return _name;
    }

    //get symbol
    function symbol() external view returns(string memory) {
        return _symbol;
    }

    //return address balance
    function balanceOf(address owner) public view returns(uint) {
        require(owner != address(0), "owner cannot be zero");

        return _balances[owner];
    }

    //return token owner
    function ownerOf(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _owners[tokenId];
    }

    //give permission to order
    function approve(address to, uint tokenId) public {
        address _owner = ownerOf(tokenId);

        require(
            _owner == msg.sender || isApprovedForAll(_owner, msg.sender),
            "not an owner!"
        );

        require(to != _owner, "cannot approve to self");

        _tokenApprovals[tokenId] = to;

        emit Approval(_owner, to, tokenId);
    }

    //setting permission to dispose
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "cannot approve to self");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //get the address of someone who can manage the token
    function getApproved(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _tokenApprovals[tokenId];
    }

    //can the operator use the owner's tokens
    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    function _baseURI() internal pure virtual returns(string memory) {
        return "";
    }

    //returns information where the token can be found
    function tokenURI(uint tokenId) public view virtual _requireMinted(tokenId) returns(string memory) {

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(baseURI, tokenId.toString())) :
            "";
    }

    //check whether such a token exists
    function _exists(uint tokenId) internal view returns(bool) {
        return _owners[tokenId] != address(0);
    }

    //can the operator dispose of tokens
    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns(bool) {
        address owner = ownerOf(tokenId);

        return(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }


    //implementation of safe transfer
    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);

        //checking whether the contract is the recipient
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "transfer to non-erc721 receiver"
        );
    }

    //checking whether the contract is the recipient
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) private returns(bool) {
        //check it is a smart contract
        if(to.code.length > 0) {
            //check if the contract has a receiving function
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval) {
                //Is the value returned by the function correct?
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason) {
                //revert with mistake
                if(reason.length == 0) {
                    revert("Transfer to non-erc721 receiver");
                } else {
                    //get an error
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _transfer(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "incorrect owner!");
        require(to != address(0), "to address is zero!");

        //additional operation before transfer
        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        //additional operation after transfer
        _afterTokenTransfer(from, to, tokenId);
    }

    //additional operation before translation, which can be overridden in descendants
    function _beforeTokenTransfer(
        address from, address to, uint tokenId
    ) internal virtual {}

    //additional operation after translation, which can be overridden in descendants
    function _afterTokenTransfer(
        address from, address to, uint tokenId
    ) internal virtual {}

    //safeMint
    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    //safeMintWithData
    function _safeMint(address to, uint tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);

        require(_checkOnERC721Received(address(0), to, tokenId, data), "non-erc721 receiver");
    }

    function _mint(address to, uint tokenId) internal virtual {
        //checking that the address is non-null, otherwise it would be burn
        require(to != address(0), "zero address to");
        //checking that the token does not exist
        require(!_exists(tokenId), "this token id is already minted");

        //additional operation before transfer
        _beforeTokenTransfer(address(0), to, tokenId);

        _owners[tokenId] = to;
        _balances[to]++;

        emit Transfer(address(0), to, tokenId);

        //additional operation after transfer
        _afterTokenTransfer(address(0), to, tokenId);
    }

} 