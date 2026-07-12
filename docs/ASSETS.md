# Mundial Image Asset Prompt Pack — Nano Banana Pro

**Model** (verified 2026-07-12 on ai.google.dev): **Nano Banana Pro = `gemini-3-pro-image`** — professional asset production, best text rendering, 1K/2K/4K output, "thinking" composition. Access: Gemini app (Pro), Google AI Studio (free tier available), or API. Alternative for fast drafts: `gemini-3.1-flash-image` (Nano Banana 2).

**How to generate**: aistudio.google.com → new prompt → model `gemini-3-pro-image` → paste Master Prompt → set aspect ratio & size per asset → download PNG into `assets/brand/` using the file name given. All output includes an invisible SynthID watermark (fine for our use).

**Global style block — prepend to EVERY prompt** (keeps the family consistent):

> STYLE: Premium sports-tech brand artwork. Deep navy night-stadium background (#0A1220), electric pitch-green (#00E676) light trails, champions-gold (#FFC533) accents, crisp white highlights. Abstract football-pitch geometry (center circle, halfway line) merged with glowing blockchain-node networks and flowing liquidity light streams. Tournament-bracket line motifs. Cinematic rim lighting, subtle volumetric haze, high contrast, ultra-clean vector-influenced 3D render. NO text, NO letters, NO numbers, NO logos, NO trophies resembling the FIFA World Cup trophy, NO real players, NO faces, NO flags, NO watermarks.

**Global negative prompt** (Nano Banana takes plain-language avoidance — append as final sentence):

> Avoid: any text or typography, official trophy shapes, FIFA imagery, club or federation crests, sponsor logos, human faces, celebrity likeness, country flags, cartoonish style, clutter, low contrast, JPEG artifacts.

Rule: **generated images contain no words** — all text is overlaid manually in editing (prevents AI spelling errors).

---

| # | Asset | File name | Size / AR | Purpose & placement |
|---|---|---|---|---|
| 1 | Primary logo | `logo-primary.png` | 1:1, 2K | README, watermark, avatar source |
| 2 | App icon | `icon-simple.png` | 1:1, 1K | favicons, small UI |
| 3 | X profile image | `x-avatar.png` | 1:1, 1K | X account |
| 4 | X banner | `x-banner.png` | 3:1 (use 16:9 2K, crop to 1500×500) | X header |
| 5 | Repo hero | `hero-repo.png` | 16:9, 2K | README top |
| 6 | Video thumbnail | `video-thumb.png` | 16:9, 2K | YouTube/X card |
| 7 | Title card | `video-title.png` | 16:9, 2K | video 0:00 |
| 8 | Bracket background | `bg-bracket.png` | 16:9, 2K | video sections |
| 9 | Architecture background | `bg-architecture.png` | 16:9, 2K | tech section |
| 10 | Team emblems ×8 | `team-01…08.png` | 1:1, 1K | bracket graphics, posts |
| 11 | Champions Pot | `visual-pot.png` | 16:9, 2K | pot explainer |
| 12 | Golden Goal | `visual-goldengoal.png` | 16:9, 2K | golden-goal post/scene |
| 13 | Penalty shootout | `visual-penalties.png` | 16:9, 2K | penalties scene |
| 14 | Transition plates ×2 | `plate-a.png`, `plate-b.png` | 16:9, 2K | video transitions |
| 15 | CTA end card | `video-endcard.png` | 16:9, 2K | video final 4s |

### Per-asset master prompts

**1. Primary logo** — `[GLOBAL STYLE] +` "A single emblem centered on a plain deep-navy background: a hexagonal badge formed of thin glowing green lines, containing an abstract football constructed from four bracket-shaped chevrons converging on one radiant gold node at the center. Flat vector-style with a subtle 3D glass depth. Generous empty margin on all sides. Perfectly symmetrical." *Transparency: regenerate on white if needed; text-safe area: none needed. QC: recognizable at 48px, symmetric, no stray marks.*

**2. App icon** — same as #1 plus: "Simplify to the minimum: badge outline, chevron football, gold center node only. Thicker strokes for small-size legibility." *QC: readable at 32px.*

**3. X avatar** — same as #2 plus: "Slightly zoomed so the badge fills 85% of frame." *QC: circle-crop safe (nothing essential in corners).*

**4. X banner** — `[GLOBAL STYLE] +` "Ultra-wide panoramic night-stadium bowl seen from the pitch center circle, rendered as glowing wireframe geometry. A luminous tournament bracket spans the sky like constellation lines, converging at a radiant gold node above the horizon. Green liquidity light-streams curve along the pitch lines toward the viewer. Left third intentionally darker and emptier." *Safe area: keep left 40% low-detail for handle/text overlay; center-bottom 25% clear (X crops). QC: focal point off-center-right, no busy noise behind future text.*

**5. Repo hero** — `[GLOBAL STYLE] +` "Wide cinematic composition: a glowing football-pitch grid dissolving into a blockchain node network toward the horizon; a single gold-lit hexagonal badge hovers above the center circle emitting soft light. Dark vignette corners. Bottom third clean and dark for headline overlay." *Safe area: bottom 30%.*

**6. Video thumbnail** — `[GLOBAL STYLE] +` "Dramatic low-angle view of a glowing green football on a wireframe pitch at the moment before a strike, motion energy trails behind it, a giant luminous bracket structure in the night sky, gold light bursting from the horizon. Extreme contrast, poster-like." *Safe area: right 40% clear for 3-word title overlay. QC: reads at 320px wide.*

**7. Title card** — like #5 but "more symmetrical, calmer, centered stage lighting like a stadium at kickoff; center 50% almost empty for the wordmark." *Safe area: center.*

**8. Bracket background** — `[GLOBAL STYLE] +` "A clean horizontal single-elimination tournament bracket of 8 slots drawn as glowing green glass lines over the dark pitch grid, converging left-to-right to one gold final node. Even spacing, minimal decoration, deliberately empty slot rectangles." *Safe area: inside every slot rectangle (team names added in editor).*

**9. Architecture background** — `[GLOBAL STYLE] +` "Abstract technical diagram atmosphere: three softly glowing rounded rectangles connected by animated-looking light conduits over the pitch grid, one green, one gold, one white, arranged in a triangle with generous empty space. No icons, no text." *Safe area: inside rectangles and center.*

**10. Team emblems (8 runs, vary the descriptor)** — `[GLOBAL STYLE] +` "A minimal abstract team crest: a shield-less geometric mark made of [descriptor] in glowing green and gold line-art on deep navy. No letters, no animals from real crests, no flags." Descriptors: 1 "two interlocking suns" · 2 "a rising hexagonal rooster-comb wave" · 3 "five orbiting stars in a circle" · 4 "three parallel lions'-claw slashes" · 5 "a radiant diamond over a bar" · 6 "four stacked chevrons" · 7 "a compass rose of arrows" · 8 "a tulip-shaped flame". *QC: sibling-consistent stroke weight; distinct silhouettes.*

**11. Champions Pot** — `[GLOBAL STYLE] +` "A floating translucent vault-sphere of golden light above the center circle, fed by dozens of thin green liquidity streams arriving from all directions along the pitch lines; small gold particles orbit it. Sense of accumulation and reward." *Safe area: top 20%.*

**12. Golden Goal** — `[GLOBAL STYLE] +` "A single explosive moment: one green energy-football crossing a glowing goal-line plane that shatters into golden light shards, time-frozen, radial gold burst, amber (#FF9E1B) accents only in this artwork. Maximum drama." *Safe area: bottom 25%.*

**13. Penalty shootout** — `[GLOBAL STYLE] +` "Tension composition: a glowing penalty spot and goal frame in wireframe, five faint shot-trajectory arcs of green light toward the goal, one gold arc among them; scoreboard-like empty rectangles floating above." *Safe area: the empty rectangles.*

**14. Transition plates A/B** — `[GLOBAL STYLE] +` A: "Almost-black minimal frame, single green bracket line sweeping diagonally with light trail." B: same "with gold line sweeping opposite diagonal." *Purpose: 8-frame wipe transitions.*

**15. CTA end card** — like #7 but "with the gold node brighter, celebratory light rays, and confetti-like green/gold particles frozen mid-air; center 60% empty." *Safe area: center (URL + handle overlaid).*

### Export & manifest
- Export: PNG, sRGB. Keep the 2K originals; downscale copies for web (banner → 1500×500 crop, avatar → 400×400).
- After generation, save to `assets/brand/` and update `assets/brand/MANIFEST.md` with: file, prompt #, model, date, chosen-vs-rejected, alt text (use the per-asset purpose line as alt text).

### QC scoring rubric (score each 1–5, keep ≥4 average)
Brand consistency · legibility at small size · World Cup relevance · technical relevance · originality · professionalism · trademark safety (any official-mark resemblance = automatic reject).

**Recommendation**: generate #1–#7 first (blocking for X account + video); #10's eight emblems are nice-to-have — skip if under 3 h remain.
