class_name CellIcon
extends Control
# أيقونة صغيرة: خلية/فقاعة علمية، أو علامة صح/خطأ (الرمز يدعم عدم الاعتماد على اللون وحده).
var mode := "cell"   # cell | ok | bad
var tint := Color("#7fe3ff")

func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_mode(m: String) -> void:
	mode = m
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 3.0
	if mode == "ok":
		draw_circle(c, r, Color("#2ecc71"))
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0, true)
		draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, 0.0), c + Vector2(-r * 0.1, r * 0.35), c + Vector2(r * 0.5, -r * 0.35)]), Color.WHITE, 7.0, true)
	elif mode == "bad":
		draw_circle(c, r, Color("#e8575d"))
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0, true)
		draw_line(c + Vector2(-r * 0.35, -r * 0.35), c + Vector2(r * 0.35, r * 0.35), Color.WHITE, 7.0, true)
		draw_line(c + Vector2(r * 0.35, -r * 0.35), c + Vector2(-r * 0.35, r * 0.35), Color.WHITE, 7.0, true)
	else:
		draw_circle(c, r, Color(tint.r, tint.g, tint.b, 0.35))
		draw_arc(c, r, 0.0, TAU, 32, tint, 3.0, true)
		draw_circle(c + Vector2(-r * 0.1, r * 0.05), r * 0.4, Color(tint.lightened(0.25), 0.9))
		draw_circle(c + Vector2(-r * 0.22, -r * 0.08), r * 0.13, Color(1, 1, 1, 0.9))
		draw_circle(c + Vector2(r * 0.5, -r * 0.42), r * 0.12, tint.lightened(0.4))
		draw_circle(c + Vector2(r * 0.42, r * 0.5), r * 0.09, tint.lightened(0.4))
