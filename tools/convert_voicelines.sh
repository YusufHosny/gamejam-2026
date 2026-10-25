#!/usr/bin/env bash
# Converts the voice line recordings (.m4a, which Godot can't import) to Ogg Vorbis under assets/voicelines/<lang>/<id>.ogg.
# Uses the ffmpeg inside the Godot flatpak, since the host may not have one. Normalized to LOUDNESS so every line is
# as loud as the next and they sit over the music and the tutorial's metronome.
# usage: tools/convert_voicelines.sh
set -euo pipefail
cd "$(dirname "$0")/../assets/voicelines"
FFMPEG=(flatpak run --command=ffmpeg org.godotengine.Godot)
LOUDNESS="acompressor=threshold=-24dB:ratio=4:attack=5:release=120:makeup=2,loudnorm=I=-16:TP=-1.5:LRA=7" # tames the peaks first, then integrated loudness in LUFS and true peak in dB

declare -A IDS=(
	["Additional lines v2 1"]=intro_1
	["Additional lines v2 2"]=intro_2
	["Additional lines v2 3"]=intro_3
	["Additional lines v2 4"]=intro_4
	["Additional lines v2 5"]=seriously
	["Additional lines v2 6"]=ugh
	["Additional lines v2 7"]=oops
	["Tutorial 1"]=tutorial_1
	["Tutorial 2"]=tutorial_2
	["Tutorial 3"]=tutorial_3
	["Tutorial 4"]=tutorial_4
	["Email app opens"]=email_open
	["You sign in 1"]=sign_in_1
	["You sign in 2"]=sign_in_2
	["Shady submit button 1"]=virus_1
	["Shady submit button 2"]=virus_2
	["Ad overflow 1"]=ads_1
	["Ad overflow 2"]=ads_2
	["Submit button dodge 1"]=dodge_1
	["Submit button dodge 2"]=dodge_2
	["Submitted at 0"]=win
)

for lang in EN FR; do
	out=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
	mkdir -p "$out"
	for name in "${!IDS[@]}"; do
		"${FFMPEG[@]}" -hide_banner -loglevel error -y -i "$lang $name.m4a" -af "$LOUDNESS" -ar 48000 -c:a libvorbis -q:a 5 "$out/${IDS[$name]}.ogg"
	done
done
echo "converted $(ls en/*.ogg fr/*.ogg | wc -l) files"
