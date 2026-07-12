#!/usr/bin/env bash
# Mundial — contract verification helper for OKLink/OKX explorer (X Layer, chain 196).
# Usage: ./scripts/verify-contracts.sh <TOKEN_ADDR> <HOOK_ADDR> <DEPLOYER_ADDR> <KICKOFF> [OKLINK_API_KEY]
# Safe: read-only against the chain; only submits source code text to the explorer.
set -euo pipefail
cd "$(dirname "$0")/.."

TOKEN=${1:?token address}
HOOK=${2:?hook address}
DEPLOYER=${3:?deployer address}
KICKOFF=${4:?kickoff unix ts}
API_KEY=${5:-}

FORGE=~/.foundry/bin/forge
CAST=~/.foundry/bin/cast
POOL_MANAGER=0x360e68faccca8ca495c1b759fd9eee466db9fb32
SUPPLY=100000000000000000000000000

# Constructor args (must mirror script/DeployMundial.s.sol defaults)
TOKEN_ARGS=$($CAST abi-encode "constructor(address,uint256)" "$DEPLOYER" "$SUPPLY")
TEAMS='[0x417267656e74696e610000000000000000000000000000000000000000000000,0x4672616e63650000000000000000000000000000000000000000000000000000,0x4272617a696c0000000000000000000000000000000000000000000000000000,0x456e676c616e6400000000000000000000000000000000000000000000000000,0x537061696e000000000000000000000000000000000000000000000000000000,0x4765726d616e7900000000000000000000000000000000000000000000000000,0x506f727475676100000000000000000000000000000000000000000000000000,0x4e65746865726c616e6473000000000000000000000000000000000000000000]'
HOOK_ARGS=$($CAST abi-encode "constructor(address,bytes32[8],uint64,uint64,uint64,uint64,uint256)" \
  "$POOL_MANAGER" "$TEAMS" "$KICKOFF" 28800 3600 10800 1000000000000000000)

echo "== Token constructor args =="; echo "$TOKEN_ARGS"
echo "== Hook constructor args ==";  echo "$HOOK_ARGS"

mkdir -p verify
$FORGE verify-contract "$TOKEN" src/MundialToken.sol:MundialToken \
  --constructor-args "$TOKEN_ARGS" --show-standard-json-input > verify/token-standard.json
$FORGE verify-contract "$HOOK" src/MundialHook.sol:MundialHook \
  --constructor-args "$HOOK_ARGS" --show-standard-json-input > verify/hook-standard.json
echo "Standard-JSON written to verify/token-standard.json and verify/hook-standard.json"
echo "Manual path: https://www.oklink.com/x-layer -> contract page -> Verify (Standard JSON, solc 0.8.26, optimizer 800, evm cancun)."

if [[ -n "$API_KEY" ]]; then
  echo "== Attempting API verification via OKLink etherscan-compatible endpoint =="
  for c in "MundialToken:$TOKEN:$TOKEN_ARGS:src/MundialToken.sol:MundialToken" ; do :; done
  $FORGE verify-contract "$TOKEN" src/MundialToken.sol:MundialToken \
    --constructor-args "$TOKEN_ARGS" \
    --verifier oklink \
    --verifier-url "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/XLAYER" \
    --api-key "$API_KEY" --watch || echo "API verify failed for token — use manual path."
  $FORGE verify-contract "$HOOK" src/MundialHook.sol:MundialHook \
    --constructor-args "$HOOK_ARGS" \
    --verifier oklink \
    --verifier-url "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/XLAYER" \
    --api-key "$API_KEY" --watch || echo "API verify failed for hook — use manual path."
fi
