// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {console2} from "forge-std/Test.sol";
import {MundialHookTest} from "./MundialHook.t.sol";
import {MundialHook} from "../src/MundialHook.sol";

/// @notice Narrated end-to-end tournament, for demos and the video walkthrough:
///   forge test --match-contract MundialDemo -vv
contract MundialDemo is MundialHookTest {
    function test_demo_fullTournamentNarrative() public {
        console2.log(unicode"=== MUNDIAL: the pool that plays the World Cup ===");
        console2.log("");

        // --- Fans pledge -------------------------------------------------
        vm.prank(fanARG);
        hook.joinTeam(0);
        vm.prank(fanFRA);
        hook.joinTeam(1);
        vm.prank(fanBRA);
        hook.joinTeam(2);
        console2.log(unicode"Fans pledged: Argentina, France, Brazil supporters are in.");

        // --- QF1: Argentina vs France ------------------------------------
        _warpToMatch(0);
        console2.log("");
        console2.log(unicode"QF1 kickoff: Argentina vs France. Every swap is a shot.");
        _swap(fanARG, true, 1e18); // ARG: 1 goal (threshold 0.5)
        _swap(fanFRA, true, 2e18); // FRA: comes back with 3 goals total volume
        _swap(fanARG, true, 1.6e18); // ARG answers
        console2.log("  Argentina goals:", hook.goalsOf(0, true));
        console2.log("  France    goals:", hook.goalsOf(0, false));

        _warpToExtraTime(0);
        hook.poke();
        MundialHook.Match memory m0 = hook.getMatch(0);
        console2.log(unicode"  Full time. Winner (seed):", m0.winner);

        // --- QF2: Brazil vs England, decided by a GOLDEN GOAL -------------
        console2.log("");
        console2.log(unicode"QF2: Brazil vs England. 0-0 after regulation...");
        _warpToExtraTime(1);
        console2.log(unicode"  Sudden death! Brazil fan swaps... GOLDEN GOAL.");
        _swap(fanBRA, true, 1e18); // settles the match in this same transaction
        console2.log("  QF2 settled:", hook.getMatch(1).settled);
        console2.log("  Winner (seed):", hook.getMatch(1).winner);

        // --- Rest of the bracket ------------------------------------------
        console2.log("");
        console2.log(unicode"Semis & final play out on the same swap-driven rules...");
        _warpPastSlot(6);
        hook.poke(); // remaining matches settle deterministically
        console2.log("  Champion (seed index):", hook.champion());
        console2.log("  Champions Pot (currency1):", hook.pot1());

        // --- Claims --------------------------------------------------------
        console2.log("");
        uint8 champ = hook.champion();
        address winnerFan = champ == 0 ? fanARG : champ == 1 ? fanFRA : fanBRA;
        vm.prank(winnerFan);
        hook.claim();
        console2.log(unicode"Champion fan claimed their pro-rata share of the pot.");
        console2.log(unicode"No owner. No oracle. No randomness. Just football, on-chain.");
    }
}
