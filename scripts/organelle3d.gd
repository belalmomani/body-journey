class_name Organelle3D
extends Node3D
# عضيات ثلاثية الأبعاد مبنية من مجسمات بدائية (بلا ملفات خارجية) مع حركة وظيفية مبسّطة.
var kind := "nucleus"      # nucleus | mito | ribo | er | golgi | membrane | orb | prokaryote
var size := 1.0            # القطر التقريبي بالمتر
var tint := Color(1.0, 0.9, 0.2)
var boost := 0.0           # يزداد عند اقتراب اللاعب (0..1)
var formed := false
var t := 0.0
var _anim: Array = []      # عقد متحركة: {n: Node3D, a: float, b: float, c: float}
var _R := 0.5

static func mat(c: Color, em := 0.0, alpha := 1.0, rough := 0.55) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = rough
	if em > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = em
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _add(mesh: PrimitiveMesh, m: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	add_child(mi)
	return mi

func _sph(r: float, c: Color, pos := Vector3.ZERO, em := 0.0, alpha := 1.0) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	return _add(s, mat(c, em, alpha), pos)

func _torus(inner: float, outer: float, c: Color, pos := Vector3.ZERO, em := 0.0, alpha := 1.0, scl := Vector3.ONE) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 32
	tm.ring_segments = 10
	return _add(tm, mat(c, em, alpha), pos, Vector3.ZERO, scl)

func build() -> void:
	_R = size * 0.5
	if kind == "nucleus":
		_nucleus()
	elif kind == "mito":
		_mito()
	elif kind == "ribo":
		_ribo()
	elif kind == "er":
		_er()
	elif kind == "golgi":
		_golgi()
	elif kind == "membrane":
		_membrane()
	elif kind == "prokaryote":
		_prokaryote()
	else:
		_sph(_R, tint, Vector3(0, _R, 0), 0.8)

func _nucleus() -> void:
	var R := _R
	_sph(R, Color("#8e4fd9"), Vector3(0, R, 0), 0.25)
	_sph(R * 0.28, Color("#5a2aa8"), Vector3(0, R * 1.18, R * 0.62), 0.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 8:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1), rng.randf_range(-1, 1)).normalized()
		_sph(R * 0.07, Color("#3a1a70"), Vector3(0, R, 0) + d * R * 0.98)
	for j in 2:
		var tr := _torus(R * 1.0, R * 1.05, Color("#d2b6ff"), Vector3(0, R * 0.15, 0), 1.0, 0.5)
		_anim.append({"n": tr, "a": float(j) * 0.5, "b": 0.0, "c": 0.0})
	for i in 4:
		var s := _sph(R * 0.05, Color("#b8e0ff"), Vector3(0, R, 0), 1.2)
		_anim.append({"n": s, "a": float(i) * 0.25, "b": float(i) * TAU / 4.0 + 0.6, "c": 0.0})

func _mito() -> void:
	var L := size
	var cap := CapsuleMesh.new()
	cap.radius = L * 0.22
	cap.height = L
	_add(cap, mat(Color("#ff8c1a"), 0.15, 0.62), Vector3(0, L * 0.24, 0), Vector3(0, 0, 90))
	for i in 5:
		var cy := CylinderMesh.new()
		cy.top_radius = L * 0.17
		cy.bottom_radius = L * 0.17
		cy.height = L * 0.03
		_add(cy, mat(Color("#ffd08a"), 0.2), Vector3(-L * 0.32 + float(i) * L * 0.16, L * 0.24, 0), Vector3(0, 0, 90))
	for i in 8:
		var s := _sph(L * 0.025, Color("#fff27a"), Vector3(0, L * 0.3, 0), 2.0)
		_anim.append({"n": s, "a": float(i) / 8.0, "b": float(i) * 2.0, "c": 0.0})

func _ribo() -> void:
	var R := _R
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 12:
		var p := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * R * 0.7
		_sph(R * 0.13, Color("#ffd23f"), Vector3(p.x, R * 0.13, p.z), 0.3)
	for i in 7:
		var b := _sph(R * 0.09, Color.from_hsv(0.08 + float(i) * 0.11, 0.65, 1.0), Vector3(R * 0.9 + float(i) * R * 0.2, R * 0.9 + sin(float(i) * 0.9) * R * 0.18, 0), 0.4)
		_anim.append({"n": b, "a": float(i), "b": 0.0, "c": 0.0})

func _er() -> void:
	var R := _R
	for i in 3:
		var tr := _torus(R * 0.5, R * 0.95, Color("#3aa0ff"), Vector3(0, R * 0.12 + float(i) * R * 0.22, 0), 0.15, 0.92, Vector3(1.0, 1.0, 0.65))
		tr.rotation_degrees = Vector3(0, 18.0 * float(i) - 10.0, 0)
	for i in 6:
		var s := _sph(R * 0.07, Color("#9af6ff"), Vector3(0, R * 0.6, 0), 1.5)
		_anim.append({"n": s, "a": float(i) / 6.0, "b": 0.0, "c": 0.0})

func _golgi() -> void:
	var R := _R
	for i in 5:
		var cy := CylinderMesh.new()
		cy.top_radius = R * (0.95 - 0.08 * float(i))
		cy.bottom_radius = cy.top_radius
		cy.height = R * 0.11
		var mi := _add(cy, mat(Color("#5fd35f"), 0.12), Vector3(0, R * 0.12 + float(i) * R * 0.17, 0))
		mi.rotation_degrees = Vector3(0, 0, 6.0)
		mi.scale = Vector3(1.0, 1.0, 0.8)
	for i in 4:
		var s := _sph(R * 0.1, Color("#ffcc4d"), Vector3(0, R * 0.5, 0), 0.5)
		_anim.append({"n": s, "a": float(i) * TAU / 4.0, "b": 0.0, "c": 0.0})

func _membrane() -> void:
	var R := _R
	var rm := R * 0.9
	for i in 15:
		var a := deg_to_rad(-70.0 + float(i) * 10.0)
		var pv := Node3D.new()
		pv.rotation.y = a
		pv.position = Vector3(0, R * 0.3, 0)
		add_child(pv)
		for sgn in [1.0, -1.0]:
			var hs := SphereMesh.new()
			hs.radius = R * 0.075
			hs.height = R * 0.15
			var hm := MeshInstance3D.new()
			hm.mesh = hs
			hs.material = mat(Color("#ffd23f"), 0.25)
			hm.position = Vector3(rm + sgn * R * 0.2, 0, 0)
			pv.add_child(hm)
			var cy := CylinderMesh.new()
			cy.top_radius = R * 0.025
			cy.bottom_radius = R * 0.025
			cy.height = R * 0.14
			cy.material = mat(Color("#ff9a3c"), 0.1)
			var tm := MeshInstance3D.new()
			tm.mesh = cy
			tm.position = Vector3(rm + sgn * R * 0.09, 0, 0)
			tm.rotation_degrees = Vector3(0, 0, 90)
			pv.add_child(tm)
	for i in 5:
		var s := _sph(R * 0.05, Color("#e8ffd0"), Vector3(0, R * 0.3, 0), 1.2)
		_anim.append({"n": s, "a": float(i) * 0.2, "b": deg_to_rad(-50.0 + float(i) * 25.0), "c": 0.0})

func _prokaryote() -> void:
	var L := size
	var cap := CapsuleMesh.new()
	cap.radius = L * 0.22
	cap.height = L
	_add(cap, mat(Color("#7fe8c6"), 0.2, 0.38), Vector3(0, L * 0.24, 0), Vector3(0, 0, 90))
	var cap2 := CapsuleMesh.new()
	cap2.radius = L * 0.245
	cap2.height = L * 1.06
	_add(cap2, mat(Color("#5fc9a8"), 0.1, 0.18), Vector3(0, L * 0.24, 0), Vector3(0, 0, 90))
	var dna := _torus(L * 0.07, L * 0.09, Color("#ff7ad9"), Vector3(0, L * 0.24, 0), 1.0)
	_anim.append({"n": dna, "a": 0.0, "b": 0.0, "c": 0.0})
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 14:
		_sph(L * 0.016, Color("#ffd23f"), Vector3(rng.randf_range(-0.38, 0.38) * L, L * 0.24 + rng.randf_range(-0.14, 0.14) * L, rng.randf_range(-0.14, 0.14) * L), 0.4)

func form_nucleus() -> void:
	if formed:
		return
	formed = true
	var e := _sph(size * 0.2, Color("#b890ff"), Vector3(0, size * 0.24, 0), 0.6, 0.3)
	e.scale = Vector3.ONE * 0.1
	create_tween().tween_property(e, "scale", Vector3.ONE, 0.8)

func _process(delta: float) -> void:
	t += delta
	var R := _R
	var k := 0.55 + 0.45 * boost
	for a in _anim:
		var n: Node3D = a["n"]
		if kind == "nucleus":
			if n is MeshInstance3D and (n as MeshInstance3D).mesh is TorusMesh:
				var p := fmod(t * 0.45 + float(a["a"]), 1.0)
				n.scale = Vector3.ONE * (1.0 + 0.6 * p)
				var mm := ((n as MeshInstance3D).mesh as TorusMesh).material as StandardMaterial3D
				mm.albedo_color.a = 0.5 * (1.0 - p) * k
			else:
				var p2 := fmod(t * 0.35 + float(a["a"]), 1.0)
				var d := Vector3(cos(float(a["b"])), 0.0, sin(float(a["b"])))
				n.position = Vector3(0, R, 0) + d * (R * 0.6 + p2 * R * 0.9)
		elif kind == "mito":
			var pm := fmod(t * 0.55 + float(a["a"]), 1.0)
			n.position = Vector3(sin(pm * 7.0 + float(a["b"])) * size * 0.3, size * 0.3 + pm * size * 0.5, sin(float(a["b"])) * size * 0.1)
			n.scale = Vector3.ONE * sin(pm * PI) * (0.8 + boost)
		elif kind == "er":
			var pe := fmod(t * 0.3 + float(a["a"]), 1.0)
			var ang := pe * TAU
			n.position = Vector3(cos(ang) * R * 0.75, R * 0.65, sin(ang) * R * 0.5)
		elif kind == "ribo":
			var cnt := 1 + int(fmod(t * 0.9, 1.0) * 6.0)
			n.visible = float(a["a"]) < float(cnt)
		elif kind == "golgi":
			var ag := t * 0.7 + float(a["a"])
			n.position = Vector3(cos(ag) * R * 1.15, R * 0.55, sin(ag) * R * 0.75)
		elif kind == "membrane":
			var pb := fmod(t * 0.35 + float(a["a"]), 1.0)
			var rr := R * 0.9 + lerpf(R * 0.5, -R * 0.5, pb)
			n.position = Vector3(cos(float(a["b"])) * rr, R * 0.3, sin(float(a["b"])) * rr)
		elif kind == "prokaryote":
			n.scale = Vector3.ONE * (1.0 + 0.06 * sin(t * 1.2))
			n.rotation.y = t * 0.3
