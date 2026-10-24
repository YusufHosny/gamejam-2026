class_name AnimatedCutscene
extends Cutscene

# a cutscene laid out with nodes and keyframed on an AnimationPlayer. the animation named ANIMATION is the
# timeline, and follows Cutscene.time so skipping, restarting and pausing stay exact

const ANIMATION := &"cutscene"
const RESYNC_S := 0.1 # only seek after a jump, seeking every frame would restart audio tracks

@onready var _animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	assert(_animation.has_animation(ANIMATION), "%s needs an animation named '%s'" % [name, ANIMATION])
	var length := _animation.get_animation(ANIMATION).length
	assert(waits() or is_equal_approx(length, length_s), "%s animation is %.2f s but its step is %.2f s" % [name, length, length_s])
	_animation.play(ANIMATION)

func _process(delta: float) -> void:
	super(delta)
	if absf(_animation.current_animation_position - time) > RESYNC_S: _animation.seek(time, true)
