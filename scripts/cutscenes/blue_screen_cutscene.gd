class_name BlueScreenCutscene
extends AnimatedCutscene

# the ads overflow and the computer blue screens, then the scream stage starts.
# the timeline lives in the AnimationPlayer, the ad flood is drawn by BlueScreenFlood

@export var progress := 0: # keyframed, the percentage stalls then jumps like the real thing
	set(value):
		progress = value
		if is_node_ready(): _progress.text = "%d%% complete" % value

@onready var _progress: Label = %Progress
