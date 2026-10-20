class_name AnswerButton
extends Button
# زر إجابة على شكل كبسولة علمية: أيقونة خلية، حالات (عادي/لمس/صح/خطأ/باهت).
signal chosen(btn: AnswerButton)
var answer_text := ""
var tint := Color("#7fe3ff")
var locked := false
var icon_node: CellIcon
var _breath: Tween

func setup(txt: String, tint_color: Color) -> void:
	answer_text = txt
	tint = tint_color
	text = txt
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	custom_minimum_size = Vector2(0, 112)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 34)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(c, Color.WHITE)
	add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.2, 0.9))
	add_theme_constant_override("outline_size", 6)
	_apply_style("idle")
	icon_node = CellIcon.new()
	icon_node.tint = tint
	icon_node.layout_direction = Control.LAYOUT_DIRECTION_LTR
	icon_node.anchor_left = 1.0
	icon_node.anchor_right = 1.0
	icon_node.anchor_top = 0.5
	icon_node.anchor_bottom = 0.5
	icon_node.offset_left = -84.0
	icon_node.offset_right = -20.0
	icon_node.offset_top = -32.0
	icon_node.offset_bottom = 32.0
	add_child(icon_node)

func _ready() -> void:
	resized.connect(func(): pivot_offset = size / 2.0)
	pressed.connect(_on_pressed)
	button_down.connect(func(): _scale_to(0.95))
	button_up.connect(func(): _scale_to(1.0))
	_start_breath()

func _start_breath() -> void:
	_breath = create_tween().set_loops()
	_breath.tween_property(self, "self_modulate", Color(1.16, 1.16, 1.16, 1.0), 1.4).set_trans(Tween.TRANS_SINE)
	_breath.tween_property(self, "self_modulate", Color.WHITE, 1.4).set_trans(Tween.TRANS_SINE)

func _scale_to(v: float) -> void:
	if locked:
		return
	create_tween().tween_property(self, "scale", Vector2(v, v), 0.07)

func _on_pressed() -> void:
	if locked:
		return
	GameState.sfx("tap")
	chosen.emit(self)

func _apply_style(state: String) -> void:
	var bg := Color(0.10, 0.22, 0.45, 0.8)
	var border := tint
	var glow := Color(tint.r, tint.g, tint.b, 0.35)
	if state == "ok":
		bg = Color(0.08, 0.45, 0.25, 0.92)
		border = Color("#5dff9a")
		glow = Color(0.2, 1.0, 0.5, 0.6)
	elif state == "bad":
		bg = Color(0.5, 0.15, 0.2, 0.9)
		border = Color("#ff8a8a")
		glow = Color(1.0, 0.35, 0.35, 0.5)
	elif state == "dim":
		bg = Color(0.1, 0.15, 0.3, 0.5)
		border = Color(tint.r, tint.g, tint.b, 0.4)
		glow = Color(0, 0, 0, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(56)
	sb.set_border_width_all(4)
	sb.border_color = border
	sb.shadow_color = glow
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 28.0
	sb.content_margin_right = 100.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, sb)

func reveal(state: String) -> void:
	locked = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _breath:
		_breath.kill()
	self_modulate = Color.WHITE
	scale = Vector2.ONE
	_apply_style(state)
	if state == "ok":
		icon_node.set_mode("ok")
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)
	elif state == "bad":
		icon_node.set_mode("bad")
		var tw2 := create_tween()
		tw2.tween_property(self, "rotation", 0.03, 0.06)
		tw2.tween_property(self, "rotation", -0.03, 0.06)
		tw2.tween_property(self, "rotation", 0.02, 0.06)
		tw2.tween_property(self, "rotation", 0.0, 0.06)
	elif state == "dim":
		modulate = Color(1, 1, 1, 0.55)
