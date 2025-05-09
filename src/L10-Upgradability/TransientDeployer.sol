// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {VotingLogicV1} from "./VotingLogicV1.sol";

contract TransientDeployer is Ownable {
    error CouldNotTransferEther();
    error ProxyAlreadyDeployed();

    bool public hasDeployed = false;

    constructor() Ownable(msg.sender) {}

    function deployProxy(
        address tokenContract,
        address proxyAdmin,
        address logicOwner,
        address logicContract
    ) external onlyOwner returns (address) {
        bytes memory data = abi.encodeWithSelector(
            VotingLogicV1.initialize.selector,
            logicOwner,
            tokenContract
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            logicContract,
            proxyAdmin,
            data
        );

        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = address(logicOwner).call{value: balance}("");
            require(success, CouldNotTransferEther());
        }

        renounceOwnership();
        return address(proxy);
    }
}
