class_name Desktop
extends RefCounted

# the retro desktop behind the ads and the virus cutscene

const WALLPAPER := Color(0.16, 0.5, 0.52)
const ICON_SIZE := 48.0
const ICON_START := Vector2(48, 150) # first icon centre, below the score
const ICON_STEP := 86.0
const TASKBAR_H := 30.0
const TASKBAR := Color(0.72, 0.71, 0.73)
const LABELS: Array[String] = ["my computer", "game_FINAL", "internet", "notes.txt", "trash"]
const ICONS: Array[Texture2D] = [
	preload("res://assets/Retro Dekstop/Icons/2X/Icon_Computer.png"),
	preload("res://assets/Retro Dekstop/Icons/2X/Icon_Folder.png"),
	preload("res://assets/Retro Dekstop/Icons/2X/Icon_Globe.png"),
	preload("res://assets/Retro Dekstop/Icons/2X/Icon_Notepad.png"),
	preload("res://assets/Retro Dekstop/Icons/2X/Icon_Trash.png"),
]

static func draw(item: CanvasItem, icons: Array[Texture2D] = ICONS, screen := Vector2.ZERO) -> void: # zero -> item's viewport
	if screen == Vector2.ZERO: screen = item.get_viewport_rect().size
	item.draw_rect(Rect2(Vector2.ZERO, screen), WALLPAPER)
	var font := ThemeDB.fallback_font
	for i in icons.size():
		var center := ICON_START + Vector2(0, i * ICON_STEP)
		item.draw_texture_rect(icons[i], Rect2(center - Vector2.ONE * ICON_SIZE / 2, Vector2.ONE * ICON_SIZE), false)
		var label := LABELS[i % LABELS.size()]
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		item.draw_string(font, center + Vector2(-width / 2, ICON_SIZE / 2 + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	item.draw_rect(Rect2(0, screen.y - TASKBAR_H, screen.x, TASKBAR_H), TASKBAR)
	item.draw_rect(Rect2(4, screen.y - TASKBAR_H + 4, 64, TASKBAR_H - 8), Color(0.85, 0.84, 0.86))
	item.draw_string(font, Vector2(14, screen.y - 10), "start", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.1, 0.12))
