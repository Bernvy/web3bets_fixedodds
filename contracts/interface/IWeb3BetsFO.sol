// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWeb3BetsFO{

    function factory() external view returns(address);

    function ecosystemAddress() external view returns(address);

    function holdersAddress() external view returns(address);

    function stableCoin() external view returns(address);

    function holdersVig() external view returns(uint);

    function ecosystemVig() external view returns(uint);

    function eventOwnersVig() external view returns(uint);

    function vigPercentage() external returns(uint);

    function shareBetEarnings(address eventOwner, uint256 _vigAmount) external;

    function isSystemAdmin(address _account) external returns (bool);

    function isEventAdmin(address _account) external returns (bool);

    function isBlack(address _account) external returns (bool);
}