@abstract
class_name ModeView
extends Node2D

# a segment's visuals over one mode's logic, like an osu skin + map + bg.
# polls the mode each frame and never judges or mutates notes

var mode: ModeHandler # bound by ModeHandler.begin before entering the tree

func _process(_delta: float) -> void: queue_redraw()

func _now() -> float: return mode.conductor.song_time()
