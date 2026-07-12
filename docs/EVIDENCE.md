# Evidence & Decision Record — Hook × World Cup

All facts verified on **2026-07-12 (04:30–06:00 UTC)** unless noted. Confidence: **V** = verified from primary source, **I** = inferred, **U** = unknown.

## 1. Campaign rules evidence table

| # | Claim | Result | Source | Conf. |
|---|---|---|---|---|
| 1 | Campaign window | Jun 11, 23:59 UTC → **Jul 12, 23:59 UTC 2026**; submissions open at check time | web3.okx.com/xlayer/build-x-hackathon/hooktheworldcup | V |
| 2 | Chain | X Layer mainnet, chainId **196**, OP Stack, gas = OKB, Cancun EVM | Official page + OKX docs | V |
| 3 | Prize structure | Top 3 hook creators share a pool; pool tier unlocked by cumulative campaign volume: T0 10k → T4 200k USDT | Official page | V |
| 4 | Judging criteria | Code quality, World Cup creativity, on-chain interactions | Official page | V |
| 5 | Judging weights | Not published | Official page (absent) | U |
| 6 | Volume counting | Only trades executed through the **OKX Wallet frontend on Uniswap v4** count; launchpad bonding-curve volume excluded | Official page | V |
| 7 | Prize split among Top 3 | Not published | — | U |
| 8 | Volume snapshot time | Not published; assume deadline | — | U |
| 9 | Uniswap v4 PoolManager on 196 | `0x360e68faccca8ca495c1b759fd9eee466db9fb32` | Uniswap deployments docs | V |
| 10 | PositionManager | `0xcf1eafc6928dc385a342e7c6491d371d2871458b` | Uniswap deployments docs | V |
| 11 | Hooklist registration | GitHub **issue** on Uniswap/hooklist via `submit-hook.yml`; bot fetches **verified** source from OKX explorer API, then auto-PRs | Uniswap/hooklist repo | V |
| 12 | Explorer verification is a hard dependency for hooklist | Bot queries `web3.okx.com/api/v5/xlayer/contract/verify-contract-info` | hooklist bot source | V |
| 13 | Hooklist listing ⇒ OKX Wallet routes to the pool | Registry is *not* a routing allowlist; but merged competitor pools do receive OKX Wallet volume | hooklist README + WC2026Hook precedent | I |
| 14 | CREATE2 proxy `0x4e59…956C` exists on 196 | Standard OP-stack predeploy; deploy script asserts `code.length > 0` at runtime | I (checked at deploy) | I |
| 15 | WOKB (wrapped OKB) address on 196 | Not independently verified — **confirm before choosing QUOTE_TOKEN** | — | U |

## 2. Competitive landscape (verified on hooklist / explorer)

| Project | Address / status | Mechanic | Assessment |
|---|---|---|---|
| **GoldenGoalHook** | `0x742d6c…`, PR #1057 open | Match-phase dynamic fees, goal points, pot + buyback-burn, anti-snipe, pro-rata claims | **Strongest rival.** Single-match arena; relies on admin-set match phases |
| WC2026Hook | `0x28f389…`, merged | Campaign fee → prize pool, pseudo-random "shots", country attribution | Uses randomness; temporal swap gating |
| KickIt | `0x2e11d4…`, merged | Possession-based dynamic fee 0.30–1.50% from time-decaying buy/sell pressure | Elegant fee curve, thin WC narrative |
| FanPulse | `0x2E8E1d…`, mainnet | Admin "momentum slider" → dynamic fee | Weak: trusted operator |
| HatTrick Finance | testnet, MOCK pool manager | — | Not a real v4 deployment |
| shot2win / goalrush.fun | unverified | — | Insufficient public detail |
| eulr.fun launchpad tokens | e.g. "argentina AGRTN" | plain bonding-curve memecoins | Low effort, no hook logic |

## 3. Gap analysis

Every competitor is either: (a) a **single match** (GoldenGoal), (b) dependent on an **admin/oracle** to declare phases or scores (GoldenGoal, FanPulse), (c) dependent on **randomness** (WC2026Hook), or (d) a fee curve with a WC skin (KickIt). **Nobody runs an entire tournament, and nobody is trustless end-to-end.** That is the gap Mundial fills: an 8-team knockout bracket whose *only* inputs are swaps and timestamps — no owner, no oracle, no randomness, no upgradeability.

## 4. Concept matrix (10 ideas considered)

| Idea | WC creativity | Code depth | Trustless | Volume flywheel | Verdict |
|---|---|---|---|---|---|
| **Mundial: swap-driven knockout tournament** | ★★★ | ★★★ | ★★★ | ★★★ | **SELECTED** |
| Penalty-shootout fee lottery (VRF) | ★★★ | ★★ | ✗ randomness | ★★ | reject: overlaps WC2026Hook |
| Oracle-fed real-match fee mirror | ★★★ | ★★ | ✗ oracle | ★★ | reject: no oracle on 196 we trust |
| Possession-style momentum fee | ★★ | ★★ | ✓ | ★★ | reject: = KickIt |
| Team-token basket AMM (8 currencies) | ★★★ | ★★★ | ✓ | ★ | reject: v4 pools are pairs; too complex for deadline |
| Sticker-album NFT per swap | ★★ | ★★ | ✓ | ★★ | reject: NFT infra adds scope |
| Anti-snipe golden-goal single match | ★★ | ★★ | partial | ★★ | reject: = GoldenGoalHook |
| LP "stadium seats" with match-day boosts | ★★ | ★★ | ✓ | ★ | reject: rewards LPs, not traders (volume is judged) |
| Prediction-market hook on bracket | ★★★ | ★★★ | ✗ oracle | ★★ | reject: oracle |
| Fee rebate "season ticket" NFT | ★ | ★ | ✓ | ★★ | reject: thin |

## 5. Top-3 comparison & final decision

| | Mundial (tournament) | Penalty lottery | Oracle mirror |
|---|---|---|---|
| Differentiation vs field | Unique (nobody does a bracket) | Overlaps WC2026Hook | Overlaps GoldenGoal |
| Trust assumptions | None | VRF/randomness | Oracle operator |
| Deadline feasibility (~19h) | High (pure Solidity + Foundry) | Medium | Low (oracle infra) |
| Volume incentive | Fans trade to score goals + earn pot share + cheaper fees | Lottery only | Passive |

**Decision: Mundial.** It wins the exact judged axes: *code quality* (single sophisticated state machine, 38 tests + fuzz, zero admin), *WC creativity* (the pool literally plays a knockout World Cup with golden goals and penalties), *on-chain interactions* (every game action is a swap, pledge, poke, or claim).

## 6. Known unknowns / risks

1. **WOKB address unverified** — deploy against native OKB (`QUOTE_TOKEN=0`, hook handles native via `settle{value}`) or verify WOKB on the explorer first.
2. **OKX Wallet routing to hooked pools** — inferred from merged competitors receiving volume; not contractually guaranteed.
3. **Judging weights & prize split** — unpublished; strategy hedges by being strong on all three axes.
4. **Explorer verification** must succeed before the hooklist issue — allow time for `forge verify-contract` with the OKX/OKLink verifier.
