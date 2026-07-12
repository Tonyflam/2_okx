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

## 2. Storyboard

| Time | Visual | Narration | On-screen text | Sound | Transition | Asset | Status |
|---|---|---|---|---|---|---|---|
| 0:00–0:05 | Title card artwork | HOOK line | MUNDIAL / The pool that plays the World Cup | stadium swell + kick SFX | fade in | `video-title.png` | ☐ |
| 0:05–0:17 | Bracket background, 8 team names animate in | CONCEPT | 8 TEAMS · 1 POOL · 0 ADMINS | music bed starts | wipe (plate A) | `bg-bracket.png` | ☐ |
| 0:17–0:32 | Diagram: wallet → swap → shot → goal (build in editor over bg) | MECHANIC | SWAP = SHOT · VOLUME = GOALS | UI tick SFX | cut | `bg-architecture.png` | ☐ |
| 0:32–0:56 | **Screen recording**: terminal running MundialDemo, zoom on "Argentina goals: 5 / France goals: 3" | DEMO pt 1 | QF1: ARG 5 – 3 FRA | crowd murmur low | cut | recording A | ☐ |
| 0:56–1:04 | Zoom on "GOLDEN GOAL" log line; flash to golden-goal artwork 1s | "…GOLDEN GOAL…" | GOLDEN GOAL — settled in-swap | whistle + hit SFX | flash | recording A + `visual-goldengoal.png` | ☐ |
| 1:04–1:12 | Terminal: champion + claim lines | DEMO pt 2 | CHAMPION CROWNED · POT CLAIMED | crowd cheer short | cut | recording A | ☐ |
| 1:12–1:30 | Fee-tier table + pot diagram (editor text over bg) | TECH | 0.50% → 0.25% → 0.15% · 0.20% → POT | music bed | wipe (plate B) | `bg-architecture.png` | ☐ |
| 1:30–1:43 | Explorer page of verified hook + GitHub README scroll | TRUST | NO OWNER · NO ORACLE · NO RANDOMNESS · 38 TESTS | music rises | cut | recording B | ☐ |
| 1:43–1:49 | CTA end card | CLOSE | @handle · github.com/Tonyflam/2_okx · X Layer | final hit, music ends | fade | `video-endcard.png` | ☐ |
| 1:49–1:53 | End card holds, disclaimer small print | — | not affiliated with FIFA/Uniswap/OKX | silence tail | fade out | same | ☐ |

## 3. Screen recording checklist (recording A = terminal, B = explorer/GitHub)

1. Close private tabs/apps; hide bookmarks bar. 2. OS Do-Not-Disturb ON. 3. No wallet extensions visible; no `.env` open; terminal history cleared (`clear`). 4. Display 1920×1080 (or record a 1920×1080 window region). 5. VS Code terminal font 18–20 pt (`terminal.integrated.fontSize`), dark theme (Default Dark Modern is fine), maximize terminal panel. 6. Rehearse once: `~/.foundry/bin/forge test --match-contract MundialDemo -vv`. 7. `clear`. 8. Start recorder — **OBS Studio** (free; Display/Window capture, 1080p30, mp4) or any OS recorder. 9. Type the command visibly, Enter, let output scroll; **pause 3 s on goals, GOLDEN GOAL, champion, claim lines** (output is fast — you will zoom in editing instead of pausing live; just leave it on screen 10 s at end). 10. For recording B: scroll the verified contract page on oklink.com, then the GitHub README slowly. 11. Stop. 12. Rename `raw-terminal.mp4`, `raw-explorer.mp4`; copy to a second location. 13. Scrub both for secrets/notifications before importing.

## 4. Editing — primary: **CapCut Desktop** (free); fallback: **DaVinci Resolve** (free)

1. New project → 16:9, 1080p, 30 fps. 2. Import: both recordings, all brand PNGs, `narration-v1.mp3`, music track. 3. Drop narration on audio track 1 — it is the master clock. 4. Lay visuals per storyboard timestamps; trim terminal recording: cut dead scrolling, keep the log lines listed above; use CapCut "zoom" keyframes (scale 100→160%) on each highlighted log line. 5. Text: CapCut Text → Space Grotesk (install from Google Fonts) → white #F4F7FB, appear/disappear with storyboard "On-screen text"; keep inside center 80% safe area. 6. Captions: import `captions.srt` (below) via Captions → Import; style: 60% width, bottom, dark bg 60% opacity. 7. SFX (CapCut library or pixabay.com, license CC0 — record source+license in `assets/audio/CREDITS.md`): whistle, crowd, UI ticks — max 3–4 total. 8. Music: one bed, "epic minimal sport tech" (CapCut commercial-safe library or pixabay CC0). Volume −22 dB under narration; use Auto-duck if available; music alone peaks −14 dB at open/close. 9. Transitions: only cuts, the two plate wipes (0.3 s), and fades at start/end. 10. End card 4–6 s with URL text. 11. Watch full-through muted (must still make sense), then with sound, then on phone-size preview. 12. Export: **1920×1080, 30 fps, H.264 MP4, AAC 48 kHz, bitrate 16 Mbps** → `mundial-demo-final.mp4`. 13. Loudness: if available run Auto-volume/normalize to ≈ −16 LUFS, true peak ≤ −1 dB (CapCut "Loudness normalization"; or `ffmpeg -i in.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:v copy out.mp4`). 14. Back up final + project file.

## 5. Captions file — save as `assets/video/captions.srt`

```
1
00:00:00,500 --> 00:00:05,000
What if a liquidity pool could play the World Cup?

2
00:00:05,200 --> 00:00:11,000
This is Mundial — a Uniswap V4 hook on X Layer.

3
00:00:11,000 --> 00:00:17,000
Other World Cup DeFi projects pick one match, trust an admin, or roll dice. Mundial runs the whole tournament — no one in charge.

4
00:00:17,200 --> 00:00:24,000
Fans pledge one of eight teams — once, irreversibly.

5
00:00:24,000 --> 00:00:32,000
During their team's match, every swap is a shot on goal. Volume scores goals.

6
00:00:32,200 --> 00:00:44,000
Argentina vs France: fans trade, goals go up — 5 to 3, Argentina advance.

7
00:00:44,000 --> 00:00:56,000
Brazil vs England: scoreless into extra time. Sudden death.

8
00:00:56,000 --> 00:01:04,000
One Brazilian fan swaps... GOLDEN GOAL. Settled inside the very swap that scored it.

9
00:01:04,000 --> 00:01:12,000
Semifinals, penalties by shot count, a final — a champion is crowned. All hook storage.

10
00:01:12,200 --> 00:01:21,000
One dynamic-fee pool. Fans pay less: 0.25%, and 0.15% while their team plays.

11
00:01:21,000 --> 00:01:30,000
A 0.20% skim builds the Champions Pot. Winners claim pro-rata; leftovers go to LPs.

12
00:01:30,200 --> 00:01:37,000
No owner. No oracle. No randomness. Only swaps and time.

13
00:01:37,000 --> 00:01:43,000
Even wash-trading a goal just funds the pot. 38 tests. Fuzzed. Verified on-chain.

14
00:01:43,200 --> 00:01:49,000
Mundial. Live on X Layer. The pool that plays the World Cup.
```

## 6. Thumbnail plan
`video-thumb.png` + overlay in editor: "THE POOL THAT PLAYS THE WORLD CUP" (Space Grotesk Bold, white, 3 lines, right 40%), small MUNDIAL badge top-left. Check readability at 320 px wide.

## 7. Upload & final review checklist
☐ Duration ≤ 120 s ☐ 1080p30 H.264 ☐ narration clear on laptop speakers ☐ captions synced ☐ no secrets/notifications visible in any frame ☐ behavior shown = real contract output ☐ music licensed (sources logged in CREDITS.md) ☐ plays start-to-finish on phone ☐ upload YouTube **Unlisted** → title "Mundial — the Uniswap v4 pool that plays the World Cup (X Layer)" → description = long description + disclaimer + repo link ☐ link opens in private window without login ☐ URL saved into SUBMISSION.md.
