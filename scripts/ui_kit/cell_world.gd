class_name CellWorld
extends Node2D
# طبقات عمق للعالم الخلوي: صور ظلّية بعيدة + جزيئات سيتوبلازم + غشاء عضوي متحرك.
# layer = "back" (خلف الشخصية) أو "front" (جزيئات قريبة أمام الشخصية).
var layer := "back"
var focus := Vector2(360.0, 640.0)
var t := 0.0
var vp := Vector2(720.0, 1280.0)
var parts: Array = []
var blobs: Array = []

func setup(l: String, count: int) -> void:
	layer = l
	vp = get_viewport_rect().size
	var r := RandomNumberGenerator.new()
	r.seed = 5 if l == "back" else 6
	for i in count:
		var d := r.randf()
		var big := l == "front"
		parts.append({
			"p": Vector2(r.randf() * vp.x, r.randf() * vp.y),
			"v": Vector2.from_angle(r.randf() * TAU) * (6.0 + d * 24.0),
			"s": (9.0 + d * 12.0) if big else (2.0 + d * 6.0),
			"a": (0.10 + d * 0.08) if big else (0.16 + d * 0.28),
			"ph": r.randf() * TAU,
			"d": d})
	if l == "back":
		var pal := [Color(1.0, 0.5, 0.6), Color(0.7, 0.5, 1.0), Color(1.0, 0.75, 0.4), Color(0.5, 0.8, 1.0)]
		for i in 6:
			blobs.append({"p": Vector2(r.randf() * vp.x, r.randf() * vp.y), "r": 90.0 + r.randf() * 130.0, "c": pal[i % 4], "ph": r.randf() * TAU})

func _process(delta: float) -> void:
	t += delta
	for pt in parts:
		var v: Vector2 = pt["v"]
		v += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 22.0 * delta   # حركة براونية
		var mx := 10.0 + float(pt["d"]) * 28.0
		if v.length() > mx:
			v = v.normalized() * mx
		pt["v"] = v
		var p: Vector2 = pt["p"] + v * delta
		if p.x < -40.0:
			p.x = vp.x + 40.0
		elif p.x > vp.x + 40.0:
			p.x = -40.0
		if p.y < -40.0:
			p.y = vp.y + 40.0
		elif p.y > vp.y + 40.0:
			p.y = -40.0
		pt["p"] = p
	queue_redraw()

func _draw() -> void:
	var off := focus - vp / 2.0
	if layer == "back":
		for b in blobs:
			var c: Color = b["c"]
			var bp: Vector2 = b["p"] - off * 0.03 + Vector2(sin(t * 0.1 + float(b["ph"])) * 20.0, cos(t * 0.08 + float(b["ph"])) * 16.0)
			draw_circle(bp, float(b["r"]), Color(c.r, c.g, c.b, 0.07))
			draw_circle(bp, float(b["r"]) * 0.6, Color(c.r, c.g, c.b, 0.05))
		_draw_membrane(off)
	for pt in parts:
		var par := 0.15 if layer == "front" else 0.02 + float(pt["d"]) * 0.1
		var pos: Vector2 = pt["p"] - off * par
		var tw := 0.75 + 0.25 * sin(t * 1.5 + float(pt["ph"]))
		var a := float(pt["a"]) * tw
		draw_circle(pos, float(pt["s"]) * 1.8, Color(1.0, 0.9, 1.0, a * 0.25))
		draw_circle(pos, float(pt["s"]), Color(1.0, 0.92, 1.0, a))

func _draw_membrane(off: Vector2) -> void:
	var c := vp / 2.0
	var rx := vp.x * 0.5 - 14.0
	var ry := vp.y * 0.5 - 70.0
	var pts := PackedVector2Array()
	var n := 90
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		var wob := 1.0 + 0.012 * sin(a * 7.0 + t * 0.9) + 0.008 * sin(a * 13.0 - t * 1.3)
		pts.append(c + Vector2(cos(a) * rx * wob, sin(a) * ry * wob) - off * 0.02)
	draw_polyline(pts, Color(1.0, 0.55, 0.5, 0.16), 34.0, true)
	draw_polyline(pts, Color(1.0, 0.75, 0.6, 0.32), 16.0, true)
	draw_polyline(pts, Color(1.0, 0.92, 0.75, 0.5), 5.0, true)
	for i in range(0, n, 3):
		draw_circle(pts[i], 5.0 + sin(t * 2.0 + float(i)) * 0.8, Color(1.0, 0.86, 0.45, 0.55))
