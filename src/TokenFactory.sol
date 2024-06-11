// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardToken.sol";

contract TokenFactory {
    event TokenCreated(address indexed projectOwner, address indexed tokenContract);

    function createToken(string memory _tokenName, string memory _tokenTicker, uint256 _tokensToMint, address _owner)
        external
        returns (address)
    {
        RewardToken newToken = new RewardToken(_tokenName, _tokenTicker, _tokensToMint, _owner);
        emit TokenCreated(msg.sender, address(newToken));
        return address(newToken);
    }
}
