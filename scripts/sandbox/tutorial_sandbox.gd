extends Node

# F6 to play one tutorial map alone

const RUN_SCENE := preload("res://scenes/run.tscn")

@export_enum("login", "phone", "email") var map_name := "login"

func _ready() -> void:
	var steps: Array[RunStep] = [MapStep.new(_map(), false)]
	var player: RunPlayer = RUN_SCENE.instantiate()
	player.run = Run.new(steps)
	player.finished.connect(func(_r: RunResult): get_tree().quit())
	player.exited.connect(get_tree().quit)
	add_child(player)

func _map() -> Map:
	match map_name:
		"phone": return TutorialMaps.phone()
		"email": return TutorialMaps.email()
		_: return TutorialMaps.login()
