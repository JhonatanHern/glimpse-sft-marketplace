//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace1155 is ERC1155 {
    mapping(uint => string) public fileHash;// ipfs hash
    mapping(uint => mapping(address => uint)) public tokenPrice;// price for every token on sale by every user. token => (user => price)
    mapping(string => bool) hashExists;
    uint private counter;// first token is zero
    IERC20 private paymentToken;

    constructor(address token) ERC1155("https://app.glimpse.io/meta/${id}.json") {
        paymentToken = IERC20(token);
    }

    function mint(string calldata _videoHash, uint _amount, uint price) external returns(uint) {
        require(!hashExists[_videoHash], "file already registered");
        fileHash[counter] = _videoHash;
        hashExists[_videoHash] = true;
        tokenPrice[counter][msg.sender] = price;
        _mint(msg.sender, counter, _amount, "");
        counter++;
        return counter - 1;
    }

    function buy(uint tokenId, uint amount, address owner) external {
        // calculate price to pay
        uint price = amount * tokenPrice[tokenId][owner];
        // require that the token has a price (>0) and the amount is larger than zero
        require(price > 0);
        // transfer ERC20 from buyer to owner (assuming previous transfer authorization from buyer)
        bool transferSuccess = paymentToken.transferFrom(msg.sender, owner, price);
        require(transferSuccess, "Something happened with the payment. Check your balance.");
        // transfer token
        _safeTransferFrom(
            owner,
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    function changePrice(uint tokenId, uint newPrice) public {
        tokenPrice[tokenId][msg.sender] = newPrice;
    }
}
