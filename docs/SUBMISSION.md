# Mundial — Submission Pack (Hook × World Cup)

Deadline: **Jul 12, 2026 23:59 UTC**. Nothing in this file is executed without explicit human approval.

## 1. Submission form draft

- **Project name**: Mundial — the pool that plays the World Cup
- **One-liner**: A Uniswap v4 hook that turns one pool into a fully on-chain 8-team knockout tournament — swaps are shots, volume scores goals, golden goals settle mid-swap, champion fans claim the pot. No owner, no oracle, no randomness.
- **Chain**: X Layer mainnet (196)
- **Hook address**: _fill after deploy_
- **Pool ID**: _fill after deploy_
- **Token**: MUNDIAL (fixed 100M supply, zero admin) — _address after deploy_
- **Repo**: https://github.com/Tonyflam/2_okx
- **Hooklist PR**: _fill after issue → bot PR_
- **X account**: _fill after creation_
- **Demo video**: _fill after recording_
- **How it uses v4**: dynamic-fee override per swap (`beforeSwap`), shot recording + 0.20% pot skim via `afterSwapReturnDelta` (FeeTakingHook pattern), `donate()` of unclaimed pot to LPs, single-pool binding at `afterInitialize`, CREATE2-mined flag address.

## 2. Judge-facing pitch (30 s read)

Every other World Cup hook is a single match, an admin switch, or a dice roll. **Mundial is the whole tournament, and it's trustless.** Eight teams, a real knockout bracket, golden goals that settle a match inside the very swap that scores them, penalties decided by shot counts, all driven exclusively by trades and timestamps. There is no owner to rug, no oracle to bribe, no randomness to game — wash-trading a goal literally funds the LPs and the champions' pot. It maximizes the three judged axes at once: a single sophisticated state machine with 38 passing tests and fuzz proofs (**code quality**), a pool that literally plays football (**creativity**), and a design where every game action — pledge, shot, poke, claim — is an on-chain interaction that fans *want* to make because fans trade cheaper (**interactions/volume**).

## 3. Two-minute demo video script

| t | Scene | Line |
|---|---|---|
| 0:00 | Title card | "What if a liquidity pool could play the World Cup?" |
| 0:10 | Terminal: `forge test --match-contract MundialDemo -vv` | "This is Mundial, a Uniswap v4 hook on X Layer. One pool. Eight teams. A real knockout bracket. Zero admins." |
| 0:25 | Demo log: fans pledge | "Fans pledge a team once, irreversibly. From then on, their swaps are shots on goal — and fans trade cheaper: 0.25% vs 0.50%, dropping to 0.15% while their team plays." |
| 0:45 | QF1 goals scroll | "Argentina vs France. Volume scores goals — 5 to 3 at full time, Argentina advances. Every number you see is hook storage, not a backend." |
| 1:05 | Golden goal | "Brazil–England is scoreless into extra time. Sudden death: one Brazilian fan swaps — golden goal, and the match settles *inside that same swap*." |
| 1:25 | Champion + claim | "The bracket resolves itself — goals, then penalties by shot count, then seed. Deterministic, no oracle, no randomness. Champion fans claim a pot skimmed from their own trades, pro-rata by volume. Leftovers are donated to LPs." |
| 1:45 | Addresses + explorer | "Live on X Layer, verified, registered on the Uniswap hooklist. 38 tests, three fuzz suites." |
| 1:55 | Close | "Mundial. The pool that plays the World Cup." |

## 4. X (Twitter) account launch plan

1. Create dedicated account (e.g. `@MundialHook`), bio: "⚽ The Uniswap v4 pool that plays the World Cup — live on @XLayerOfficial. No owner, no oracle, no randomness."
2. First post immediately after deploy, tagging `@XLayerOfficial` and linking the pool + repo.
3. Pin the demo video post once recorded.

## 5. 10-post content calendar

| # | Timing | Post |
|---|---|---|
| 1 | Launch | 🚨 Kickoff! Mundial is live on @XLayerOfficial — the first Uniswap v4 pool that plays an entire World Cup on-chain. Swaps are shots. Volume scores goals. No owner, no oracle. [addresses + repo] |
| 2 | +1h | How it works, 🧵: pledge one of 8 teams → your swaps become shots during your team's match → goals win matches → champions split the pot. Diagram attached. |
| 3 | Pre-QF1 | ⏰ QF1 kicks off at [time UTC]: 🇦🇷 Argentina vs 🇫🇷 France. Fans of playing teams pay just 0.15% fees. Pick your side. |
| 4 | During QF1 | LIVE: Argentina 2–1 France with [x] minutes of regulation left. One swap can change everything. |
| 5 | Post-QF1 | FULL TIME. [Winner] advances — settled entirely by hook storage, verifiable on the explorer: [tx link]. |
| 6 | Golden-goal moment | ⚡ GOLDEN GOAL. Match settled *inside the swap that scored it*. This is what "trading is the game" means. [tx link] |
| 7 | Tech post | Under the hood: dynamic fee override, afterSwapReturnDelta skim, 38 Foundry tests, 3 fuzz proofs, zero privileged roles. Code: [repo] |
| 8 | Semis | Bracket update graphic: the final four. Next kickoff [time]. |
| 9 | Final | 🏆 THE FINAL. Winner-team fans split the Champions Pot pro-rata by their traded volume. 30-day claim window, leftovers donated to LPs. |
| 10 | Champion crowned | Champions! 🏆 [Team] fans can now claim(). Thank you @XLayerOfficial × @Uniswap — the beautiful game, fully on-chain. |

## 6. Eligibility checklist

- [ ] Hook deployed to X Layer mainnet (196) within campaign window
- [ ] Pool created on Uniswap v4 PoolManager `0x360e…fb32` with the hook attached
- [ ] Contracts **verified on OKX explorer** (hard dependency for hooklist bot)
- [ ] Hooklist issue opened via `submit-hook.yml` → bot PR URL captured
- [ ] Liquidity seeded so OKX Wallet can route trades
- [ ] Dedicated X account created; launch post tags @XLayerOfficial
- [ ] Demo video recorded (≤2 min)
- [ ] Submission form completed before **23:59 UTC**
- [ ] No wash trading / Sybil activity by us — organic volume only
- [ ] Repo public with README, docs, tests

## 7. Critical path (remaining hours, all times UTC Jul 12)

| Time | Owner | Step |
|---|---|---|
| by 07:00 | agent | Code, tests, scripts, docs complete; repo committed ✅ |
| 07:00–08:00 | **human** | Fund deployer EOA with OKB; set `XLAYER_RPC_URL`, `PRIVATE_KEY`; decide QUOTE_TOKEN (native OKB default; verify WOKB first if preferred) and KICKOFF |
| 08:00–09:00 | human+agent | Run `DeployMundial.s.sol --broadcast`; record addresses; run `SeedLiquidity.s.sol` (ERC20 pair) or seed via UI |
| 09:00–10:30 | human+agent | `forge verify-contract` both contracts on OKX explorer; confirm "verified" via explorer API |
| 10:30–11:30 | human | Open hooklist issue (submit-hook.yml); wait for bot PR; capture PR URL |
| 11:30–12:30 | human | Create X account; launch post tagging @XLayerOfficial; record 2-min demo (`forge test --match-contract MundialDemo -vv` + explorer) |
| 12:30–14:00 | human | Test a real swap through OKX Wallet frontend to the pool; confirm routing |
| 14:00–20:00 | human | Content calendar posts 2–4; monitor; buffer for verification/routing issues |
| 20:00–22:00 | human | Fill and double-check submission form (do **not** submit before final review) |
| 22:00–23:00 | human | **Submit form.** Screenshot confirmation |
| 23:00–23:59 | — | Buffer. No changes after submission |
