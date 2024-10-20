// contracts/FunToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Polygon is ERC20 {

    // Define the supply of FunToken: 1,000,000 
    uint256 constant initialSupply = 1000000 * (10**18);
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // Constructor will be called on contract creation
    constructor() ERC20("POL", "POL") {
        _mint(msg.sender, initialSupply);
    }
}