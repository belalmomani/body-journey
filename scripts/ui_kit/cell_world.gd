class_name CellWorld
extends Node2D
# طبقات عمق للعالم الخلوي: صور ظلّية بعيدة + جزيئات سيتوبلازم + غشاء عضوي متحرك.
# layer = "back" (خلف الشخصية) أو "front" (جزيئات قريبة أمام الشخصية).
var layer := "back"
var mode := "cell"   # cell | artery | heart | capillary | lungs
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
		if mode == "artery" or mode == "heart" or mode == "capillary":
			v = Vector2(40.0 + float(pt["d"]) * 90.0, v.y * 0.3)
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
	if layer == "back" and mode != "cell":
		_draw_vessel(off)
	elif layer == "back":
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
		var blood := mode == "artery" or mode == "heart" or mode == "capillary"
		if blood:
			var sz := float(pt["s"]) * 3.0
			draw_circle(pos, sz, Color(0.9, 0.2, 0.25, minf(0.8, a * 2.5)))
			draw_circle(pos, sz * 0.45, Color(0.6, 0.1, 0.15, minf(0.7, a * 2.0)))
		elif mode == "lungs":
			draw_circle(pos, float(pt["s"]) * 1.6, Color(0.9, 1.0, 1.0, a * 0.5))
			draw_arc(pos, float(pt["s"]) * 1.6, 0.0, TAU, 16, Color(1, 1, 1, a), 1.5, true)
		else:
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

func _wavy(y0: float, amp: float, ph: float, off: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 30
	for i in n + 1:
		var x := vp.x * float(i) / float(n)
		pts.append(Vector2(x, y0 + sin(x * 0.012 + t * 1.2 + ph) * amp) - off * 0.02)
	return pts

func _draw_vessel(off: Vector2) -> void:
	if mode == "artery":
		for k in 2:
			var y0 := 70.0 if k == 0 else vp.y - 70.0
			var w := _wavy(y0, 10.0 + 4.0 * sin(t * 3.0), float(k) * 2.0, off)
			draw_polyline(w, Color(0.85, 0.3, 0.35, 0.35), 70.0, true)
			draw_polyline(w, Color(0.95, 0.5, 0.5, 0.6), 24.0, true)
	elif mode == "capillary":
		for k in 2:
			var y0 := vp.y * (0.2 if k == 0 else 0.8)
			var w := _wavy(y0, 6.0, float(k), off)
			draw_polyline(w, Color(0.95, 0.6, 0.65, 0.45), 40.0, true)
			draw_polyline(w, Color(1.0, 0.8, 0.8, 0.7), 12.0, true)
		for i in 7:
			var px := vp.x * (float(i) + 0.5) / 7.0
			var py := vp.y * (0.08 if i % 2 == 0 else 0.93)
			draw_circle(Vector2(px, py) - off * 0.03, 60.0, Color(0.95, 0.5, 0.6, 0.35))
	elif mode == "heart":
		var beat := pow(maxf(0.0, sin(t * 3.0)), 6.0)
		draw_arc(vp / 2.0 - off * 0.02, vp.x * 0.62, 0.0, TAU, 64, Color(0.9, 0.2, 0.3, 0.45), 40.0 + beat * 30.0, true)
		draw_arc(vp / 2.0 - off * 0.02, vp.x * 0.56, 0.0, TAU, 64, Color(1.0, 0.5, 0.5, 0.5), 8.0 + beat * 6.0, true)
	elif mode == "lungs":
		for i in 8:
			var a := TAU * float(i) / 8.0 + t * 0.05
			var cpos := vp / 2.0 + Vector2(cos(a) * vp.x * 0.62, sin(a) * vp.y * 0.55) - off * 0.03
			draw_circle(cpos, 110.0 + sin(t * 1.5 + float(i)) * 8.0, Color(0.8, 0.95, 1.0, 0.2))
			draw_arc(cpos, 110.0, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 4.0, true)
