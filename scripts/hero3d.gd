class_name Hero3D
extends Node3D
# غلاف لنموذج رائد ثلاثي الأبعاد: تشغيل الحركات، التعابير، الالتفات السلس، رمش تلقائي.
const MODEL := "res://assets/characters/hero/Raed_Character.glb"
const LOOPS := ["idle", "walk", "run", "talk"]
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var face: MeshInstance3D
var current := ""
var loaded := false
var auto_blink := true
var _blink_t := 2.0
var _expr := {}

func _ready() -> void:
	var ps = load(MODEL)
	if not (ps is PackedScene):
		push_warning("Raed model missing: " + MODEL)
		return
	model = (ps as PackedScene).instantiate()
	add_child(model)
	skeleton = _find(model, "Skeleton3D") as Skeleton3D
	anim = _find(model, "AnimationPlayer") as AnimationPlayer
	face = _find(model, "MeshInstance3D") as MeshInstance3D
	if anim:
		for n in anim.get_animation_list():
			var a := anim.get_animation(n)
			a.loop_mode = Animation.LOOP_LINEAR if LOOPS.has(String(n)) else Animation.LOOP_NONE
	if face and face.mesh:
		for i in face.mesh.get_surface_count():
			var m = face.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				var mm := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				mm.vertex_color_use_as_albedo = true
				face.set_surface_override_material(i, mm)
	loaded = true
	play("idle", 0.0)

func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null

func play(n: String, blend := 0.15) -> void:
	if anim and anim.has_animation(n):
		current = n
		anim.play(n, blend)

func is_busy() -> bool:
	return anim != null and anim.is_playing() and not LOOPS.has(current)

func set_expression(n: String, v: float) -> void:
	_expr[n] = v
	if face:
		face.set("blend_shapes/" + n, v)

func get_expression(n: String) -> float:
	return float(_expr.get(n, 0.0))

func clear_expressions() -> void:
	for k in _expr.keys():
		set_expression(String(k), 0.0)

# اتجاه الحركة في المستوى (x, z)؛ الأمام الافتراضي للنموذج هو +Z
func turn_towards(dir: Vector2, delta: float) -> void:
	if dir.length() < 0.05:
		return
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.y), clampf(10.0 * delta, 0.0, 1.0))

func update_motion(speed: float) -> void:
	var want := "idle"
	if speed > 0.6:
		want = "run"
	elif speed > 0.05:
		want = "walk"
	if want != current and not is_busy():
		play(want)

func _process(delta: float) -> void:
	if not loaded or not auto_blink:
		return
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = randf_range(2.5, 5.0)
		var tw := create_tween()
		tw.tween_method(func(v: float): set_expression("Blink", v), 0.0, 1.0, 0.06)
		tw.tween_method(func(v: float): set_expression("Blink", v), 1.0, 0.0, 0.10)
