class_name VoiceLines
extends RefCounted

# every voice line's captions per language. parts start when that phrase starts in the recording (found with silence
# detection), a caption builds up part by part and holds a little after the speech ends. the english captions swear in
# french, it's funnier. the audio is assets/voicelines/<lang>/<id>.ogg, made by tools/convert_voicelines.sh

const HOLD_S := 0.6
const LANGUAGES := {"en": "English", "fr": "Français"}
const LINES := {
	# intro, the "Additional lines v2" takes
	&"intro_1": {
		"en": {"end": 1.85, "parts": [[0.70, "Okay. The game is done."]]},
		"fr": {"end": 1.93, "parts": [[0.56, "Okay."], [1.31, "Le jeu est fini."]]},
	},
	&"intro_2": {
		"en": {"end": 3.61, "parts": [[0.86, "Well..."], [1.87, "it runs."], [2.92, "That counts as done."]]},
		"fr": {"end": 3.96, "parts": [[0.50, "Bon..."], [1.73, "il tourne."], [3.27, "Ça compte comme fini."]]},
	},
	&"intro_3": {
		"en": {"end": 4.73, "parts": [[0.77, "The jam closes in a few minutes."], [3.13, "Let's submit it before anything goes wrong."]]},
		"fr": {"end": 4.30, "parts": [[0.40, "La jam ferme dans quelques minutes."], [3.03, "Envoyons-le avant que ça tourne mal."]]},
	},
	&"intro_4": {
		"en": {"end": 3.79, "parts": [[0.69, "Sign in first?"], [2.56, "...Sure."], [3.39, "Easy."]]},
		"fr": {"end": 3.29, "parts": [[0.49, "Se connecter d'abord ?"], [2.07, "...D'accord."], [2.73, "Facile."]]},
	},
	&"seriously": {
		"en": {"end": 1.67, "parts": [[0.59, "Seriously?"]]},
		"fr": {"end": 1.35, "parts": [[0.34, "Sérieusement ?"]]},
	},
	&"ugh": {
		"en": {"end": 1.41, "parts": [[0.66, "Ugh..."]]},
		"fr": {"end": 1.13, "parts": [[0.51, "Rhaa..."]]},
	},
	&"oops": {
		"en": {"end": 0.87, "parts": [[0.35, "Oops."]]},
		"fr": {"end": 1.02, "parts": [[0.63, "Oups."]]},
	},
	# tutorial hints
	&"tutorial_1": {
		"en": {"end": 3.30, "parts": [[0.57, "Click the circle when the approach circle hits it"]]},
		"fr": {"end": 3.29, "parts": [[0.54, "Clique le cercle lorsque le cercle en approche le touche"]]},
	},
	&"tutorial_2": {
		"en": {"end": 3.03, "parts": [[0.57, "Click and hold the slider, then follow the ball"]]},
		"fr": {"end": 2.74, "parts": [[0.45, "Clique et garde le slider, puis suis la balle"]]},
	},
	&"tutorial_3": {
		"en": {"end": 3.40, "parts": [[0.68, "Press the key when a notification hits the line"]]},
		"fr": {"end": 3.17, "parts": [[0.36, "Appuie sur la touche lorsqu'une notif touche la ligne"]]},
	},
	&"tutorial_4": {
		"en": {"end": 3.10, "parts": [[0.39, "Slash through the circle when the approach circle hits it"]]},
		"fr": {"end": 3.16, "parts": [[0.59, "Tranche le cercle quand le cercle en approche le touche"]]},
	},
	# cutscenes
	&"email_open": {
		"en": {"end": 2.36, "parts": [[0.40, "Alright,"], [1.20, "where is that dumb email?"]]},
		"fr": {"end": 2.17, "parts": [[0.63, "Bien, il est où ce putain de mail ?"]]},
	},
	&"sign_in_1": {
		"en": {"end": 2.93, "parts": [[0.49, "Okay, I'm in!"], [2.18, "Let's see..."]]},
		"fr": {"end": 3.55, "parts": [[0.73, "Okay, j'y suis !"], [2.94, "Voyons voir..."]]},
	},
	&"sign_in_2": {
		"en": {"end": 4.03, "parts": [[0.50, "Putain de merde, there's five minutes left?! How?!"]]},
		"fr": {"end": 3.90, "parts": [[0.70, "Putain de merde, y'a que 5 minutes qui restent ?"], [3.44, "Comment ?!"]]},
	},
	&"virus_1": {
		"en": {"end": 4.48, "parts": [[0.65, "Gotta submit this fast now! Please work..."]]},
		"fr": {"end": 3.58, "parts": [[0.62, "Faut vite que je l'envoie maintenant !"], [2.47, "Pitié, que ça marche..."]]},
	},
	&"virus_2": {
		"en": {"end": 2.71, "parts": [[0.59, "You've gotta be putain de kidding me..."]]},
		"fr": {"end": 1.63, "parts": [[0.55, "Tu te fous de ma gueule..."]]},
	},
	&"ads_1": {
		"en": {"end": 5.73, "parts": [[0.57, "Who even makes these? What's happening?"], [4.27, "Noooo! Merde!"]]},
		"fr": {"end": 5.86, "parts": [[0.67, "Qui fabrique ces trucs aussi ?"], [2.84, "Qu'est-ce qui se passe ?"], [4.20, "Noooon ! Merde !"]]},
	},
	&"ads_2": {
		"en": {"end": 2.61, "parts": [[0.59, "Why is this happening to me..."]]},
		"fr": {"end": 2.03, "parts": [[0.63, "Pourquoi ça n'arrive qu'à moi..."]]},
	},
	&"dodge_1": {
		"en": {"end": 5.47, "parts": [[0.78, "There it is! Now I've just gotta..."], [5.23, "Huh?"]]},
		"fr": {"end": 4.26, "parts": [[0.80, "Le voilà ! J'ai plus qu'à..."], [3.94, "Hein ?"]]},
	},
	&"dodge_2": {
		"en": {"end": 3.00, "parts": [[0.80, "Okay, who designed this merde?"]]},
		"fr": {"end": 2.64, "parts": [[0.75, "Ok, qui a conçu cette merde ?"]]},
	},
	&"win": {
		"en": {"end": 4.87, "parts": [[0.86, "Phew, that was close!"], [2.76, "No way I can do this again next year..."]]},
		"fr": {"end": 4.82, "parts": [[0.71, "Ouf,"], [1.52, "c'était pas loin !"], [2.91, "Pas une chance de refaire ça l'année prochaine..."]]},
	},
}

static func _line(id: StringName) -> Dictionary: return LINES[id][GameConfig.language]

static func stream(id: StringName) -> AudioStream:
	return load("res://assets/voicelines/%s/%s.ogg" % [GameConfig.language, id])

# what's been said `t` seconds into the recording, empty before the first part and once it's held long enough
static func caption(id: StringName, t: float) -> String:
	var line := _line(id)
	if t > line.end + HOLD_S: return ""
	var said: Array[String] = []
	for part: Array in line.parts:
		if t >= part[0]: said.append(part[1])
	return " ".join(said)

static func part_start(id: StringName, part: int) -> float: return _line(id).parts[part][0]

static func text(id: StringName) -> String: return " ".join(_line(id).parts.map(func(p: Array): return p[1]))

static func caption_end(id: StringName) -> float: return _line(id).end + HOLD_S
