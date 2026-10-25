extends Node

# temporary: the whole run from the intro, autoplayed
func _ready() -> void:
	GameConfig.difficulty = Difficulty.Level.AUTOPLAY
	var sandbox: Node = load("res://scenes/sandbox/stage_sandbox.tscn").instantiate()
	sandbox.start_step = 0
	add_child(sandbox)
