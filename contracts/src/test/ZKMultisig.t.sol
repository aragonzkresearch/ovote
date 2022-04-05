// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "src/ZKMultisig.sol";

interface CheatCodes {
    function roll(uint256) external;
    function expectRevert(bytes calldata) external;
}

contract ZKMultisigTest is DSTest {
    ZKMultisig zkmultisig;

    function setUp() public {
        zkmultisig = new ZKMultisig();
    }

    function testNewProcess() public {
        // create a 1st process
        uint256 id = zkmultisig.newProcess(2222, 1111, 1000, 1000, 100, 10, 60);
        assertEq(id, 1);

        { // scope for process 1, avoids stack too deep errors
        // get the process with id=1
        (address _creator, uint256 _transactionHash, uint256 _censusRoot,
         uint64 _censusSize, uint64 _ethEndBlockNum, uint64
         _resultsPublishingWindow, uint8 _minParticipation, uint8
         _minPositiveVotes, bool _closed) = zkmultisig.processes(1);

        assertEq(_creator, 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84); // address of creator
        assertEq(_transactionHash, 2222);
        assertEq(_censusRoot, 1111);
        assertEq(_censusSize, 1000);
        assertEq(_ethEndBlockNum, 1000);
        assertEq(_resultsPublishingWindow, 100);
        assertEq(_minParticipation, 10);
        assertEq(_minPositiveVotes, 60);
        assertTrue(!_closed);
        }


        // create a 2nd process with the exact same parameters
        id = zkmultisig.newProcess(2222, 1111, 1000, 1000, 100, 10, 60);
        assertEq(id, 2);
        // get the process with id=2
        { // scope for process 2, avoids stack too deep errors
        (address _creator, uint256 _transactionHash, uint256 _censusRoot,
         uint64 _censusSize, uint64 _ethEndBlockNum, uint64
         _resultsPublishingWindow, uint8 _minParticipation, uint8
         _minPositiveVotes, bool _closed) = zkmultisig.processes(2);

        assertEq(_creator, 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        assertEq(_transactionHash, 2222);
        assertEq(_censusRoot, 1111);
        assertEq(_censusSize, 1000);
        assertEq(_ethEndBlockNum, 1000);
        assertEq(_resultsPublishingWindow, 100);
        assertEq(_minParticipation, 10);
        assertEq(_minPositiveVotes, 60);
        assertTrue(!_closed);
        }
    }

    function testPublishResult() public {
        CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

        // create a 1st process
        uint256 id = zkmultisig.newProcess(2222, 1111, 1000, 1000, 100, 10, 60);

        cheats.roll(1000);

        // publish result
        zkmultisig.publishResult(id, 204, 250);
        // publish another result containing more votes
        zkmultisig.publishResult(id, 204, 300);

        // expect revert when trying to publish a result with same amount of
        // votes than the last accepted one
        cheats.expectRevert(bytes("nVotes > results[id].nVotes"));
        zkmultisig.publishResult(id, 204, 300);

        // expect revert when trying to publish a result with more votes than
        // censusSize
        cheats.expectRevert(bytes("nVotes <= processes[id].censusSize"));
        zkmultisig.publishResult(id, 204, 1001);

        // expect revert when trying to publish a result for a process that does not exist
        cheats.expectRevert(bytes("process id does not exist"));
        zkmultisig.publishResult(2, 204, 300);
    }

    function testCloseProcess() public {
        CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

        // create a 1st process
        uint256 id = zkmultisig.newProcess(2222, 1111, 1000, 1000, 100, 10, 60);
        assertEq(id, 1);

        // publish result
        cheats.roll(1000);
        zkmultisig.publishResult(id, 204, 300);

        // try to close process, but expect revert
        cheats.roll(1099);
        cheats.expectRevert(bytes("process.resPubStartBlock not reached yet"));
        zkmultisig.closeProcess(1);

        (,,,,,,,, bool _closed) = zkmultisig.processes(1);
        assertTrue(!_closed);

        // close process
        cheats.roll(1100);
        zkmultisig.closeProcess(1);

        (,,,,,,,, _closed) = zkmultisig.processes(1);
        assertTrue(_closed);
    }
}
