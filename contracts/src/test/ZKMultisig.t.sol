// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "src/ZKMultisig.sol";

contract ZKMultisigTest is DSTest {
    ZKMultisig zkmultisig;

    function setUp() public {
        zkmultisig = new ZKMultisig();
    }

    function testNewProcess() public {
        uint256 censusRoot = 1111;
        uint64 censusSize = 1000;
        uint64 ethEndBlockNum = 1000;
        uint64 resultsPublishingWindow = 100;
        uint8 minParticipation = 10;
        uint8 minPositiveVotes = 60;

        // create a 1st process with the parameters
        zkmultisig.newProcess(censusRoot, censusSize, ethEndBlockNum,
                              resultsPublishingWindow, minParticipation,
                              minPositiveVotes);

        // get the process with id=1
        (address _creator, uint256 _censusRoot, uint64 _censusSize,
         uint64 _ethEndBlockNum, uint64 _resultsPublishingWindow, uint8
         _minParticipation, uint8 _minPositiveVotes, bool closed) = zkmultisig.processes(1);

         // address expectedCreator = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
        assertEq(_creator, 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        assertEq(_censusRoot, censusRoot);
        assertEq(_censusSize, censusSize);
        assertEq(_ethEndBlockNum, ethEndBlockNum);
        assertEq(_resultsPublishingWindow, resultsPublishingWindow);
        assertEq(_minParticipation, minParticipation);
        assertEq(_minPositiveVotes, minPositiveVotes);


        // create a 2nd process with the exact same parameters
        zkmultisig.newProcess(censusRoot, censusSize, ethEndBlockNum,
                              resultsPublishingWindow, minParticipation,
                              minPositiveVotes);
        // get the process with id=2
        (_creator, _censusRoot, _censusSize, _ethEndBlockNum,
         _resultsPublishingWindow, _minParticipation, _minPositiveVotes, closed) =
             zkmultisig.processes(2);

        assertEq(_creator, 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        assertEq(_censusRoot, censusRoot);
        assertEq(_censusSize, censusSize);
        assertEq(_ethEndBlockNum, ethEndBlockNum);
        assertEq(_resultsPublishingWindow, resultsPublishingWindow);
        assertEq(_minParticipation, minParticipation);
        assertEq(_minPositiveVotes, minPositiveVotes);
    }
}
