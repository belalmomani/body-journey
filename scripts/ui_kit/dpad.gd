class_name DPad
extends Control
# عصا تحكم بالأسهم: 8 اتجاهات + مركز للتوقف. اضغط مع الاستمرار وحرّك الإصبع بين الخانات.
signal dir_changed(dir: Vector2)
const CELL := 112.0
var dir := Vector2.ZERO
var _pressed := false
var _cell := Vector2i(1, 1)
var _sb_n: StyleBoxFlat
var _sb_a: StyleBoxFlat

func _init() -> void:
	custom_minimum_size = Vector2(CELL * 3.0, CELL * 3.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_sb_n = StyleBoxFlat.new()
	_sb_n.bg_color = Color(1, 1, 1, 0.30)
	_sb_n.set_corner_radius_all(26)
	_sb_n.set_border_width_all(2)
	_sb_n.border_color = Color(1, 1, 1, 0.55)
	_sb_a = StyleBoxFlat.new()
	_sb_a.bg_color = Color(1.0, 0.85, 0.3, 0.8)
	_sb_a.set_corner_radius_all(26)
	_sb_a.set_border_width_all(3)
	_sb_a.border_color = Color(1, 1, 1, 0.9)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb: InputEventMouseButton = e
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = mb.pressed
			if _pressed:
				_update(mb.position)
			else:
				_set_cell(Vector2i(1, 1))
	elif e is InputEventMouseMotion and _pressed:
		var mm: InputEventMouseMotion = e
		_update(mm.position)

func _update(p: Vector2) -> void:
	_set_cell(Vector2i(clampi(int(p.x / CELL), 0, 2), clampi(int(p.y / CELL), 0, 2)))

func _set_cell(c: Vector2i) -> void:
	_cell = c
	dir = Vector2(float(c.x - 1), float(c.y - 1))
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	dir_changed.emit(dir)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_pressed = false
		_set_cell(Vector2i(1, 1))

func _draw() -> void:
	for cy in 3:
		for cx in 3:
			var r := Rect2(Vector2(float(cx), float(cy)) * CELL + Vector2(6, 6), Vector2(CELL - 12.0, CELL - 12.0))
			var active := _pressed and _cell == Vector2i(cx, cy)
			draw_style_box(_sb_a if active else _sb_n, r)
			var c := r.get_center()
			if cx == 1 and cy == 1:
				draw_circle(c, 14.0, Color(1, 1, 1, 0.55))
			else:
				var d := Vector2(float(cx - 1), float(cy - 1)).normalized()
				var o := d.orthogonal()
				draw_colored_polygon(PackedVector2Array([c + d * 26.0, c - d * 14.0 + o * 22.0, c - d * 14.0 - o * 22.0]), Color(0.1, 0.1, 0.4, 0.9))
