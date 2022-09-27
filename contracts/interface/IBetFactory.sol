// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IBetFactory {

    event BetCreated(address better, address marketAddress, uint stake, uint8 odds, string marketSide);

    function placeBet(address _marketAddress, string memory _marketSide, uint256 _stake, uint8 _odds) external returns(address);


}