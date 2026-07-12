# Mundial Brand System

Central idea: **"The World Cup tournament played by swaps."**

## Core identity

- **Name presentation**: **MUNDIAL** (all-caps wordmark) / "Mundial" in prose. Never "MundialHook" in consumer-facing copy (that is the contract name).
- **Tagline**: *The pool that plays the World Cup.*
- **One-sentence pitch**: Mundial is a Uniswap v4 hook on X Layer that turns a single liquidity pool into a complete on-chain knockout tournament — swaps are shots, volume scores goals, and champion fans claim the pot.
- **Short description** (~160 chars): A Uniswap v4 hook that runs an entire 8-team World Cup inside one pool. Swaps are shots. Goals win matches. No admin, no oracle, no randomness.
- **Long description**: Mundial turns one dynamic-fee Uniswap v4 pool on X Layer into a self-running knockout World Cup. Traders pledge one of eight teams; while their team's match is live, every swap is a shot on goal and its volume accrues toward goals. Matches resolve by lead at full time, golden goal in sudden-death extra time, penalties by shot count, and deterministic seeding as last resort. The bracket — quarterfinals to final — lives entirely in hook storage. A 0.20% skim on fan swaps builds a Champions Pot that winning-team fans claim pro-rata to their traded volume; leftovers are donated to LPs after a 30-day window. There is no owner, no oracle, and no randomness: the tournament's only inputs are swaps and time.

## Color palette

| Role | Name | Hex | Usage |
|---|---|---|---|
| Primary background | Stadium Night | `#0A1220` | backgrounds, banner base |
| Primary accent | Pitch Green | `#00E676` | goals, CTAs, live states |
| Secondary accent | Champions Gold | `#FFC533` | pot, trophies, winner states |
| Text on dark | Floodlight White | `#F4F7FB` | headlines, body on dark |
| Supporting | Midfield Slate | `#26344A` | cards, dividers |
| Alert/live | Golden Goal Amber | `#FF9E1B` | golden-goal moments only |

Contrast (WCAG): Floodlight White on Stadium Night ≈ 16.9:1 (AAA); Pitch Green on Stadium Night ≈ 10.5:1 (AAA, large or bold text); Champions Gold on Stadium Night ≈ 11.4:1. Never place Pitch Green text on Champions Gold.

## Typography

- **Headlines**: Space Grotesk (Google Fonts, free) — geometric, technical, sporty.
- **Body/UI**: Inter — neutral, highly legible.
- **Code/terminal**: JetBrains Mono.
- Minimum body size 16px; headline tracking slightly tight (-1%); no condensed fonts below 14px.

## Logo & icon system

- **Logo concept**: a hexagonal "node" badge (blockchain node + stadium crest hybrid) containing an abstract football built from bracket lines — four chevrons converging to a center point (the final). Pitch Green lines on Stadium Night, one Champions Gold node at the convergence point.
- **App icon**: the badge alone, no wordmark, readable at 48×48.
- **Bracket motif**: horizontal single-elimination bracket lines used as a recurring graphic device (backgrounds, dividers, banner).
- **Pitch/grid language**: subtle center-circle + halfway-line geometry as background texture, blended with faint liquidity-flow trails.

## Voice & tone

- Confident, precise, sporting. Short sentences. Present tense.
- Football metaphors backed by literal mechanics ("a swap *is* a shot" — because the contract records it as one).
- Never hype without proof; every claim links to code, a tx, or a test.

**Correct**: "Golden goals settle the match inside the swap that scores them."
**Incorrect**: "The most revolutionary DeFi experience ever!!!" / "guaranteed win" / "🚀🚀🚀"

## Usage rules

Do: keep the badge on dark backgrounds; keep clear space equal to the badge's stroke width; use flags only as unicode emoji in social copy.
Don't: copy FIFA/World Cup emblems or trophy silhouettes; use federation/club crests; use sponsor logos; imply endorsement by FIFA, Uniswap, OKX, or X Layer; use official match footage or player likenesses.

## Disclaimer language (append to bio/README/video description)

> Mundial is an independent project built for the Hook × World Cup campaign on X Layer. It is not affiliated with or endorsed by FIFA, any football federation, Uniswap Labs, OKX, or X Layer. Not financial advice; participation involves risk of loss.

## Social profile bio (≤160 chars)

> ⚽ The Uniswap v4 pool that plays the World Cup — live on @XLayerOfficial. Swaps are shots. Goals win matches. No admin, no oracle. Not affiliated with FIFA.

## Repository hero copy

> **MUNDIAL** — *The pool that plays the World Cup.*
> An 8-team knockout tournament living inside one Uniswap v4 pool. Trading is the game.
