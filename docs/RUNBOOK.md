# 🏆 MUNDIAL MASTER LAUNCH RUNBOOK

**The single source of truth for launching Mundial before the deadline.**
Written so anyone can follow it. Read top to bottom. Do not skip warnings.

- Deadline: **Jul 12, 2026 — 23:59 UTC** (verified live on the official page at 05:40 UTC today)
- Campaign: Hook × World Cup — https://web3.okx.com/xlayer/build-x-hackathon/hooktheworldcup
- Repo: https://github.com/Tonyflam/2_okx (public; code not yet pushed)

**Status labels**: `SAFE` (agent did/can do automatically) · `HUMAN LOGIN` · `HUMAN SECRET` · `WALLET SIGNATURE` · `PUBLIC ACTION` · `IRREVERSIBLE` · `COMPLETED` · `BLOCKED` · `NOT STARTED`

Linked detail docs: [EVIDENCE.md](EVIDENCE.md) · [SPEC.md](SPEC.md) · [SUBMISSION.md](SUBMISSION.md) · [BRAND.md](BRAND.md) · [ASSETS.md](ASSETS.md) · [VOICE.md](VOICE.md) · [VIDEO.md](VIDEO.md) · [PITCH.md](PITCH.md) · [SOCIAL.md](SOCIAL.md) · [deployments/xlayer.json](../deployments/xlayer.json)

---

## PHASE 0 — Already done for you ✅

| Step | Status |
|---|---|
| Contracts written (hook + token), zero admin/oracle/randomness | `SAFE` `COMPLETED` |
| 77/77 tests pass, incl. 2000-run fuzz (CI profile), lint clean | `SAFE` `COMPLETED` |
| Secrets scan clean; `.env`, `broadcast/`, `cache/`, `out/` git-ignored | `SAFE` `COMPLETED` |
| X Layer infra verified **on-chain**: chain 196, PoolManager/PositionManager/Permit2/CREATE2 proxy all have bytecode | `SAFE` `COMPLETED` |
| Deployment **simulated against live X Layer**: total gas 5,642,989 ≈ **0.000226 OKB** | `SAFE` `COMPLETED` |
| All docs, brand pack, prompts, scripts prepared | `SAFE` `COMPLETED` |

You only do the steps below.

---

## PHASE 1 — Create and fund the deployer wallet

### ☐ 1.1 Import a dedicated deployer key into a Foundry keystore — `HUMAN SECRET`
**Why**: signing needs a key; a keystore keeps it encrypted on disk and out of shell history. Use a **fresh wallet used only for this deployment**, never your main wallet.

1. In the VS Code terminal, type exactly:
   ```bash
   ~/.foundry/bin/cast wallet import mundial-deployer --interactive
   ```
2. It asks for the private key: **paste it directly into the terminal prompt** (it is hidden; never paste it into chat, files, or a browser).
3. It asks for a password: invent one and remember it (needed once more at deploy time).
4. **Success looks like**: `` `mundial-deployer` keystore was saved successfully ``  plus the wallet address.
5. **Copy and save**: the printed address — call it `DEPLOYER_ADDRESS`.
6. **If it fails**: run it again; the most common issue is a key missing the `0x` prefix.
7. Reversible? **Yes** (`rm ~/.foundry/keystores/mundial-deployer` removes it).

> ⚠️ NEVER share the private key or password with anyone — including the AI assistant. If any tool or website ever asks for the seed phrase, STOP AND ASK FOR HELP.

### ☐ 1.2 Fund the deployer with OKB on X Layer — `WALLET SIGNATURE` `IRREVERSIBLE (spends real funds)`
**Why**: gas. Simulation says 0.000226 OKB; liquidity seeding, pool init and buffer bring the safe total to **0.05 OKB** (~a few dollars).

1. From OKX exchange or your main wallet, withdraw/send **0.05 OKB** to `DEPLOYER_ADDRESS`, network: **X Layer** (⚠️ NOT Ethereum, NOT OKC).
2. Verify arrival (SAFE, no secrets):
   ```bash
   ~/.foundry/bin/cast balance <DEPLOYER_ADDRESS> --rpc-url https://rpc.xlayer.tech
   ```
3. **Success looks like**: a number ≥ `50000000000000000` (0.05 OKB in wei).
4. **If it fails**: confirm the withdrawal network was X Layer; funds sent to the same address on another chain are recoverable with the same key, so do not panic — STOP AND ASK FOR HELP.

---

## PHASE 2 — Deploy (simulate first, then sign once)

> ⚠️ **IRREVERSIBLE**: broadcasting creates contracts permanently and the tournament clock starts at `KICKOFF`. Defaults: kickoff = 1h after deploy, 8h regulation + 1h extra time + 3h break per match (7 matches ≈ 3.5 days). Quote = **native OKB** (verified working in simulation; no WOKB dependency).

### ☐ 2.1 Re-simulate with YOUR wallet — `SAFE` (no broadcast)
```bash
cd /workspaces/2_okx
POOL_MANAGER=0x360e68faccca8ca495c1b759fd9eee466db9fb32 \
~/.foundry/bin/forge script script/DeployMundial.s.sol \
  --rpc-url https://rpc.xlayer.tech \
  --account mundial-deployer --sender <DEPLOYER_ADDRESS>
```
Enter your keystore password when prompted.
**Success looks like**: `SIMULATION COMPLETE`, a log block with `MundialToken:`, `MundialHook :`, `PoolId`, and an estimated cost near 0.000226 OKB.
**Check before continuing**: the `MundialHook` address must end with hex `10C4` pattern bits — the last 2 bytes AND `0x3FFF` must equal `0x10C4` (the agent will verify this for you — just paste the output into chat).
**If it fails**: paste the error into chat. Nothing was spent.

### ☐ 2.2 Broadcast for real — `WALLET SIGNATURE` `IRREVERSIBLE`
Same command **plus `--broadcast`**:
```bash
POOL_MANAGER=0x360e68faccca8ca495c1b759fd9eee466db9fb32 \
~/.foundry/bin/forge script script/DeployMundial.s.sol \
  --rpc-url https://rpc.xlayer.tech \
  --account mundial-deployer --sender <DEPLOYER_ADDRESS> \
  --broadcast
```
**Success looks like**: `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL` and tx hashes.
**Copy and save** (into chat is fine — all public data): MundialToken address, MundialHook address, PoolId, all tx hashes. The agent records them in [deployments/xlayer.json](../deployments/xlayer.json).
**If it fails**: most common cause is low gas funds; check balance and retry. A partial failure (token deployed, hook failed) is fine — tell the agent, the script can be re-run cleanly.

### ☐ 2.3 Seed liquidity — `WALLET SIGNATURE` `IRREVERSIBLE (locks funds in pool)`
**Why**: an empty pool can't trade; judges and OKX Wallet users need something to swap against. With native OKB + MUNDIAL and a 1:1 price, full-range `LIQUIDITY=1e21` needs ~**0.012 OKB + 0.012 MUNDIAL-scale** per side at minimum — we seed responsibly small.

The deployer already holds all 100M MUNDIAL. Ask the agent for the exact command once 2.2 completes (it needs the real addresses). It will use [script/SeedLiquidity.s.sol](../script/SeedLiquidity.s.sol) with `--account mundial-deployer`.
**Success looks like**: `Seeded liquidity` in the logs and a `ModifyLiquidity` event on the explorer.

### ☐ 2.4 One test swap — `WALLET SIGNATURE` (tiny, reversible in value)
Ask the agent for the exact `cast send` swap command (or use OKX Wallet UI once routed). A ~0.001 OKB swap proves `beforeSwap`/`afterSwap` fire.
**Success looks like**: tx succeeds; explorer shows the hook's `ShotTaken`/fee events; `pot` view increases if you pledged first.

---

## PHASE 3 — Verify contracts on the explorer (hard hooklist dependency)

### ☐ 3.1 Attempt automatic verification — `SAFE` to try
The agent runs `forge verify-contract` against the OKLink/OKX verifier with your deployed addresses (no secrets needed; a free OKLink API key may be required — `HUMAN LOGIN` at oklink.com if so).
**Success looks like**: "Contract successfully verified", and the address page on https://www.oklink.com/x-layer shows green "Contract" source tab.

### ☐ 3.2 Manual fallback via web UI — `HUMAN LOGIN`
1. The agent generates the exact Standard-JSON input files (`SAFE`, already scripted):
   ```bash
   ~/.foundry/bin/forge verify-contract <HOOK_ADDR> src/MundialHook.sol:MundialHook --show-standard-json-input > verify-hook.json
   ```
2. Open https://www.oklink.com/x-layer → search your contract address → "Verify Contract" → choose **Solidity (Standard JSON input)**, compiler `v0.8.26`, upload the file, paste constructor args (agent provides the exact hex).
3. **Success looks like**: source code visible on the contract page.
4. **If it fails**: check compiler `0.8.26+commit`, optimizer `true/800`, EVM `cancun`. STOP AND ASK FOR HELP after two failed attempts — the agent will diff settings.

---

## PHASE 4 — Publish the repository — `PUBLIC ACTION`

### ☐ 4.1 Approve the push
**Why**: hooklist and judges need public source. Repo is already public but only has "Initial commit"; the real code is local.
Tell the agent: **"push approved"** — it runs `git push origin main` and applies description/topics.
**Success looks like**: https://github.com/Tonyflam/2_okx shows the full README.
Reversible? Technically yes (force-push), practically treat as public forever.

---

## PHASE 5 — Hooklist registration — `PUBLIC ACTION`

### ☐ 5.1 Open the submission issue
**Why**: campaign requires hook registration; the bot needs your **verified** contract (Phase 3 first!).
The agent prepares the exact issue body (see [SUBMISSION.md](SUBMISSION.md) §hooklist). With your approval it runs:
```bash
gh issue create --repo Uniswap/hooklist --title "Add MundialHook (X Layer)" --body-file docs/hooklist-issue.md
```
…or you click "New issue → Submit a hook" at https://github.com/Uniswap/hooklist/issues/new/choose and paste.
**Success looks like**: issue created; within ~minutes the bot comments and opens a PR. **Copy and save the PR URL** — the form needs it.
**If it fails**: bot complains about unverified source → finish Phase 3, comment `/retry` or re-open.

---

## PHASE 6 — X (Twitter) account — `HUMAN LOGIN` `PUBLIC ACTION`

### ☐ 6.1 Create the account
1. Go to https://x.com/i/flow/signup (use an email you control; phone/CAPTCHA is yours to solve — never share codes).
2. Try handles in order: **@MundialHook**, **@MundialXLayer**, **@PlayMundial**.
3. Display name: `Mundial ⚽`; bio, link, and profile/banner images: everything is pre-written in [SOCIAL.md](SOCIAL.md) and [ASSETS.md](ASSETS.md) — copy/paste/upload.

### ☐ 6.2 Publish the launch post (required, tags @XLayerOfficial)
Copy **Post 1** verbatim from [SOCIAL.md](SOCIAL.md). Attach the banner or demo clip.
**Success looks like**: post is live and public. **Copy and save the post URL** — the form needs it.
Reversible? Deleting a post is possible but treat as permanent. ⚠️ Do not post before contracts are deployed — the post contains addresses.

---

## PHASE 7 — Demo video

### ☐ 7.1 Record + edit — follow [VIDEO.md](VIDEO.md) step-by-step (beginner-proof)
The narration script, storyboard, terminal commands, SRT captions, and export settings are all pre-written. Voice-over options (ElevenLabs, ~1,600 credits needed) in [VOICE.md](VOICE.md); recording your own voice with the same script is a fully acceptable fallback.

### ☐ 7.2 Upload — `HUMAN LOGIN` `PUBLIC ACTION`
Upload to YouTube as **Unlisted** (or attach directly to the X post). Test the link in a private browser window — it must play without login.
**Copy and save the video URL.**

---

## PHASE 8 — Final submission — `PUBLIC ACTION` `IRREVERSIBLE`

### ☐ 8.1 Fill the official form — `HUMAN LOGIN`
Open the submission form linked from the campaign page (button "Submit project" at https://web3.okx.com/xlayer/build-x-hackathon/hooktheworldcup). Every answer is pre-written in [SUBMISSION.md](SUBMISSION.md) §form — copy field by field, replacing the marked placeholders with the real addresses/URLs you saved.
**Before clicking Submit**: paste a screenshot or the filled values into chat — the agent runs the final placeholder/link check.

### ☐ 8.2 Submit — before **23:59 UTC**
> ⚠️ IRREVERSIBLE. Aim to submit by **22:30 UTC** to keep a buffer.
**Success looks like**: Google Forms confirmation screen. **Screenshot it and save.**

---

## ✅ DO THESE STEPS NOW — one-page human checklist (in order)

1. ☐ 1.1 Import deployer key into keystore (2 min)
2. ☐ 1.2 Send 0.05 OKB on X Layer network to the deployer (5 min)
3. ☐ 2.1 Run simulation command; paste output into chat (2 min)
4. ☐ 2.2 Say "broadcast approved", run deploy with `--broadcast` (3 min)
5. ☐ 2.3 Run the seed-liquidity command the agent gives you (3 min)
6. ☐ 3.x Verify contracts (agent-led; you click at most a web form) (15–45 min)
7. ☐ 4.1 Say "push approved" (1 min)
8. ☐ 5.1 Approve hooklist issue creation; save PR URL (10 min)
9. ☐ 6.1–6.2 Create X account; publish Post 1; save URL (20 min)
10. ☐ 2.4 One test swap through OKX Wallet if routing is live (10 min)
11. ☐ 7.x Record/edit/upload the 2-minute video; save URL (60–120 min)
12. ☐ 8.1–8.2 Fill form from SUBMISSION.md; final check with agent; **Submit by 22:30 UTC**

**Highest-risk dependency**: explorer contract verification (Phase 3) gates the hooklist (Phase 5). Do Phases 1–3 first; everything else can proceed in parallel.
