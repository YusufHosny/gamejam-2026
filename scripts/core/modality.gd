class_name Modality
extends RefCounted

enum Kind { FOUR_D, AIM_CLICK, SLASH }
enum HandPos { A, B } # A: right hand mouse, left hand keys. B: both hands on keys

static func hand_pos(kind: Kind) -> HandPos:
	match kind:
		Kind.AIM_CLICK, Kind.SLASH: return HandPos.A
		Kind.FOUR_D: return HandPos.B
	assert(false, "unhandled modality %s" % kind)
	return HandPos.A
