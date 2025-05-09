// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {TransientDeployer} from "src/L10-Upgradability/TransientDeployer.sol";
import {VotingToken} from "src/L10-Upgradability/VotingToken.sol";
import {VotingLogicV1} from "src/L10-Upgradability/VotingLogicV1.sol";
import {VotingLogicV2} from "src/L10-Upgradability/VotingLogicV2.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract TransientDeployerTest is Test {
    error CouldNotTransferEther();
    error ProxyAlreadyDeployed();

    TransientDeployer sut;
    VotingToken tokenContract;
    VotingLogicV1 logicContractV1;
    ProxyAdmin proxyAdmin;

    address public tokenDeployer =
        vm.addr(
            0x1234567890123456789012345678901234567890123456789012345678901234
        );
    address public proxyAdminAddress =
        vm.addr(
            0x1234567890123456789012345678901234567890123456789012345678901239
        );
    address public logicOwner =
        vm.addr(
            0x1234567890123456789012345678901234567890123456789012345678901236
        );

    function setUp() public {
        vm.startPrank(tokenDeployer);
        tokenContract = new VotingToken();

        logicContractV1 = new VotingLogicV1();
        proxyAdmin = new ProxyAdmin(proxyAdminAddress);

        sut = new TransientDeployer();
    }

    function testDeployProxy() public {
        console.log("This: ", address(this));
        address proxy = sut.deployProxy(
            address(tokenContract),
            address(proxyAdmin),
            logicOwner,
            address(logicContractV1)
        );

        VotingLogicV1 logicProxy = VotingLogicV1(proxy);

        assertEq(logicProxy.owner(), logicOwner);
        assertEq(address(logicProxy.votingToken()), address(tokenContract));

        assertEq(sut.owner(), address(0));
        assertNotEq(address(proxy), address(0));
    }
}
