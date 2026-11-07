class_name Stage3D
extends SubViewportContainer
# مسرح ثلاثي الأبعاد للمرحلة الأولى: يقرأ حالة اللعبة الثنائية (المنطق كما هو) ويعرضها كمشهد 3D.
# المحاور: X ← x، Z ← y (بكسل منطقي × K). الكاميرا مائلة تُظهر الحقل كاملاً.
const K := 0.005
const RING_N := 96
const KINDS := {"النواة": "nucleus", "الميتوكوندريا": "mito", "الريبوسوم": "ribo", "الغشاء": "membrane",
	"الشبكة الإندوبلازمية": "er", "جهاز جولجي": "golgi"}
var vp := Vector2(720, 1280)
var sub: SubViewport
var root3: Node3D
var cam: Camera3D
var hero: Hero3D
var world_env: Environment
var floor_mat: StandardMaterial3D
var cell_ring: MultiMeshInstance3D
var prok: Organelle3D
var models := {}
var germs := {}
var _t := 0.0
var _focus := false
var _fit_frames := 0
var _fit_done := false
var _base_pos := Vector3(0, 8, 6)
var _base_look := Vector3(0, 0, 0.6)
var _look := Vector3(0, 0, 0.6)
var _last_hero := Vector3.ZERO
var _first := true
var _special := ""
var _expr := {}
var _env := ""

func to3(p: Vector2) -> Vector3:
	return Vector3((p.x - vp.x * 0.5) * K, 0.0, (p.y - vp.y * 0.5) * K)

func setup(lvl) -> void:
	vp = lvl.get_viewport_rect().size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub = SubViewport.new()
	sub.own_world_3d = true
	sub.msaa_3d = Viewport.MSAA_2X
	sub.handle_input_locally = false
	sub.gui_disable_input = true
	add_child(sub)
	root3 = Node3D.new()
	sub.add_child(root3)
	_build_env()
	_build_floor()
	_build_particles()
	hero = Hero3D.new()
	hero.scale = Vector3.ONE * 0.87
	root3.add_child(hero)
	cam = Camera3D.new()
	cam.fov = 40.0
	root3.add_child(cam)
	cam.current = true
	cam.position = _base_pos
	cam.look_at(_base_look)

func _build_env() -> void:
	world_env = Environment.new()
	world_env.background_mode = Environment.BG_COLOR
	world_env.background_color = Color("#4a2370")
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = Color("#e6d8ff")
	world_env.ambient_light_energy = 0.7
	world_env.fog_enabled = true
	world_env.fog_light_color = Color("#5b2a8a")
	world_env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = world_env
	root3.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.0
	sun.light_color = Color("#fff1e0")
	sun.shadow_enabled = true
	root3.add_child(sun)

func _build_floor() -> void:
	var W := vp.x * K * 0.5
	var H := vp.y * K * 0.5
	var cy := CylinderMesh.new()
	cy.top_radius = 1.0
	cy.bottom_radius = 1.0
	cy.height = 0.05
	cy.radial_segments = 48
	floor_mat = Organelle3D.mat(Color("#c47ad8"), 0.06, 1.0, 0.9)
	cy.material = floor_mat
	var fl := MeshInstance3D.new()
	fl.mesh = cy
	fl.scale = Vector3(W * 1.03, 1.0, H * 1.03)
	fl.position = Vector3(0, -0.025, 0)
	root3.add_child(fl)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	sm.radial_segments = 10
	sm.rings = 5
	sm.material = Organelle3D.mat(Color("#ffb347"), 0.35)
	mm.mesh = sm
	mm.instance_count = RING_N * 2
	cell_ring = MultiMeshInstance3D.new()
	cell_ring.multimesh = mm
	root3.add_child(cell_ring)

func _build_particles() -> void:
	var W := vp.x * K
	var H := vp.y * K
	for cfg in [[80, 0.03, 0.7, 10.0], [14, 0.14, 0.15, 12.0]]:
		var p := CPUParticles3D.new()
		p.amount = int(cfg[0])
		p.lifetime = float(cfg[3])
		p.preprocess = float(cfg[3])
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(W * 0.5, 1.0, H * 0.5)
		p.direction = Vector3(1, 0.2, 0.3)
		p.spread = 180.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.03
		p.initial_velocity_max = 0.14
		var sm := SphereMesh.new()
		sm.radius = float(cfg[1])
		sm.height = float(cfg[1]) * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		sm.material = Organelle3D.mat(Color("#ffeaff"), 1.0, float(cfg[2]))
		p.mesh = sm
		p.position = Vector3(0, 0.9, 0)
		root3.add_child(p)

func _fit() -> void:
	var W := vp.x * K * 0.5 * 1.04
	var H := vp.y * K * 0.5 * 1.04
	var look := Vector3(0, 0, H * 0.06)
	var dir := Vector3(0, 0.82, 0.57).normalized()
	var corners := [Vector3(-W, 0, -H), Vector3(W, 0, -H), Vector3(-W, 0, H), Vector3(W, 0, H)]
	var d := 6.0
	while d < 40.0:
		cam.position = look + dir * d
		cam.look_at(look)
		var ok := true
		for c in corners:
			if not cam.is_position_in_frustum(c):
				ok = false
		if ok:
			break
		d += 0.5
	_base_pos = cam.position
	_base_look = look
	_look = look

func sync(lvl, delta: float) -> void:
	_t += delta
	if not _fit_done:
		_fit_frames += 1
		if _fit_frames > 2:
			_fit()
			_fit_done = true
	_sync_hero(lvl, delta)
	_sync_items(lvl)
	_sync_hazards(lvl)
	_sync_env(lvl)
	_update_cam(delta)
	_update_ring()

func _sync_hero(lvl, delta: float) -> void:
	var p3 := to3(lvl.ppos)
	hero.position = Vector3(p3.x, -float(lvl.hop_y) * K, p3.z)
	var vel := (p3 - _last_hero) / maxf(delta, 0.001)
	if _first:
		vel = Vector3.ZERO
		_first = false
	_last_hero = p3
	if vel.length() > 12.0:
		vel = Vector3.ZERO   # انتقال مفاجئ (مثلاً بداية الأسئلة)
	var ratio := vel.length() / (400.0 * K)
	if ratio > 0.1:
		hero.turn_towards(Vector2(vel.x, vel.z).normalized(), delta)
	var want := ""
	if float(lvl.inv) > 1.2:
		want = "hit"
	elif float(lvl.act_t) > 0.0 and str(lvl.phase) == "play":
		want = "collect"
	elif str(lvl.phase) == "story" and str(lvl.story_pose) == "point":
		want = "point"
	elif str(lvl.phase) == "story" and str(lvl.story_pose) == "joy":
		want = "joy"
	if want != _special:
		_special = want
		if want != "":
			hero.play(want)
	if want == "":
		hero.update_motion(ratio if str(lvl.phase) == "play" else 0.0)
	if hero.loaded:
		var targets := {"Smile": 1.0 if (want == "collect" or want == "joy") else 0.0,
			"Worried": 1.0 if want == "hit" else 0.0,
			"Surprised": 1.0 if bool(lvl.alert.visible) else 0.0}
		for k in targets:
			var cur := float(_expr.get(k, 0.0))
			cur = lerpf(cur, float(targets[k]), minf(1.0, 8.0 * delta))
			_expr[k] = cur
			hero.set_expression(String(k), cur)

func _sync_items(lvl) -> void:
	var alive := {}
	for it in lvl.items:
		var n2: Node2D = it["node"]
		if not is_instance_valid(n2):
			continue
		var id := n2.get_instance_id()
		alive[id] = true
		if not models.has(id):
			models[id] = _make_item(it)
		var m: Dictionary = models[id]
		var r: Node3D = m["root"]
		var vis := n2.visible and float(n2.modulate.a) > 0.02 and bool(it.get("active", true))
		r.visible = vis
		if not vis:
			continue
		r.position = to3(n2.position)
		r.scale = Vector3.ONE * float(n2.scale.x)
		var ring: Node3D = m["ring"]
		ring.visible = not bool(it["got"])
		ring.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 5.0))
		var mdl: Organelle3D = m["model"]
		mdl.boost = float(it["fx"].boost) if it["fx"] != null else 0.0
	for id in models.keys():
		if not alive.has(id):
			(models[id]["root"] as Node3D).queue_free()
			models.erase(id)

func _make_item(it: Dictionary) -> Dictionary:
	var nm := str(it["name"])
	var d := float(it["r"]) * 2.0 * K
	var root := Node3D.new()
	root3.add_child(root)
	var mdl := Organelle3D.new()
	mdl.kind = str(KINDS.get(nm, "orb"))
	mdl.size = d if mdl.kind != "orb" else d * 0.8
	if mdl.kind == "orb":
		var hc: Color = (it["halo"] as Sprite2D).modulate
		mdl.tint = Color(hc.r, hc.g, hc.b)
	root.add_child(mdl)
	mdl.build()
	var tm := TorusMesh.new()
	tm.inner_radius = d * 0.55
	tm.outer_radius = d * 0.58
	tm.rings = 32
	tm.ring_segments = 6
	tm.material = Organelle3D.mat(Color("#ffe34d"), 1.5, 0.6)
	var ring := MeshInstance3D.new()
	ring.mesh = tm
	ring.position = Vector3(0, 0.02, 0)
	root.add_child(ring)
	var lab := Label3D.new()
	lab.text = nm
	lab.font_size = 56
	lab.pixel_size = 0.004
	lab.outline_size = 12
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.position = Vector3(0, d * 0.55 + 0.35, 0)
	root.add_child(lab)
	return {"root": root, "model": mdl, "ring": ring, "label": lab}

func _sync_hazards(lvl) -> void:
	for hi in lvl.hazards.size():
		var h: Dictionary = lvl.hazards[hi]
		var s: Sprite2D = h["node"]
		var id := s.get_instance_id()
		if not germs.has(id):
			var g := Germ3D.new()
			g.kind = "virus" if hi % 2 == 0 else "bact"
			g.size = 0.62
			root3.add_child(g)
			g.build()
			germs[id] = g
		var g3: Germ3D = germs[id]
		g3.visible = bool(lvl.hazards_on) and s.visible and float(s.modulate.a) > 0.02
		if g3.visible:
			g3.position = to3(s.position)
			g3.rotation.y = -s.rotation * 1.5

func _sync_env(lvl) -> void:
	var e := str(lvl.env)
	if e != _env:
		_env = e
		if prok != null and is_instance_valid(prok):
			prok.queue_free()
			prok = null
		if e == "primitive" or e == "forming":
			floor_mat.albedo_color = Color("#6fd6c0")
			world_env.background_color = Color("#1d4a58")
			prok = Organelle3D.new()
			prok.kind = "prokaryote"
			prok.size = 2.6
			prok.position = to3(Vector2(vp.x * 0.5, vp.y * 0.42))
			root3.add_child(prok)
			prok.build()
		else:
			floor_mat.albedo_color = Color("#c47ad8")
			world_env.background_color = Color("#4a2370")
	if prok != null and is_instance_valid(prok) and lvl.prok != null and is_instance_valid(lvl.prok):
		if bool(lvl.prok.formed):
			prok.form_nucleus()

func _update_cam(delta: float) -> void:
	var tp := _base_pos
	var tl := _base_look
	if _focus:
		var hp := hero.position
		tp = hp + Vector3(0, 3.4, 3.0)
		tl = hp + Vector3(0, 0.3, 1.9)
	var k := 1.0 - exp(-4.0 * delta)
	cam.position = cam.position.lerp(tp, k)
	_look = _look.lerp(tl, k)
	if (cam.position - _look).length() > 0.1:
		cam.look_at(_look)

func _update_ring() -> void:
	var rx := vp.x * K * 0.5 * 1.03
	var rz := vp.y * K * 0.5 * 1.03
	var mm := cell_ring.multimesh
	for i in RING_N:
		var a := TAU * float(i) / float(RING_N)
		var wob := 1.0 + 0.012 * sin(a * 7.0 + _t * 0.9) + 0.008 * sin(a * 13.0 - _t * 1.3)
		var px := cos(a) * rx * wob
		var pz := sin(a) * rz * wob
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(px, 0.1 + 0.03 * sin(_t * 2.0 + float(i)), pz)))
		mm.set_instance_transform(RING_N + i, Transform3D(Basis(), Vector3(px, 0.32, pz)))

func set_focus(on: bool) -> void:
	_focus = on

func burst(p: Vector2, r: float) -> void:
	var pos := to3(p)
	var tm := TorusMesh.new()
	tm.inner_radius = r * K * 0.9
	tm.outer_radius = r * K
	tm.rings = 24
	tm.ring_segments = 8
	var m := Organelle3D.mat(Color("#fff27a"), 2.0, 0.8)
	tm.material = m
	var ring := MeshInstance3D.new()
	ring.mesh = tm
	ring.position = pos + Vector3(0, 0.15, 0)
	root3.add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 2.2, 0.8)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.8)
	tw.chain().tween_callback(ring.queue_free)
	for i in 8:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		sm.radial_segments = 8
		sm.rings = 4
		sm.material = Organelle3D.mat(Color("#fff27a"), 2.5)
		s.mesh = sm
		s.position = pos + Vector3(0, 0.3, 0)
		root3.add_child(s)
		var dir := Vector3(cos(float(i) * TAU / 8.0), 0.4, sin(float(i) * TAU / 8.0))
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(s, "position", pos + Vector3(0, 0.3, 0) + dir * (r * K * 1.8), 0.7)
		tw2.tween_property(s, "scale", Vector3.ZERO, 0.7)
		tw2.chain().tween_callback(s.queue_free)
