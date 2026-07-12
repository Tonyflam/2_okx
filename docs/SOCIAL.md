# Mundial — X Account & Social Launch Pack

**Rules baked in**: professional, confident, zero desperation; no attacks on competitors; no guaranteed-victory or return promises; no encouragement of wash trading, self-trading, Sybil, fake engagement, or artificial volume; disclose that trading involves risk.

## Account setup

- Handle options (try in order): **@MundialHook** → **@MundialXLayer** → **@PlayMundial**
- Display name: `Mundial ⚽`
- Bio (≤160): `⚽ The Uniswap v4 pool that plays the World Cup — live on @XLayerOfficial. Swaps are shots. Goals win matches. No admin, no oracle. Not affiliated with FIFA.`
- Website: `https://github.com/Tonyflam/2_okx`
- Location: `X Layer · chain 196`
- Profile image: `assets/brand/x-avatar.png` · Banner: `assets/brand/x-banner.png` (crop 1500×500)

## Post 1 — REQUIRED launch post (pin it; tags @XLayerOfficial; publish only after deploy)

> ⚽ Kickoff. Mundial is live on @XLayerOfficial.
>
> One Uniswap v4 pool. Eight teams. A full knockout World Cup that plays itself:
> swaps are shots → volume scores goals → golden goals settle mid-swap → champion fans claim the pot.
>
> No admin. No oracle. No randomness.
>
> 🏟 Hook: `<HOOK_ADDR>`
> 📜 Code: github.com/Tonyflam/2_okx
> #HookTheWorldCup #XLayer #UniswapV4
>
> Not affiliated with FIFA. Trading involves risk.

*(Attach: banner image or demo clip. Save the post URL — required in the submission form.)*

## Launch thread (reply chain under Post 1)

1. "How it works, in 60 seconds 🧵 Pick one of 8 teams — once, irreversibly. From then on you're a fan on-chain."
2. "When YOUR team plays, your swaps become shots. Every 1.0 of volume = a goal. The market literally plays the match."
3. "Draw at full time? Sudden death. The first goal in extra time — the golden goal — settles the match *inside the swap that scores it*. Same transaction."
4. "Still level? Penalties: most shots (swap count) wins. Total deadlock? Lower seed advances. Every path is deterministic — no dice anywhere."
5. "Fans trade cheaper: 0.50% for neutrals → 0.25% for fans → 0.15% during your match. A 0.20% skim on fan swaps fills the Champions Pot 🏆"
6. "Win the tournament and claim your share, pro-rata to the volume you traded. Unclaimed after 30 days? Donated to LPs. Nothing gets stuck."
7. "Security: no owner, no oracle, no upgrade keys. 77 passing tests incl. fuzz. Verified source on the explorer. Read it yourself: github.com/Tonyflam/2_okx"

## 10-post competition calendar

| # | When | Content |
|---|---|---|
| 1 | Launch | Post 1 above |
| 2 | +1 h | Launch thread (1–7) |
| 3 | Kickoff −30 min | "⏰ QF1 kicks off at <T> UTC: 🇦🇷 vs 🇫🇷. Fans of playing teams pay 0.15%. Choose your side (once — it's forever): <pool link>" |
| 4 | During QF1 | Live score screenshot from explorer/state view: "LIVE: goals ARG <x> – FRA <y>. Every number is hook storage." |
| 5 | Post-QF1 | "FULL TIME. <team> advance. Settlement tx: <link> — no admin pressed any button." |
| 6 | Golden-goal moment (whenever it first happens) | "⚡ GOLDEN GOAL. Match settled inside the scoring swap: <tx link>. This is what 'trading is the game' means." |
| 7 | Tech deep-dive | "Under the hood 🧵: beforeSwap fee override, afterSwapReturnDelta pot skim, donate() fallback, CREATE2-mined flag address. For the hook-curious: <repo link>" |
| 8 | Security post | "Why you can trust a tournament with no referee: immutable params, CEI everywhere, bounded loops, claim-conservation fuzz proofs. Threat model in the repo: <link>" |
| 9 | Semis/Final | Bracket graphic (bg-bracket.png + names): "The final four. Next kickoff <T> UTC." |
| 10 | Champion | "🏆 CHAMPIONS. <team> fans can now claim() their share of the Champions Pot: <pot amount>. Leftovers after 30 days go to LPs. Thank you @XLayerOfficial — the beautiful game, fully on-chain." |

## Standalone posts (use as fits)
- **Demo video post**: "2 minutes. One pool. A whole World Cup. Watch Mundial run end-to-end: <video link>" (attach video natively too).
- **Champions Pot post**: visual-pot.png + "The pot isn't sponsored. It's skimmed — 0.20% of every fan swap. You're playing for your own collective volume."
- **Final CTA (submission day)**: "Built in the open for #HookTheWorldCup. Code, tests, threat model, live pool — all public. Verdict's with the judges now 🤝"

## Reply strategy
Reply to technical questions with code links, not vibes; concede unknowns honestly; never argue with other teams — congratulate good work; redirect "wen token/price" questions to the disclaimer; report/ignore bait.
