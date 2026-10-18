class_name UI
extends RefCounted
# مساعدات واجهة برمجية موحدة (RTL، أزرار كبيرة)

static func root(scene: Control) -> VBoxContainer:
	scene.layout_direction = Control.LAYOUT_DIRECTION_RTL
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#fff4d6")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene.add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 32)
	scene.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	m.add_child(v)
	return v

static func label(text: String, size := 32, color := Color("#3b2a6b")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func button(text: String, cb: Callable, color := Color("#ff7a59")) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", 36)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(28)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	var dis: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	dis.bg_color = Color("#b8b8b8")
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)
	b.pressed.connect(func(): GameState.sfx("tap"))
	b.pressed.connect(cb)
	return b

static func input(placeholder: String, secret := false) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.custom_minimum_size = Vector2(0, 88)
	e.add_theme_font_size_override("font_size", 32)
	return e

static func scroll(parent: Control) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(s)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	s.add_child(v)
	return v

static func back_button(parent: Control, scene := "res://scenes/menu.tscn") -> void:
	parent.add_child(button("رجوع", func(): GameState.go(scene), Color("#6c63ff")))
