// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract DEX is ERC20 {
    address token;

    constructor(address tokenAddr) ERC20("LP Token", "LPTKN") {
        token = tokenAddr;
    }

    error Incorrect_Ratio_Of_Tokens_Provided();
    error Number_Of_LpTokens_Must_Be_Greater_Than_Zero();

    function addLiquidity(uint256 tokenAmount) external payable {
        if (getTokenReserve() == 0) {
            ERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
            _mint(msg.sender, address(this).balance); //lpToken
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getTokenReserve();
            uint256 reqTokenAmount = (tokenReserve * msg.value) / ethReserve;

            if (tokenAmount < reqTokenAmount)
                revert Incorrect_Ratio_Of_Tokens_Provided();

            ERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
            _mint(msg.sender, (totalSupply() * msg.value) / ethReserve); //lpToken
        }
    }

    function removeLiquidity(uint256 numLpTokens) external payable {
        if (numLpTokens == 0)
            revert Number_Of_LpTokens_Must_Be_Greater_Than_Zero();

        uint256 ethToReturn = (numLpTokens * address(this).balance) /
            totalSupply();
        uint256 tokenToReturn = (getTokenReserve() * ethToReturn) /
            address(this).balance;

        _burn(msg.sender, numLpTokens);
        ERC20(token).transferFrom(address(this), msg.sender, tokenToReturn);
        payable(msg.sender).transfer(ethToReturn);
    }

    function getOutputFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        return
            (inputAmount * outputReserve * 99) /
            (inputAmount * 99 + inputReserve * 100);
    }

    function getTokenFromEth() external payable returns (uint256) {
        uint256 numTokens = getOutputFromSwap(
            msg.value,
            address(this).balance - msg.value,
            getTokenReserve()
        );
        ERC20(token).transferFrom(address(this), msg.sender, numTokens);

        return numTokens;
    }

    function getEthFromToken(uint256 numTokens) external returns (uint256) {
        uint256 ethAmount = getOutputFromSwap(
            numTokens,
            getTokenReserve(),
            address(this).balance
        );
        ERC20(token).transferFrom(msg.sender, address(this), numTokens);
        payable(msg.sender).transfer(ethAmount);

        return ethAmount;
    }

    function getTokenReserve() public view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }
}
