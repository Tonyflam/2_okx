# Mundial — Judge Guide

The fastest honest path to evaluating this project. Everything below is verifiable from public sources; status labels are current as of 2026-07-17.

## 30-second read

Mundial makes one Uniswap v4 pool play a complete eight-team knockout World Cup with **no admin, no oracle, no randomness**. Traders pledge a team once; while that team's match is live their swaps are shots and volume converts to goals. Golden goals settle inside the very swap that scored them. A 0.20% skim on fan swaps builds a Champions Pot claimed pro-rata by champion fans; leftovers are donated to LPs. The whole tournament state machine lives in hook storage on X Layer mainnet.

- **Hook**: [`0x51f3d18a574c1deec5c04d395573cda9248dd0c4`](https://www.oklink.com/x-layer/address/0x51f3d18a574c1deec5c04d395573cda9248dd0c4) (chain 196)
- **Token**: [`0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f`](https://www.oklink.com/x-layer/address/0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f)
- **Pool ID**: `0x0cc28818a207ae3c182a88dbe9677203859f916116711a19c9b010bf390bbeda`
- **Demo video**: https://youtu.be/Jk3e9K3U0bg
- **Hooklist**: [listed in Uniswap/hooklist](https://github.com/Uniswap/hooklist/blob/main/hooks/xlayer/0x51f3d18a574c1deec5c04d395573cda9248dd0c4.json) (merged 2026-07-16 via [#1103](https://github.com/Uniswap/hooklist/pull/1103); submitted as [#1062](https://github.com/Uniswap/hooklist/pull/1062))

## Evidence by judging dimension

| Judging dimension | Mundial evidence | Exact proof |
|---|---|---|
| **Code quality** | Implements `IHooks` directly with 4 meaningful callbacks; immutable parameters, zero admin surface; bounded loops (`_sync` ≤ 7 matches); CEI + flag-before-transfer on value paths; 77 passing tests incl. 3 fuzz properties (goal math, claim conservation, tournament termination) | [src/MundialHook.sol](../src/MundialHook.sol) · [test/MundialHook.t.sol](../test/MundialHook.t.sol) · `forge test` |
| **World Cup creativity** | The theme is the mechanism, not the skin: 8-team knockout bracket in hook storage, timed matches create demand windows, swaps = shots, volume = goals, golden goal settles mid-swap, penalties count shots, deterministic seeding breaks deadlocks, champion fans claim the pot | [How the game works](../README.md#how-the-game-works) · demo video (quarterfinal 5–3, golden goal, champion crowned — real `forge test` output, labelled) |
| **On-chain interaction** | `joinTeam(seed)` pledges; swaps drive shots/goals/fees; lazy settlement via any swap or public `poke()`; golden-goal in-swap settlement; `claim()` pro-rata payouts; `sweepToLPs()` donates leftovers via `donate()` in an unlock callback | Deployed hook (12,931 bytes of live bytecode); deploy/init txs in [deployments/xlayer.json](../deployments/xlayer.json); liquidity/routing status below |

## Hook permissions (decoded from the CREATE2-mined address, bitmask `0x10c4`)

| Flag | Used for |
|---|---|
| `afterInitialize` | binds exactly one dynamic-fee pool, rejects everything else |
| `beforeSwap` | lazy match settlement + per-swap dynamic LP-fee override (0.50% → 0.25% fan → 0.15% live → 0.10% golden-goal ET) |
| `afterSwap` | shot recording + volume attribution for the live match |
| `afterSwapReturnsDelta` | 0.20% Champions Pot skim on the unspecified currency (canonical fee-taking pattern) |

All other 10 flags are false — verifiable by decoding the address bits.

## How to verify in three commands

```bash
# 1. The hook is live on X Layer mainnet
cast code 0x51f3d18a574c1deec5c04d395573cda9248dd0c4 --rpc-url https://rpc.xlayer.tech | wc -c   # 25865 → 12,931 bytes of live bytecode

# 2. Tournament state is on-chain and autonomous (255 = no champion yet)
cast call 0x51f3d18a574c1deec5c04d395573cda9248dd0c4 'champion()(uint8)' --rpc-url https://rpc.xlayer.tech

# 3. The whole tournament runs end-to-end locally
forge test --match-contract MundialDemo -vv
```

## Test evidence

- `forge test`: **77 tests passed, 0 failed** (two suites: unit/fuzz in [test/MundialHook.t.sol](../test/MundialHook.t.sol), narrated end-to-end tournament in [test/MundialDemo.t.sol](../test/MundialDemo.t.sol)).
- Fuzz properties: goal accounting, claim conservation (no value created or lost), tournament termination.
- The demo video's terminal footage is this test suite running — labelled "FOUNDRY END-TO-END TEST" on screen, not staged.

## Current status — honest

| Item | Status |
|---|---|
| Hook + token deployed, pool initialized (mainnet) | ✅ VERIFIED (bytecode + txs in [deployments/xlayer.json](../deployments/xlayer.json)) |
| Source verification | ✅ VERIFIED — published on OKLink ([hook](https://www.oklink.com/x-layer/evm/address/0x51f3d18a574c1deec5c04d395573cda9248dd0c4/contract) + [token](https://www.oklink.com/x-layer/evm/address/0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f/contract)) and exact match on [Sourcify](https://repo.sourcify.dev/196/0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4), chain 196 |
| Pool liquidity | ⏳ PENDING (pool initialized at 1:1, no position minted yet) |
| OKX Wallet routing | ⏳ UNCONFIRMED (depends on liquidity + discovery) |
| Hooklist | ✅ MERGED into [Uniswap/hooklist](https://github.com/Uniswap/hooklist/blob/main/hooks/xlayer/0x51f3d18a574c1deec5c04d395573cda9248dd0c4.json) (2026-07-16, `verifiedSource: true`) |

## Trust assumptions & known limitations

- **`tx.origin` for game attribution only** — deliberate and documented: routers/aggregators attribute swaps to the human; it never authorizes funds. Worst case: a malicious contract takes a shot for the victim's own team at the victim's own cost.
- **Timestamps as the clock** — hour-scale windows make second-scale validator drift immaterial.
- **A team's goals can be "bought" with volume** — by design: buying goals pays LP fees plus the pot skim, so manipulation pressure converts into LP and fan revenue.
- Tournament parameters are immutable after deploy; there is no pause or rescue mechanism (accepted trade-off for zero-trust).

Full threat model: [docs/SPEC.md](SPEC.md) §4.
