// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    address public owner;

    constructor(string memory _name, string memory _symbol, uint256 _initalAmount, address _owner)
        ERC20(_name, _symbol)
    {
        _mint(_owner, _initalAmount);
        owner = _owner;
    }
}
