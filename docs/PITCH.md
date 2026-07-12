# Mundial — Judge-Facing Pitches

All comparative claims are sourced in [EVIDENCE.md](EVIDENCE.md) §2 (publicly reviewed competitor set, checked 2026-07-12). We never claim "first" or "only" in absolute terms.

## 10-word pitch
One Uniswap v4 pool plays a whole World Cup autonomously.

## 25-word pitch
Mundial turns one Uniswap v4 pool into a complete eight-team knockout World Cup: swaps are shots, volume scores goals, champion fans claim the pot.

## 50-word pitch
Mundial is a Uniswap v4 hook on X Layer that runs a full eight-team knockout tournament inside one dynamic-fee pool. Fans pledge teams; their swaps become shots; volume scores goals; golden goals settle mid-swap; penalties count shots. Champion fans claim a skimmed pot pro-rata. No admin, oracle, or randomness.

## 100-word pitch
Mundial makes a liquidity pool play the World Cup. Eight teams enter a knockout bracket living entirely in hook storage on X Layer. Traders pledge a team once; while that team's match is live their swaps are recorded as shots, and swap volume converts to goals. Matches resolve by full-time lead, sudden-death golden goals settled inside the scoring swap, penalties by shot count, then deterministic seeding. Fans trade at reduced dynamic fees; a 0.20% skim accumulates a Champions Pot claimed pro-rata by champion-team fans, with leftovers donated to LPs. No owner, no oracle, no randomness — only swaps and time.

## Two-minute spoken pitch
Use the narration script in [VIDEO.md](VIDEO.md) §1 verbatim — it is timed, sourced, and consistent.

## Technical-judge pitch
Mundial exercises the v4 hook surface meaningfully rather than decoratively. `afterInitialize` binds exactly one dynamic-fee pool and rejects everything else. `beforeSwap` lazily settles any due matches (bounded 7-iteration sync) and returns a per-swap LP-fee override — four tiers driven by game state. `afterSwap` with `afterSwapReturnDelta` implements the canonical fee-taking pattern on the unspecified currency to fund the pot, and records shots/volume for the live match. Unclaimed funds exit via `donate()` inside an `unlock` callback, handling native-OKB settlement. The hook address is CREATE2-mined to encode permissions and self-validated in the constructor (`Hooks.validateHookPermissions`) — we implement `IHooks` directly since BaseHook was removed from v4-periphery main. 77 tests including comparative fee assertions, full settlement-path coverage, and three fuzz properties (goal math, claim conservation, tournament termination) at 2,000 runs.

## Non-technical-judge pitch
Every trade in Mundial's pool is a kick of the ball. Pick your team once; when they play, your trades are shots and enough trading scores goals. Ties go to sudden death — one golden goal ends it instantly. The winners' fans split a prize pot that grew from their own trading. Nobody referees this tournament: no company, no data feed, no dice — the rules are locked in code that anyone can read, and they run themselves.

## Why the hook is technically necessary
The game *is* the pool's swap flow, so it can only exist as a hook: fee tiers require per-swap `beforeSwap` overrides on a dynamic-fee pool; shot attribution and pot skims require `afterSwap` + return-delta access to the swap's settled amounts; lazy match settlement must piggyback on swap execution to stay autonomous; and returning leftovers to LPs uses `donate` — a PoolManager primitive only reachable from unlock callbacks. No router wrapper, standalone contract, or off-chain service could bind game state to trades atomically the way hook callbacks do.

## Why the World Cup theme is functional, not decorative
The tournament structure generates the economics. The bracket schedule creates time-boxed demand windows (fans trade *during their match* for cheapest fees and goals); knockout elimination concentrates attention on surviving teams; golden-goal sudden death creates a provable "last decisive swap" moment; penalties-by-shots reward participation count, not size. Remove the football and the fee tiers, skim, and claims lose their coordinating logic — the theme is the mechanism design.

## Security & trust assumptions
No privileged roles, upgradeability, oracle, or randomness exist; parameters are immutable and the only inputs are swaps and `block.timestamp` (hour-scale windows make second-scale validator drift immaterial). Value paths follow CEI; claims are flag-before-transfer; sweep runs inside PoolManager's unlock with balance snapshots. The one deliberate softness — `tx.origin` for *game attribution only* — is documented: it never authorizes funds, and the worst a malicious contract can do is take a shot for the victim's own team at the victim's own cost. Full threat model: [SPEC.md](SPEC.md) §4.

## Legitimate user engagement
Engagement incentives are aligned with real trading, not manipulation: fans get fee *discounts* (cheapest while their team plays), goals require volume that pays LP fees plus the pot skim — so "buying goals" is costly and the cost accrues to LPs and other fans, converting manipulation pressure into protocol revenue. Prize-volume rules are external to us (OKX-frontend-only counting), and we neither run nor encourage wash trading, Sybil accounts, or artificial volume.
