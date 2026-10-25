class_name Sfx
extends RefCounted

# the cutscenes' sound effects by name. the files are Kenney's CC0 packs, picked and renamed by tools/fetch_sfx.sh,
# the whooshes and the build up are made by SfxUtils since the packs have nothing like them

const FILES := {
	&"click": preload("res://assets/sfx/click.ogg"),
	&"key": preload("res://assets/sfx/key.ogg"),
	&"tap": preload("res://assets/sfx/tap.ogg"),
	&"pop": preload("res://assets/sfx/pop.ogg"),
	&"swipe": preload("res://assets/sfx/swipe.ogg"),
	&"peel": preload("res://assets/sfx/peel.ogg"),
	&"success": preload("res://assets/sfx/success.ogg"),
	&"fanfare": preload("res://assets/sfx/fanfare.ogg"),
	&"error": preload("res://assets/sfx/error.ogg"),
	&"question": preload("res://assets/sfx/question.ogg"),
	&"glitch": preload("res://assets/sfx/glitch.ogg"),
	&"crash": preload("res://assets/sfx/crash.ogg"),
	&"boom": preload("res://assets/sfx/boom.ogg"),
	&"explosion": preload("res://assets/sfx/explosion.ogg"),
	&"startup": preload("res://assets/sfx/startup.ogg"),
	&"sting": preload("res://assets/sfx/sting.ogg"),
}
const VOLUME_DB := { # anything not listed plays at 0 dB
	&"key": -6.0,
	&"pop": -4.0,
	&"glitch": -8.0,
	&"error": -6.0,
	&"whoosh": -3.0,
	&"whoosh_low": -2.0,
	&"charge": -4.0,
}

const CHARGE_S := 2.5 # the win cutscene's build up, it checks

static var _made := {}

static func stream(id: StringName) -> AudioStream:
	if FILES.has(id): return FILES[id]
	if not _made.has(id):
		match id:
			&"whoosh": _made[id] = SfxUtils.whoosh()
			&"whoosh_low": _made[id] = SfxUtils.whoosh(0.9, true)
			&"charge": _made[id] = SfxUtils.charge(CHARGE_S)
			_: assert(false, "no sound named %s" % id)
	return _made[id]

static func volume_db(id: StringName) -> float: return VOLUME_DB.get(id, 0.0)
