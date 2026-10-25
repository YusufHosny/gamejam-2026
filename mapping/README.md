# Mapping takes

Recorded with `scenes/sandbox/mapping_recorder.tscn` (F6). Each json is one take: inputs with map time, beat, half and quarter beat snaps, position, and for holds the slider path and length. `TakeMaps.fill(segment, TakeMaps.load_take(path))` turns one into notes.

S slows the song to 0.75x or 0.5x (pitch kept). Takes stay in song time, so slow takes line up with the 1x grid.

Plan: hard maps come from Yusuf's takes (often rhythm only, plus notes on shapes: squares, triangles, stars, jumps). Aim is placed from those notes, and the easy maps are thinned out from the hard ones.
