# Final Submission Answer Sheet — Hook × World Cup

**Form location**: campaign page → "Submit project" button → Google Form (exact form URL is client-side rendered on https://web3.okx.com/xlayer/build-x-hackathon/hooktheworldcup — resolve on first open; verify the form title mentions Hook × World Cup before filling. STATUS: page shows campaign **Online** as of 05:40 UTC Jul 12).

**Rule**: fill only rows marked ✅ Verified. Rows marked ⏳ get real values during RUNBOOK Phases 2–7. Never submit with a ⏳ remaining.

| Field (typical) | Answer | Chars | Status |
|---|---|---|---|
| Project name | Mundial | 7 | ✅ |
| One-line description | The Uniswap v4 pool that plays the World Cup: an autonomous 8-team knockout tournament where swaps are shots, volume scores goals, and champion fans claim the pot. | 165 | ✅ |
| Project description | Use the 100-word pitch from [PITCH.md](PITCH.md). | ~640 | ✅ |
| Chain | X Layer Mainnet (chainId 196) | — | ✅ |
| Hook contract address | `0x51f3d18a574c1deec5c04d395573cda9248dd0c4` | — | ✅ deployed |
| Token contract address | `0xfb8fb4cf5f92256c52a638f46f8ecc2525303d6f` | — | ✅ deployed |
| Pool ID | `0x0cc28818a207ae3c182a88dbe9677203859f916116711a19c9b010bf390bbeda` | — | ✅ initialized |
| Explorer link | `https://www.oklink.com/x-layer/address/0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4` (deployed; source verification pending) | — | ✅ opens |
| GitHub repository | https://github.com/Tonyflam/2_okx | — | ✅ public |
| Hooklist PR/issue URL | https://github.com/Uniswap/hooklist/pull/1062 | — | ✅ filed |
| Project X account | `<@handle>` | — | ⏳ Phase 6 |
| Launch post URL (tags @XLayerOfficial) | `<POST_URL>` | — | ⏳ Phase 6 |
| Demo video URL | https://youtu.be/Jk3e9K3U0bg (YouTube unlisted; test in private window) | — | ✅ uploaded |
| Team / contact | your name + email/TG (your choice — not stored in repo) | — | ⏳ human |
| Wallet for prizes | your address (NOT the throwaway deployer unless you intend it) | — | ⏳ human |
| How it uses Uniswap v4 | beforeSwap dynamic-fee overrides per game state; afterSwap + afterSwapReturnDelta pot skim and shot recording; afterInitialize single-pool binding; donate() LP fallback via unlock callback; CREATE2-mined permission address. | 240 | ✅ |
| What makes it creative | The World Cup is the mechanism, not the skin: bracket scheduling creates timed demand windows, golden goals settle inside the scoring swap, penalties count swaps — the entire tournament state machine lives in hook storage with no admin, oracle, or randomness. | 260 | ✅ |

## Pre-submit validation checklist (do WITH the agent)
1. ☐ Every ⏳ replaced with a real value; grep the sheet for `<` finds nothing.
2. ☐ All URLs open logged-out (private window): explorer shows the deployed contract; repo shows README; post is public; video plays.
3. ☐ Addresses cross-checked against [deployments/xlayer.json](../deployments/xlayer.json) (agent diff).
4. ☐ Screenshot of the filled form BEFORE submitting.
5. ☐ Submit by **22:30 UTC** target (hard 23:59 UTC). Screenshot the confirmation.
