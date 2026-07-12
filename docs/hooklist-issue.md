# Hooklist submission — pre-filled issue

**How to submit** (after contracts are deployed AND verified on the explorer):
Go to https://github.com/Uniswap/hooklist/issues/new/choose → **"Submit a Hook"** → fill exactly as below. Or approve and the agent runs `gh issue create --repo Uniswap/hooklist` with this content.

**Title**: `hook: MundialHook`

---

### Chain
xlayer

### Hook Address
<HOOK_ADDRESS — fill after deploy>

### Hook Name
MundialHook

### Description
Mundial turns one dynamic-fee Uniswap v4 pool on X Layer into a complete, autonomous 8-team knockout World Cup. Traders pledge one of eight teams (once, irreversibly). While their team's match is live, each swap is recorded as a shot and its volume accrues toward goals. Matches resolve by full-time lead, sudden-death golden goal (settled inside the scoring swap), penalties by shot count, then deterministic seeding — no admin, no oracle, no randomness. beforeSwap returns per-swap dynamic fee overrides (0.50% neutral / 0.25% fan / 0.15% live match / 0.10% golden-goal extra time); afterSwap + afterSwapReturnDelta skims 0.20% of fan swaps into a Champions Pot claimed pro-rata by champion-team fans, with unclaimed funds donated to LPs after 30 days. Source & tests: https://github.com/Tonyflam/2_okx

### Deployer Address
<DEPLOYER_ADDRESS — fill after deploy>

### Audit URL
_No response_ (unaudited hackathon build; threat model at https://github.com/Tonyflam/2_okx/blob/main/docs/SPEC.md)

---

**After creating the issue**: the registry bot fetches the **verified** source from the OKX explorer API and opens a PR automatically. Save the PR URL for the submission form. If the bot reports unverified source, complete explorer verification first (RUNBOOK Phase 3), then re-trigger.
