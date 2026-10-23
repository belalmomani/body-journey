class_name DialogueBox
extends PanelContainer
# صندوق حوار مكتوب: اسم المتحدث، صورة، ظهور تدريجي للنص، متابعة/إعادة/تخطي.
signal finished
signal line_shown(line: Dictionary)
var lines: Array = []
var idx := 0
var portraits := {}
var name_label: Label
var text_label: Label
var portrait: TextureRect
var next_btn: Button
var _tw: Tween
var _typing := false

func _init() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_theme_stylebox_override("panel", UI.holo_style())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(top)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	top.add_child(col)
	name_label = UI.glow_label("", 30, Color("#ffd27f"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(name_label)
	text_label = UI.glow_label("", 30)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.layout_direction = Control.LAYOUT_DIRECTION_RTL
	col.add_child(text_label)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(portrait)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var skip := UI.button("تخطي", _end, Color("#8d99ae"))
	var rep := UI.button("إعادة", _show, Color("#6c63ff"))
	next_btn = UI.button("التالي", _next, Color("#2a9d8f"))
	for b in [skip, rep, next_btn]:
		var bb: Button = b
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.custom_minimum_size = Vector2(0, 72)
		bb.add_theme_font_size_override("font_size", 28)
		row.add_child(bb)

func play(l: Array, p: Dictionary) -> void:
	lines = l
	portraits = p
	idx = 0
	visible = true
	_show()

func _show() -> void:
	if idx >= lines.size():
		return
	var line: Dictionary = lines[idx]
	var who := str(line.get("who", ""))
	name_label.text = who
	portrait.texture = portraits.get(who, null)
	text_label.text = str(line["text"])
	text_label.visible_characters = 0
	_typing = true
	if _tw:
		_tw.kill()
	var n := text_label.text.length()
	_tw = create_tween()
	_tw.tween_property(text_label, "visible_characters", n, minf(2.2, 0.025 * float(n)))
	_tw.tween_callback(func(): _typing = false)
	next_btn.text = "متابعة" if idx >= lines.size() - 1 else "التالي"
	line_shown.emit(line)

func _next() -> void:
	if _typing:
		if _tw:
			_tw.kill()
		text_label.visible_characters = -1
		_typing = false
		return
	idx += 1
	if idx >= lines.size():
		_end()
	else:
		_show()

func _end() -> void:
	if _tw:
		_tw.kill()
	visible = false
	finished.emit()
