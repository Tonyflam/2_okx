#!/usr/bin/env bash
# Mundial — one-command video build.
#   ./script/build_demo_video.sh          -> review render (silent if narration missing)
#   ./script/build_demo_video.sh --final  -> final render (requires narration audio)
set -euo pipefail
cd "$(dirname "$0")/.."
python3 script/build_video_assets.py
python3 script/build_demo_video.py "$@"
