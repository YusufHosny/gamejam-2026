#!/usr/bin/env bash
# downloads the source audio for tools/music/process.py into $1 (default /tmp/claude-music/raw)
set -euo pipefail
out="${1:-/tmp/claude-music/raw}"
mkdir -p "$out"
declare -A sources=(
	[vivaldi_summer]=wVAq3CzHf9E # TomatoClassic, Four Seasons Summer III Presto
	[moonlight_3rd]=zucBfXpCA6s # Valentina Lisitsa, Moonlight Sonata III
	[ad_music]=3BFIxzQFrEs
	[glass]=dtG10azv6ag
	[drums]=YHh4QzYJKCM # 100 bpm drum beat
	[scream]=FgxoZ1qi4JM
)
for name in "${!sources[@]}"; do
	uvx yt-dlp -q --no-warnings -f bestaudio -x --audio-format wav -o "$out/$name.%(ext)s" "https://www.youtube.com/watch?v=${sources[$name]}"
done
