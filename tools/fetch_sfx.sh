#!/usr/bin/env bash
# Downloads Kenney's CC0 sound packs into a temp dir and copies the sounds the cutscenes use into assets/sfx/<name>.ogg.
# To swap a sound, change its line in SOUNDS and rerun. whoosh, whoosh_low and charge aren't here, SfxUtils makes them.
# usage: tools/fetch_sfx.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PACKS=(interface-sounds ui-audio impact-sounds sci-fi-sounds rpg-audio)
declare -A SOUNDS=( # our name -> pack/file in the pack's Audio folder
	[click]=ui-audio/mouseclick1.ogg
	[key]=ui-audio/click3.ogg
	[tap]=interface-sounds/select_001.ogg
	[pop]=interface-sounds/maximize_006.ogg
	[swipe]=rpg-audio/cloth3.ogg
	[peel]=rpg-audio/cloth1.ogg
	[success]=interface-sounds/confirmation_002.ogg
	[fanfare]=interface-sounds/confirmation_004.ogg
	[error]=interface-sounds/error_008.ogg
	[question]=interface-sounds/question_001.ogg
	[glitch]=interface-sounds/glitch_002.ogg
	[crash]=impact-sounds/impactPunch_heavy_000.ogg
	[boom]=sci-fi-sounds/lowFrequency_explosion_001.ogg
	[explosion]=sci-fi-sounds/explosionCrunch_000.ogg
	[startup]=interface-sounds/confirmation_001.ogg
	[sting]=impact-sounds/impactBell_heavy_000.ogg
)

tmp=$(mktemp -d)
trap 'chmod -R u+w "$tmp"; rm -rf "$tmp"' EXIT # some packs unzip read only
for pack in "${PACKS[@]}"; do
	url=$(curl -sL --max-time 30 "https://kenney.nl/assets/$pack" | grep -oE 'https://kenney\.nl/media/pages/assets/[^"]+\.zip' | head -1)
	[ -n "$url" ] || { echo "no download link for $pack" >&2; exit 1; }
	curl -sL --max-time 300 -o "$tmp/$pack.zip" "$url"
	unzip -q -o "$tmp/$pack.zip" -d "$tmp/$pack"
done

mkdir -p assets/sfx
for name in "${!SOUNDS[@]}"; do
	source=${SOUNDS[$name]}
	cp "$tmp/${source%%/*}/Audio/${source#*/}" "assets/sfx/$name.ogg"
done
cp "$tmp/interface-sounds/License.txt" assets/sfx/LICENSE.txt
echo "copied ${#SOUNDS[@]} sounds into assets/sfx"
