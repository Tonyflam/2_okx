# ⚽ MUNDIAL — the pool that plays the World Cup

![Mundial](assets/brand/hero-repo.jpg)

**A Uniswap v4 Hook on X Layer that turns one liquidity pool into a fully on-chain 8-team knockout tournament.** Trading *is* the game: every swap by a pledged fan is a shot on goal, volume scores goals, the bracket resolves itself, and champion fans claim a pot skimmed from their own trades.

**🔴 LIVE on X Layer mainnet (chain 196)** — Hook [`0x51f3d18a574c1deec5c04d395573cda9248dd0c4`](https://www.oklink.com/x-layer/address/0x51f3d18a574c1deec5c04d395573cda9248dd0c4) · Token [`0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f`](https://www.oklink.com/x-layer/address/0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f) · Pool `0x0cc28818a207ae3c182a88dbe9677203859f916116711a19c9b010bf390bbeda` · Kickoff **2026-07-12 12:45 UTC** · Full record: [deployments/xlayer.json](deployments/xlayer.json)

🎥 **[2-minute demo video](https://youtu.be/Jk3e9K3U0bg)** · 📋 **[Judge guide](docs/JUDGING.md)** · 🪝 **[Uniswap hooklist PR #1062](https://github.com/Uniswap/hooklist/pull/1062)**

**Current status (honest):** contracts deployed & pool initialized ✅ · explorer source verification pending ⏳ · pool liquidity pending ⏳ · OKX Wallet routing unconfirmed ⏳

Built for the **Hook × World Cup** campaign (OKX × X Layer × Uniswap v4, Jun 11 – Jul 12 2026).

> **No owner. No oracle. No randomness. No upgradeability.** The entire tournament — kickoffs, goals, golden goals, penalties, bracket progression, payouts — is deterministic on-chain logic driven purely by swaps and timestamps.

## How the game works

1. **Pledge** — call `joinTeam(seed)` once, irreversibly, for any of 8 still-alive teams (Argentina, France, Brazil, England, Spain, Germany, Portugal, Netherlands).
2. **Play** — swap in the pool. If your team is playing its match *right now*, your swap is a **shot**: its currency1 volume accrues to your team. Every `goalThreshold` of volume = **1 goal**.
3. **Match resolution** (all lazy — settled by the next swap or a public `poke()`):
   - Lead at full time → **win**.
   - Tied → **extra time, sudden death**: first goal is a **golden goal** and settles instantly, mid-swap.
   - Still tied at ET end → **penalties**: more shots (swap count) wins.
   - Total deadlock → lower **seed** advances (deterministic, no randomness).
4. **Bracket** — QF → SF → Final, standard single-elimination, fully on hook storage.
5. **Win** — champion-team fans `claim()` a pro-rata share (by their traded volume) of the **Champions Pot**: a 0.20% skim taken only from fan swaps. 30-day claim window, then `sweepToLPs()` donates leftovers to the pool's LPs.

## Fee tiers (dynamic-fee pool)

| State | LP fee |
|---|---|
| Neutral swapper | 0.50% |
| Fan of an alive team | 0.25% |
| Fan whose team is playing **live** | 0.15% |
| Fan swapping in **golden-goal extra time** | 0.10% |

Being a fan is cheaper. Playing is cheapest. The hook overrides the fee per-swap via `OVERRIDE_FEE_FLAG`.

## Architecture

```mermaid
flowchart LR
    subgraph XLayer["X Layer (chain 196)"]
        PM[Uniswap v4 PoolManager]
        H[MundialHook]
        T[MundialToken\nfixed supply, no admin]
        PM -- beforeSwap: fee override + lazy settle --> H
        PM -- afterSwap: shot recording + 0.20% skim --> H
        H -- donate leftovers --> PM
    end
    Fan((Fan)) -- joinTeam / swap / claim --> PM
    Anyone((Anyone)) -- poke --> H
```

- [src/MundialHook.sol](src/MundialHook.sol) — implements `IHooks` directly (BaseHook was removed from v4-periphery main; we self-validate permissions with `Hooks.validateHookPermissions` in the constructor). Flags: `afterInitialize | beforeSwap | afterSwap | afterSwapReturnDelta`.
- [src/MundialToken.sol](src/MundialToken.sol) — minimal solmate ERC20, 100M fixed supply, zero privileges.
- Single pool binding: `afterInitialize` rejects static-fee pools and any second pool.

## Trust model & security notes

- **Zero admin surface**: no owner, pauser, or upgrade path anywhere.
- **Fan attribution uses `tx.origin`** — a deliberate, documented choice so routers/aggregators (incl. the OKX Wallet router path) attribute swaps to the human. Contracts/smart accounts simply get neutral treatment; there is no approval-based risk since `tx.origin` is never used for authorization of funds, only game scoring.
- **Skim** follows the canonical FeeTakingHook pattern (`afterSwapReturnDelta`, take on the unspecified currency), CEI everywhere, claim flag set before transfer.
- **Bounded loops**: `_sync()` settles at most 7 matches; no unbounded iteration.
- Full threat model in [docs/SPEC.md](docs/SPEC.md).

## Build & test

```bash
git clone --recurse-submodules https://github.com/Tonyflam/2_okx
forge build
forge test          # 77 tests across 2 suites, incl. 3 fuzz properties
forge test --match-contract MundialDemo -vv   # narrated end-to-end tournament
```

## Deploy (X Layer)

```bash
export XLAYER_RPC_URL=https://rpc.xlayer.tech
export POOL_MANAGER=0x360e68faccca8ca495c1b759fd9eee466db9fb32
# optional: QUOTE_TOKEN (default native OKB), KICKOFF, REGULATION, EXTRA_TIME, BREAK_TIME, GOAL_THRESHOLD

# use a Foundry keystore (cast wallet import <name> --interactive); never a raw key in env
forge script script/DeployMundial.s.sol --rpc-url $XLAYER_RPC_URL --account <keystore-name> --broadcast
# then seed liquidity (native-OKB pair) via:
forge script script/SeedLiquidity.s.sol --rpc-url $XLAYER_RPC_URL --account <keystore-name> --broadcast
```

The deploy script mines a CREATE2 salt (`HookMiner`) so the hook address encodes its permission flags, deploys token + hook, and initializes the dynamic-fee pool at 1:1.

### Deployed addresses (X Layer mainnet)

| Contract | Address |
|---|---|
| MundialToken | [`0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f`](https://www.oklink.com/x-layer/address/0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f) |
| MundialHook | [`0x51f3d18a574c1deec5c04d395573cda9248dd0c4`](https://www.oklink.com/x-layer/address/0x51f3d18a574c1deec5c04d395573cda9248dd0c4) |
| PoolManager | `0x360e68faccca8ca495c1b759fd9eee466db9fb32` |

## Docs

- [docs/JUDGING.md](docs/JUDGING.md) — **judge guide**: evidence per judging dimension, how to verify in three commands.
- [docs/SPEC.md](docs/SPEC.md) — PRD, interfaces, threat model.
- [docs/PITCH.md](docs/PITCH.md) — pitches from 10 words to technical depth.
- [deployments/xlayer.json](deployments/xlayer.json) — machine-readable deployment record (real tx hashes).
- [assets/audio/CREDITS.md](assets/audio/CREDITS.md) — demo-video audio attribution.

> Mundial is an independent project built for the Hook × World Cup campaign on X Layer. It is not affiliated with or endorsed by FIFA, any football federation, Uniswap Labs, OKX, or X Layer. Not financial advice; participation involves risk of loss.

## License

MIT
