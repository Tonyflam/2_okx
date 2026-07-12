# Mundial 2-Minute Demo Video — Production Workbook

Target: **105–120 s**, 1920×1080, proves the contract genuinely works (live `forge test --match-contract MundialDemo -vv` output — real contract execution, not staged).

## 1. Final narration script (~235 words ≈ 109 s at natural pace)

> **[HOOK]** What if a liquidity pool could play the World Cup?
>
> **[CONCEPT]** This is Mundial — a Uniswap V-four hook on X-Layer. Every World Cup DeFi project so far picks one match, trusts an admin, or rolls the dice. Mundial does something harder: it runs the entire tournament — with no one in charge.
>
> **[MECHANIC]** Here's the trick. Fans pledge one of eight teams — once, irreversibly. When their team's match is live, every swap they make becomes a shot on goal. Trading volume scores goals. The market literally plays the football.
>
> **[DEMO]** Watch it run. Argentina versus France — fans trade, goals go up: five to three, Argentina advance. Brazil against England is scoreless into extra time — sudden death. One Brazilian fan swaps… GOLDEN GOAL. The match settles inside the very swap that scored it. Semifinals, penalties decided by shot counts, a final — and a champion is crowned. All of it, hook storage.
>
> **[TECH]** Under the hood: one dynamic-fee pool. Fans pay lower fees — a quarter percent, dropping to point-one-five while their team plays. A zero-point-two percent skim on fan swaps builds the Champions Pot. Winning fans claim it pro-rata to their volume; leftovers are donated to the LPs.
>
> **[TRUST]** No owner. No oracle. No randomness. The only inputs are swaps and time. Even wash-trading a goal just funds the pot. Thirty-eight tests. Fuzzed. Verified on-chain.
>
> **[CLOSE]** Mundial. Live on X-Layer. The pool that plays the World Cup.

**Backup short script (~75 s)**: keep HOOK, MECHANIC, first half of DEMO (through GOLDEN GOAL), TRUST, CLOSE — drop CONCEPT and TECH.

Pronunciation: see [VOICE.md](VOICE.md) dictionary. Emphasize: "GOLDEN GOAL", "no one in charge", final line slow.

### ⚠ REQUIRED CUTS in the recorded audio (do these in the editor before export)

1. **Hard-cut** the sentence *"Even wash-trading a goal just funds the pot."* — remove it entirely.
2. In *"Thirty-eight tests. Fuzzed. Verified on-chain."* — **cut after "Fuzzed."** ("Verified on-chain" is not yet true; source verification is pending, and the real count is 77 tests — the on-screen card shows the correct number).
3. Trim or cut *"Every World Cup DeFi project so far picks one match, trusts an admin, or rolls the dice."* — unsupported competitor claim; keep only "Mundial runs the entire tournament — with no one in charge."

Never show or say "verified" or "liquidity live" anywhere in the video.

## 2. Storyboard

All finished cards live in **`assets/video/ready/`** — text is baked in, nothing to typeset. Your narration audio is the master clock: slide the cut points to match it. Times below assume the ~117 s script.

| Time | Narration | Asset (assets/video/ready/) | Notes | Status |
|---|---|---|---|---|
| 0:00–0:05 | HOOK line | `00-title-card.png` | fade in from black | ☐ |
| 0:05–0:17 | CONCEPT | `01-tournament-card.png` | bracket + 8 team chips | ☐ |
| 0:17–0:31 | MECHANIC | `02-mechanic-card.png` | swap = shot on goal | ☐ |
| 0:31–0:43 | DEMO pt 1 ("Watch it run…") | **Clip A** `raw/01-foundry-demo.mp4` + overlay `recording-label-foundry.png` | fallback still: `terminal-wide.png` | ☐ |
| 0:43–0:47 | "five to three, Argentina advance" | `terminal-goals.png` + overlay `03-score-overlay.png` + `recording-label-foundry.png` | zoom in slightly | ☐ |
| 0:47–0:56 | "…GOLDEN GOAL" | `terminal-golden.png` (zoom on gold line), flash `04-golden-goal-card.png` ~1 s on the words | keep FOUNDRY label on terminal shots | ☐ |
| 0:56–1:08 | "champion is crowned" | `terminal-champion.png` + overlay `05-champion-overlay.png` | | ☐ |
| 1:08–1:20 | TECH (fees) | `06-fees-card.png` | | ☐ |
| 1:20–1:28 | TECH (pot) | `07-pot-card.png` | | ☐ |
| 1:28–1:39 | TRUST | `08-trust-card.png` | says 77 TESTS · FUZZED · DEPLOYED ON X LAYER | ☐ |
| 1:39–1:47 | "Live on X Layer" | **Clip B** `raw/02-xlayer-explorer.mp4` + overlay `recording-label-mainnet.png` | fallback still: `09-live-proof-card.png` (no label on the still) | ☐ |
| 1:47–1:51 | (optional) repo beat | **Clip C** `raw/03-github-repo.mp4` | skip if tight on time | ☐ |
| 1:51–1:57 | CLOSE | `10-end-card.png` | holds 4–6 s; FIFA disclaimer is baked in | ☐ |

## 3. Screen recording checklist (recording A = terminal, B = explorer/GitHub)

1. Close private tabs/apps; hide bookmarks bar. 2. OS Do-Not-Disturb ON. 3. No wallet extensions visible; no `.env` open; terminal history cleared (`clear`). 4. Display 1920×1080 (or record a 1920×1080 window region). 5. VS Code terminal font 18–20 pt (`terminal.integrated.fontSize`), dark theme (Default Dark Modern is fine), maximize terminal panel. 6. Rehearse once: `~/.foundry/bin/forge test --match-contract MundialDemo -vv`. 7. `clear`. 8. Start recorder — **OBS Studio** (free; Display/Window capture, 1080p30, mp4) or any OS recorder. 9. Type the command visibly, Enter, let output scroll; **pause 3 s on goals, GOLDEN GOAL, champion, claim lines** (output is fast — you will zoom in editing instead of pausing live; just leave it on screen 10 s at end). 10. For recording B: scroll the verified contract page on oklink.com, then the GitHub README slowly. 11. Stop. 12. Rename `raw-terminal.mp4`, `raw-explorer.mp4`; copy to a second location. 13. Scrub both for secrets/notifications before importing.

## 4. Editing — primary: **CapCut Desktop** (free); fallback: **DaVinci Resolve** (free)

1. New project → 16:9, 1080p, 30 fps. 2. Import: your clips from `assets/video/raw/`, every PNG in `assets/video/ready/`, and your narration file. 3. Drop narration on audio track 1 — it is the master clock. 4. Lay visuals per storyboard timestamps; trim terminal recording: cut dead scrolling, keep the log lines listed above; use CapCut "zoom" keyframes (scale 100→160%) on each highlighted log line. 5. Text: none needed — every card already has its text baked in; do not add extra titles. 6. Captions: import `assets/video/ready/captions-final.srt` via Captions → Import; style: 60% width, bottom, dark bg 60% opacity (this file already matches the required audio cuts — nudge timings to your audio). 7. SFX (CapCut library or pixabay.com, license CC0 — record source+license in `assets/audio/CREDITS.md`): whistle, crowd, UI ticks — max 3–4 total. 8. Music: one bed, "epic minimal sport tech" (CapCut commercial-safe library or pixabay CC0). Volume −22 dB under narration; use Auto-duck if available; music alone peaks −14 dB at open/close. 9. Transitions: only cuts, the two plate wipes (0.3 s), and fades at start/end. 10. End card 4–6 s with URL text. 11. Watch full-through muted (must still make sense), then with sound, then on phone-size preview. 12. Export: **1920×1080, 30 fps, H.264 MP4, AAC 48 kHz, bitrate 16 Mbps** → `mundial-demo-final.mp4`. 13. Loudness: if available run Auto-volume/normalize to ≈ −16 LUFS, true peak ≤ −1 dB (CapCut "Loudness normalization"; or `ffmpeg -i in.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:v copy out.mp4`). 14. Back up final + project file.

## 5. Captions file

Use the pre-built, claim-checked file: **`assets/video/ready/captions-final.srt`** (42-char lines, no wash-trading sentence, no "verified" claim, correct test count). Do not use any older inline captions.

## 6. Thumbnail
Already built: **`assets/video/ready/thumbnail-final.png`** (1280×720, text baked in). Upload as-is; check readability at 320 px wide.

## 7. Upload & final review checklist
☐ Duration ≤ 120 s ☐ 1080p30 H.264 ☐ narration clear on laptop speakers ☐ captions synced ☐ no secrets/notifications visible in any frame ☐ behavior shown = real contract output ☐ music licensed (sources logged in CREDITS.md) ☐ plays start-to-finish on phone ☐ upload YouTube **Unlisted** → title "Mundial — the Uniswap v4 pool that plays the World Cup (X Layer)" → description = long description + disclaimer + repo link ☐ link opens in private window without login ☐ URL saved into SUBMISSION.md.
