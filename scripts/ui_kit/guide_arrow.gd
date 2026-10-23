class_name GuideArrow
extends Node2D
# سهم يدلّ اللاعب إلى هدف المهمة الحالية.
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var s := 1.0 + 0.12 * sin(t * 6.0)
	var pts := PackedVector2Array([Vector2(34, 0) * s, Vector2(-14, 24) * s, Vector2(-4, 0) * s, Vector2(-14, -24) * s])
	draw_colored_polygon(pts, Color(1.0, 0.9, 0.3, 0.95))
	pts.append(pts[0])
	draw_polyline(pts, Color.WHITE, 3.0, true)
