class_name Germ3D
extends Node3D
# جرثومة ثلاثية الأبعاد بوجه غاضب: فيروس بنتوءات أو بكتيريا كبسولية. الوجه نحو +Z.
var kind := "virus"
var size := 0.6
var t := 0.0

func _add(mesh: PrimitiveMesh, m: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	add_child(mi)
	return mi

func _sph(r: float, c: Color, pos: Vector3, em := 0.0) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return _add(s, Organelle3D.mat(c, em), pos)

func build() -> void:
	var r := size * 0.5
	var face_z := r
	if kind == "virus":
		_sph(r, Color("#7bc043"), Vector3(0, r, 0), 0.1)
		for i in 14:
			var y := 1.0 - 2.0 * (float(i) + 0.5) / 14.0
			var rad := sqrt(1.0 - y * y)
			var th := float(i) * 2.399963
			var dir := Vector3(cos(th) * rad, y, sin(th) * rad)
			var sp := CylinderMesh.new()
			sp.top_radius = size * 0.03
			sp.bottom_radius = size * 0.045
			sp.height = size * 0.2
			var mi := _add(sp, Organelle3D.mat(Color("#5a9e2b")), Vector3(0, r, 0) + dir * (r + size * 0.08))
			mi.basis = Basis(Quaternion(Vector3.UP, dir))
			_sph(size * 0.05, Color("#b9e36b"), Vector3(0, r, 0) + dir * (r + size * 0.18), 0.2)
	else:
		var cap := CapsuleMesh.new()
		cap.radius = size * 0.3
		cap.height = size * 1.3
		_add(cap, Organelle3D.mat(Color("#8e44d6"), 0.1), Vector3(0, size * 0.3, 0), Vector3(0, 0, 90))
		face_z = size * 0.3
		r = size * 0.3
		for i in 6:
			_sph(size * 0.04, Color("#c79bff"), Vector3(-size * 0.5 + float(i) * size * 0.2, size * 0.3 + size * 0.3, 0))
	# وجه غاضب
	var ey := r * (1.0 if kind == "virus" else 1.05)
	for sx in [-1.0, 1.0]:
		_sph(size * 0.11, Color.WHITE, Vector3(sx * size * 0.16, ey + size * 0.05, face_z * 0.92))
		_sph(size * 0.055, Color("#1a1a2a"), Vector3(sx * size * 0.16, ey + size * 0.04, face_z * 0.92 + size * 0.08))
		var br := BoxMesh.new()
		br.size = Vector3(size * 0.2, size * 0.04, size * 0.04)
		_add(br, Organelle3D.mat(Color("#1d2a1a")), Vector3(sx * size * 0.16, ey + size * 0.2, face_z * 0.95), Vector3(0, 0, -sx * 22.0))
	var mo := SphereMesh.new()
	mo.radius = size * 0.12
	mo.height = size * 0.1
	_add(mo, Organelle3D.mat(Color("#2a0e18")), Vector3(0, ey - size * 0.16, face_z * 0.96))

func _process(delta: float) -> void:
	t += delta
	scale = Vector3.ONE * (1.0 + 0.05 * sin(t * 6.0))
