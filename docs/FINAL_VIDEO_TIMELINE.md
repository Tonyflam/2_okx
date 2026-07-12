# FINAL VIDEO TIMELINE — Mundial demo (1080p30, target ≤120 s)

Machine-readable master: [assets/video/work/timeline.csv](../assets/video/work/timeline.csv) — the render script reads that file; this page mirrors it for review. Rebuild any time with `./script/build_demo_video.sh`.

**Status: PROVISIONAL — timed to the written narration (~117.5 s at natural pace). The moment `assets/audio/narration-final.wav|.mp3` lands, in/out points are re-fitted to the actual spoken phrase boundaries and this table is updated. Do not ship the silent review render.**

Audio track: narration only, loudnorm −16 LUFS / −1.5 dBTP. No music (nothing licensed is on hand; the narration carries it). Fade-in 0.5 s, fade-out 0.7 s. Captions burned in + `captions-final.srt` alongside.

| # | In | Out | Narration (spoken words) | Visual | Motion | Overlays | Transition | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | 0:00.0 | 0:05.0 | "What if a liquidity pool could play the World Cup?" | 00-title-card | Ken Burns in (1.00→1.07, centered) | — | fade-in 0.5 s | ☑ rendered |
| 2 | 0:05.0 | 0:17.5 | "This is Mundial — a Uniswap v4 hook on X Layer… runs the entire tournament — with no one in charge." | 01-tournament-card | KB out | — | cut | ☑ rendered |
| 3 | 0:17.5 | 0:31.5 | "Fans pledge one of eight teams… The market plays the football." | 02-mechanic-card | KB in | — | cut | ☑ rendered |
| 4 | 0:31.5 | 0:43.0 | "Watch it run. Argentina versus France — fans trade, goals go up." | raw 01-foundry-demo.mp4 · fallback terminal-wide | KB in (still) / straight (clip) | recording-label-foundry | cut | ☑ fallback rendered |
| 5 | 0:43.0 | 0:47.5 | "Five to three — Argentina advance." | terminal-goals (zoom crop of real output) | static | 03-score-overlay + foundry label | cut | ☑ rendered |
| 6 | 0:47.5 | 0:56.5 | "Brazil against England is scoreless into extra time… GOLDEN GOAL." | terminal-golden | KB in | foundry label | cut | ☑ rendered |
| 7 | 0:56.5 | 1:00.5 | "The match settles inside the very swap that scored it." | 04-golden-goal-card | static | — | cut | ☑ rendered |
| 8 | 1:00.5 | 1:08.5 | "Semifinals, penalties decided by shot counts… All of it, hook storage." | terminal-champion | static | 05-champion-overlay + foundry label | cut | ☑ rendered |
| 9 | 1:08.5 | 1:20.5 | "One dynamic-fee pool… point-one-five while their team plays." | 06-fees-card | KB out | — | cut | ☑ rendered |
| 10 | 1:20.5 | 1:28.5 | "A zero-point-two percent skim builds the Champions Pot… leftovers go to the LPs." | 07-pot-card | KB in | — | cut | ☑ rendered |
| 11 | 1:28.5 | 1:39.5 | "No owner. No oracle. No randomness… Seventy-seven tests. Fuzzed." | 08-trust-card | static | — | cut | ☑ rendered |
| 12 | 1:39.5 | 1:47.5 | "Deployed on X Layer. Code public on GitHub." | raw 02-xlayer-explorer.mp4 · fallback 09-live-proof-card | KB in (still) | recording-label-mainnet (clip only) | cut | ☑ fallback rendered |
| 13 | 1:47.5 | 1:53.5 | "Mundial. Live on X Layer. The pool that plays the World Cup." | 10-end-card | static | — | cut | ☑ rendered |
| 14 | 1:53.5 | 1:57.5 | *(silence tail)* | 10-end-card hold ≥4 s | static | — | fade-out 0.7 s | ☑ rendered |

## Narration-audit deltas already applied to captions/cards

The recorded script (docs/VIDEO.md §1) contains three lines that must NOT survive into the final audio; captions and cards above already use the corrected wording:

| Recorded line | Action on the audio | Replacement in captions/cards |
|---|---|---|
| "Even wash-trading a goal just funds the pot." | **Hard cut** — sits between two sentence boundaries in TRUST; a clean scissor edit works. | *(removed)* |
| "Thirty-eight tests. Fuzzed. Verified on-chain." | Cut after "Fuzzed." — drop "Verified on-chain." If the cut clicks, ONE replacement sentence is needed: **"Seventy-seven tests. Fuzzed. Deployed on X Layer."** (George, stability 45 / similarity 75 / style 35 / boost on) | "Seventy-seven tests. Fuzzed." + card 09 shows DEPLOYED · SOURCE VERIFICATION PENDING |
| "Every World Cup DeFi project so far picks one match, trusts an admin, or rolls the dice." | Keep only if the audio can cleanly reduce to "Mundial runs the entire tournament — with no one in charge."; otherwise cut the comparison sentence. | "It doesn't pick one match or trust an admin. It runs the entire tournament — with no one in charge." |

## Re-timing procedure when the audio arrives

1. `ffprobe` duration; transcribe with timestamps.
2. Perform the three surgical cuts above (ffmpeg `atrim`+`concat` at zero-crossings).
3. Set each scene's `dur` in timeline.csv to the actual phrase boundaries (±0.2 s early on the visual).
4. `./script/build_demo_video.sh --final` → QC gates → `assets/video/final/mundial-demo-final.mp4`.
