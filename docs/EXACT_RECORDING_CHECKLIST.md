# EXACT RECORDING CHECKLIST — read top to bottom, do exactly this

Three short screen recordings. Nothing else. Every card, overlay, caption, QR, and zoom is already built — you only supply raw footage. **Record in this order: A, B, C.** Total hands-on time ≈ 15 minutes.

Global rules for every clip:

- Canvas **1920×1080, 30 fps** (OBS Studio: Settings → Video → Base & Output 1920×1080, 30 FPS Common; or macOS: QuickTime full-screen on a 16:9 display; or Windows: Win+G Game Bar full screen).
- **Do Not Disturb ON** (macOS: Control Center → Focus; Windows: Win+N → Do not disturb; Ubuntu: notification toggle in quick settings).
- Close Slack/Discord/email/every personal window. Hide the bookmarks bar (browser: Ctrl/Cmd+Shift+B).
- Never visible: wallet popups, `.env` files, private keys, RPC keys, notifications, account balances, terminal history, personal bookmarks.
- After each clip: watch it end-to-end once, checking corners for popups, before moving on.

---

## Clip A — Foundry demo (the tournament proof)

**Save as:** `assets/video/raw/01-foundry-demo.mp4` · **Target length:** 25–40 s · Will appear labeled "FOUNDRY END-TO-END TEST".

1. Open VS Code on this repository, maximize the terminal panel (drag the divider to ~90% height).
2. Set terminal font size 24: Settings → search `terminal.integrated.fontSize` → `24`.
3. Run `clear`.
4. **Type but do NOT run:**
   `~/.foundry/bin/forge test --match-contract MundialDemo --match-test test_demo_fullTournamentNarrative -vv`
5. Start recording. Sit still 2 seconds.
6. Press Enter. (Output finishes in ~2 s — do not try to pause it. Zooms happen in the edit.)
7. Leave the finished output untouched on screen for **8 full seconds**.
8. Stop recording.

- **Start frame:** typed command visible, not yet executed. **End frame:** full output, cursor idle.
- **Must be visible in the final frame** (the edit zooms onto these exact lines):
  - `QF1 kickoff: Argentina vs France. Every swap is a shot.`
  - `Argentina goals: 5` and `France    goals: 3`
  - `Sudden death! Brazil fan swaps... GOLDEN GOAL.`
  - `Champion (seed index): 0`
  - `Champion fan claimed their pro-rata share of the pot.`
  - `No owner. No oracle. No randomness. Just football, on-chain.`
- **Must NOT be visible:** other terminal tabs' history, `.env`, notifications, your name in prompts is fine (it's a Codespace).
- **Pass check:** 1080p ✓ 30fps ✓ all six lines readable ✓ ≥8 s hold at end ✓ no popups ✓. Fail → just re-record from step 3; nothing else changes.

## Clip B — X Layer mainnet proof

**Save as:** `assets/video/raw/02-xlayer-explorer.mp4` · **Target length:** 20–30 s · Labeled "X LAYER MAINNET DEPLOYMENT".

1. Open a fresh browser window (guest/incognito is ideal), bookmarks hidden.
2. Go to exactly:
   `https://www.oklink.com/x-layer/address/0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4`
3. Let the page fully load. Put the cursor in dead space (right margin).
4. Start recording. Hold the address overview **3 seconds** — full address must be on screen.
5. Scroll down slowly (2–3 s per screen) to the transactions list. Hover the **contract-creation transaction** row (`0x97ea47ce…`) for 2 seconds. Do not click anything else.
6. Scroll back up until the address is visible again. Hold **3 seconds**. Stop.

- **Start/end frame:** address `0x51f3…Dd0C4` fully visible.
- **Must NOT appear:** any "verified" badge claim in your narrationless footage is fine as the page shows reality; do not open wallet extensions; no other tabs.
- **Pass check:** address legible at 100% zoom ✓ smooth slow scroll ✓ ≥3 s holds ✓. Fail → reload page, redo.

## Clip C — Public repository proof

**Save as:** `assets/video/raw/03-github-repo.mp4` · **Target length:** 20–30 s.

1. Same clean browser window: `https://github.com/Tonyflam/2_okx` (signed-out view is best — open it in the guest window).
2. Start recording on the repo header + hero image. Hold **2 seconds**.
3. Scroll slowly through the README: pause 2 s on "How the game works", 2 s on the testing section.
4. Click `src/MundialHook.sol` → hold 3 s on the license/pragma/top of the contract. Back.
5. Click `test/MundialDemo.t.sol` → hold 3 s. Back to the repo root, end on the hero. Stop.

- **Pass check:** no bookmarks bar ✓ no profile dropdown opened ✓ steady scroll ✓ ends on hero ✓.

## Clip D — live pool trade

**Skipped.** Liquidity is not seeded yet; there is no eligible route to show. Do not record a wallet for aesthetics. If liquidity is seeded later and a real route exists in OKX Wallet, we can add a 10 s clip — the timeline works with or without it.

---

**Then reply here with:** `clips done` (or `clip A done` etc. as you go). Files land in `assets/video/raw/` with the exact names above.
