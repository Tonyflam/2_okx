# Mundial Voice-Over Guide — ElevenLabs

Facts verified 2026-07-12 on elevenlabs.io/docs: TTS credits = **1 credit/character**; models: **`eleven_v3`** (most expressive, 70+ langs, 5k char limit, supports audio tags), **`eleven_multilingual_v2`** (most stable long-form, 29 langs, 10k chars), **`eleven_flash_v2_5`** (fast/cheap). Voice IDs are account-visible in the Voice Library (10,000+ voices) — names below are from the default/library set; **confirm the ID in your own dashboard before generating** (Voices → voice card → copy ID).

Our narration is ~1,550 characters → ~1,550 credits per take. The free tier (10k credits/mo) covers ~6 takes. **Do not buy a plan or spend credits without approval. Do not clone any voice.**

## Target sound
Premium sports-documentary narrator: confident not arrogant, energetic not shouting, warm, globally understandable, credible on technical vocabulary, memorable within 5 seconds. No celebrity imitation.

## Candidates (default/library voices — verify availability in your dashboard)

| Voice | Why it fits | Accent/tone | Risk |
|---|---|---|---|
| **1. Brian** (default library; deep male narrator) | classic documentary gravitas, steady pace, excellent on technical words | American, deep, warm | can feel slow — raise style/speed slightly |
| **2. George** (default library; warm British storyteller) | "world football" broadcast feel, international credibility | British RP, warm | slightly soft for hype moments |
| **3. Antoni** (default library; well-rounded male) | modern, energetic, product-launch energy | American, mid-deep | less "sports epic" |

**Final recommendation: George** — British warmth reads as world-football broadcasting to an international judging panel, and it handles "Mundial" naturally. **Backup: Brian.**

## Settings (Text-to-Speech dashboard)

- Model: **`eleven_multilingual_v2`** for the final take (most stable long-form). Use `eleven_v3` only if you want the audio-tag emotion control and are happy to iterate.
- Stability: **45** (expressive but controlled)
- Similarity: **75**
- Style: **35** (documentary lift without shouting)
- Speaker boost: **on**
- Speed: **1.0** (script is timed for natural pace; do not exceed 1.05)

## 15-second audition script (~160 chars — cheap to test all 3 voices)

> "Mundial. The pool that plays the World Cup. Eight teams. One Uniswap v4 hook on X Layer. Every swap is a shot on goal. No admin. No oracle. Just football, on-chain."

## Pronunciation dictionary

| Term | Guide / substitution if mispronounced |
|---|---|
| Mundial | "moon-dee-AHL" — if flattened, write `Moondiahl` |
| Uniswap V4 | "YOU-nee-swap vee-four" — write `Uniswap V-four` |
| Hook | natural |
| X Layer | "EX-layer" — write `X-Layer` with hyphen |
| on-chain | "on CHAIN" — keep hyphen |
| liquidity | natural |
| Champions Pot | equal stress: `Champions. Pot.` if rushed |
| trustless | "TRUST-less" |
| penalty shootout | natural |
| Solidity | "so-LID-it-ee" |
| OKB | "oh-kay-BEE" — write `O K B` |

## Comparison rubric (pick highest total; 1–5 each)
Clarity of technical terms · warmth · energy at "GOLDEN GOAL" line · gravitas at closing line · overall memorability.

## Workflow
1. Log in at elevenlabs.io (HUMAN LOGIN). 2. Voices → search each candidate → copy real voice ID. 3. Text-to-Speech → paste audition script → generate for all 3 (≈480 credits total). 4. Score with rubric; pick winner. 5. Paste the final narration from [VIDEO.md](VIDEO.md) → generate 1–2 takes → download MP3 as `assets/audio/narration-v1.mp3`. 6. **Stop before any paid action.**

Fallback (zero cost, fully acceptable): record your own voice with the same script — judges score the project, not the narrator.
