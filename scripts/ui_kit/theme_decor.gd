class_name ThemeDecor
extends Control
# زخارف متحركة هادئة خلف لوحة السؤال، تتغير بحسب موضوع المرحلة.
var mode := "bubbles"   # bubbles | blood | heart | nerve | shield
var t := 0.0
var seeds: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := RandomNumberGenerator.new()
	r.seed = 99
	for i in 14:
		seeds.append(Vector3(r.randf(), r.randf(), r.randf()))

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	for i in seeds.size():
		var s: Vector3 = seeds[i]
		var x := s.x * w
		var y := fmod(s.y * h - t * (8.0 + s.z * 14.0) + h * 4.0, h)
		var r := 10.0 + s.z * 26.0
		var p := Vector2(x, y)
		if mode == "blood":
			draw_circle(p, r, Color(0.95, 0.2, 0.25, 0.16))
			draw_circle(p, r * 0.45, Color(0.5, 0.05, 0.1, 0.14))
		elif mode == "nerve":
			draw_circle(p, r * 0.3, Color(0.5, 0.85, 1.0, 0.4))
			draw_line(p, p + Vector2(r * 1.6, -r), Color(0.5, 0.85, 1.0, 0.2), 2.0)
		elif mode == "heart":
			var k := 1.0 + 0.15 * sin(t * 4.0 + float(i))
			draw_circle(p + Vector2(-r * 0.3, 0.0) * k, r * 0.4 * k, Color(1.0, 0.4, 0.5, 0.15))
			draw_circle(p + Vector2(r * 0.3, 0.0) * k, r * 0.4 * k, Color(1.0, 0.4, 0.5, 0.15))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.7, r * 0.1) * k, p + Vector2(r * 0.7, r * 0.1) * k, p + Vector2(0.0, r * 0.9) * k]), Color(1.0, 0.4, 0.5, 0.15))
		elif mode == "shield":
			var pts := PackedVector2Array()
			for a in 6:
				pts.append(p + Vector2.from_angle(float(a) * TAU / 6.0 + t * 0.2) * r)
			draw_colored_polygon(pts, Color(0.6, 0.85, 1.0, 0.12))
		else:
			draw_circle(p, r, Color(0.6, 0.9, 1.0, 0.1))
			draw_arc(p, r, 0.0, TAU, 24, Color(0.7, 0.95, 1.0, 0.25), 2.0, true)
