class_name OrganelleFX
extends Node2D
# حدث بصري يمثّل وظيفة العضية (مبسّط وكرتوني). boost = 0..1 يزداد عند اقتراب اللاعب.
var kind := "nucleus"
var r := 100.0
var boost := 0.0
var t := 0.0
var cel := 0.0
var formed := false   # للخلية البدائية: بعد تكوّن غشاء النواة

func celebrate() -> void:
	cel = 0.9

func _process(delta: float) -> void:
	t += delta
	if cel > 0.0:
		cel -= delta
		if kind == "burst" and cel <= 0.0:
			queue_free()
			return
	queue_redraw()

func _spark(p: Vector2, s: float, col: Color) -> void:
	draw_circle(p, s * 0.5, col)
	draw_line(p + Vector2(-s, 0.0), p + Vector2(s, 0.0), col, 1.5)
	draw_line(p + Vector2(0.0, -s), p + Vector2(0.0, s), col, 1.5)

func _draw() -> void:
	var k := 0.55 + 0.45 * boost
	if kind == "mito":
		# طاقة: ومضات تتصاعد من الميتوكوندريا
		draw_circle(Vector2.ZERO, r * 0.9, Color(1.0, 0.7, 0.2, (0.10 + 0.08 * sin(t * 3.0) + 0.15 * boost) * 0.5))
		var n := 5 + int(boost * 5.0)
		for i in n:
			var p := fmod(t * 0.55 + float(i) / float(n), 1.0)
			var pos := Vector2(sin(p * 7.0 + float(i) * 2.0) * r * 0.35, r * 0.15 - p * r * 0.95)
			_spark(pos, 4.0 + 4.0 * boost, Color(1.0, 0.95, 0.4, sin(p * PI) * k))
	elif kind == "nucleus":
		# نبضات التحكم + رسائل وراثية تخرج من النواة
		for j in 2:
			var p := fmod(t * 0.45 + float(j) * 0.5, 1.0)
			draw_arc(Vector2.ZERO, r * (0.55 + 0.6 * p), 0.0, TAU, 48, Color(0.85, 0.65, 1.0, 0.5 * (1.0 - p) * k), 3.0, true)
		for i in 4:
			var p2 := fmod(t * 0.35 + float(i) * 0.25, 1.0)
			var d := Vector2.from_angle(float(i) * TAU / 4.0 + 0.6)
			draw_circle(d * (r * 0.55 + p2 * r * 0.9), 4.0, Color(0.7, 0.9, 1.0, (1.0 - p2) * k))
	elif kind == "er":
		# نقل المواد على امتداد الشبكة
		for i in 6:
			var p := fmod(t * 0.3 + float(i) / 6.0, 1.0)
			var pos := Vector2(lerpf(-r * 0.8, r * 0.8, p), sin(p * TAU * 1.5 + float(i)) * r * 0.3)
			draw_circle(pos, 4.0 + 2.0 * boost, Color(0.6, 0.95, 1.0, sin(p * PI) * k))
	elif kind == "ribo":
		# سلسلة بروتين تنمو خرزة بعد خرزة
		var cnt := 1 + int(fmod(t * 0.9, 1.0) * 6.0)
		for i in cnt:
			var pos := Vector2(r * 0.55 + float(i) * 15.0, -r * 0.55 - sin(float(i) * 0.9) * 14.0)
			draw_circle(pos, 7.0, Color.from_hsv(fmod(0.08 + float(i) * 0.11, 1.0), 0.65, 1.0, k))
			draw_arc(pos, 7.0, 0.0, TAU, 16, Color(1, 1, 1, 0.6 * k), 1.5, true)
	elif kind == "golgi":
		# حويصلات تدور حول جولجي وأخرى تخرج موجّهة
		for i in 3:
			var a := t * 0.7 + float(i) * TAU / 3.0
			var pos := Vector2(cos(a) * r * 0.95, sin(a) * r * 0.55)
			draw_circle(pos, 9.0, Color(1.0, 0.8, 0.3, 0.85 * k))
			draw_circle(pos + Vector2(-2.0, -2.0), 3.0, Color(1, 1, 1, 0.7 * k))
		var p3 := fmod(t * 0.35, 1.0)
		draw_circle(Vector2(r * 0.5 + p3 * r * 0.8, -r * 0.1 - p3 * r * 0.5), 8.0, Color(0.6, 1.0, 0.7, (1.0 - p3) * k))
	elif kind == "membrane":
		# مواد تعبر الغشاء بانتقائية
		for i in 5:
			var p := fmod(t * 0.35 + float(i) * 0.2, 1.0)
			var x := lerpf(-r * 0.6, r * 0.6, float(i) / 4.0)
			draw_circle(Vector2(x, lerpf(-r * 0.45, r * 0.45, p)), 5.0, Color(0.9, 1.0, 0.8, sin(p * PI) * k))
	elif kind == "prokaryote":
		# خلية بدائية: جدار، مادة وراثية حرّة (حلقة)، ريبوسومات صغيرة، بلا نواة
		_capsule(r, r * 0.55, Color(0.6, 0.95, 0.8, 0.35), Color(0.45, 0.85, 0.7, 0.9))
		var pts := PackedVector2Array()
		for i in 41:
			var a := TAU * float(i) / 40.0
			var rad := r * 0.22 * (1.0 + 0.12 * sin(a * 5.0 + t * 1.2))
			pts.append(Vector2(cos(a), sin(a)) * rad + Vector2(0.0, 10.0))
		draw_polyline(pts, Color(0.95, 0.5, 0.9, 0.95), 5.0, true)
		for i in 14:
			var rp := Vector2(cos(float(i) * 2.3) * r * 0.75, sin(float(i) * 1.7) * r * 0.3) + Vector2(sin(t + float(i)) * 4.0, cos(t * 0.8 + float(i)) * 4.0)
			draw_circle(rp, 4.0, Color(0.9, 0.8, 0.3, 0.8))
		if formed:
			draw_circle(Vector2(0.0, 10.0), r * 0.34, Color(0.8, 0.6, 1.0, 0.15))
			draw_arc(Vector2(0.0, 10.0), r * 0.34, 0.0, TAU, 48, Color(0.8, 0.6, 1.0, 0.9), 6.0, true)
	elif kind == "burst":
		var q := 1.0 - cel / 0.9
		for j in 2:
			draw_arc(Vector2.ZERO, r * (0.4 + (q + float(j) * 0.2) * 1.2), 0.0, TAU, 48, Color(1.0, 0.95, 0.5, maxf(0.0, 0.8 - q - float(j) * 0.2)), 5.0, true)
		for i in 10:
			var d := Vector2.from_angle(float(i) * TAU / 10.0)
			_spark(d * r * (0.4 + q * 1.4), 7.0 * (1.0 - q * 0.5), Color(1.0, 0.95, 0.4, 1.0 - q))

func _capsule(half_len: float, half_h: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	var cl := half_len - half_h
	for i in 25:
		var a := -PI / 2.0 + PI * float(i) / 24.0
		pts.append(Vector2(cl + cos(a) * half_h, sin(a) * half_h))
	for i in 25:
		var a2 := PI / 2.0 + PI * float(i) / 24.0
		pts.append(Vector2(-cl + cos(a2) * half_h, sin(a2) * half_h))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, Color(edge.r, edge.g, edge.b, 0.35), 18.0, true)
	draw_polyline(pts, edge, 8.0, true)
