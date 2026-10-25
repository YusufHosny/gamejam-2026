class_name MenuStyle
extends RefCounted

# the french look the menus share: Lobster with thick outlines, baguettes for buttons, the flag waving behind them

const FONT := preload("res://assets/fonts/Lobster-Regular.ttf")
const BAGUETTE := preload("res://assets/menu/baguette.png")
const BAGUETTE_LIT := preload("res://assets/menu/baguette_lit.png") # toasted and glowing, hovered or focused
const BACKGROUND := preload("res://assets/menu/french_flag.png")
const BUTTON_SIZE := Vector2(320, 100)
const CRUMB := Color(1.0, 0.96, 0.86)
const CRUST := Color(0.36, 0.18, 0.05)
const NAVY := Color(0.0, 0.14, 0.35)
const OUTLINE := 10
const TITLE_OUTLINE := 22
const PANEL := Color(0.05, 0.05, 0.1, 0.78)
const ACCENT := Color(1.0, 0.85, 0.2)

static var _theme: Theme = null

# Bangers everywhere, outlined white text, dark translucent panels so the art behind stays busy but the text reads
static func theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	_theme.default_font = FONT
	_theme.default_font_size = 28
	for type in [&"Label", &"Button", &"CheckBox", &"OptionButton", &"TabBar", &"LineEdit", &"SpinBox"]:
		_theme.set_color(&"font_outline_color", type, Color.BLACK)
		_theme.set_constant(&"outline_size", type, OUTLINE)
	_theme.set_color(&"font_color", &"Label", Color.WHITE)
	_theme.set_stylebox(&"panel", &"TabContainer", _panel())
	_theme.set_stylebox(&"panel", &"PanelContainer", _panel())
	for state in [&"normal", &"hover", &"pressed", &"focus"]: _theme.set_stylebox(state, &"Button", _flat(Color(0.12, 0.12, 0.2, 0.9) if state != &"hover" else Color(0.2, 0.55, 0.3, 0.95)))
	return _theme

static func _panel() -> StyleBoxFlat:
	var box := _flat(PANEL)
	box.set_content_margin_all(18)
	return box

static func _flat(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color.BLACK
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(8)
	return box

# the button as a baguette with its label written on, toasted when hovered, focused or held
static func baguette_button(button: Button, label: String) -> void:
	var normal := _bread(BAGUETTE)
	var lit := _bread(BAGUETTE_LIT)
	for state in [&"normal", &"disabled"]: button.add_theme_stylebox_override(state, normal)
	for state in [&"hover", &"pressed", &"focus", &"hover_pressed"]: button.add_theme_stylebox_override(state, lit)
	button.text = label
	button.add_theme_font_size_override(&"font_size", 36)
	for state in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]: button.add_theme_color_override(state, CRUMB)
	button.add_theme_color_override(&"font_outline_color", CRUST)
	button.add_theme_constant_override(&"outline_size", 12)
	button.custom_minimum_size = BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER # the bread never stretches

static func _bread(texture: Texture2D) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	return box

# fills the menu behind everything else in it
static func add_background(menu: Control, texture: Texture2D = BACKGROUND) -> void:
	var back := TextureRect.new()
	back.texture = texture
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(back)
	menu.move_child(back, 0)

# a big outlined comic title with a coloured drop shadow
static func title(label: Label, size: int) -> void:
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_constant_override(&"outline_size", TITLE_OUTLINE)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_color_override(&"font_shadow_color", NAVY)
	label.add_theme_constant_override(&"shadow_offset_x", 6)
	label.add_theme_constant_override(&"shadow_offset_y", 8)
	label.add_theme_constant_override(&"shadow_outline_size", TITLE_OUTLINE)
