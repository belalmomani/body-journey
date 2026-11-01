extends Node3D
# معاينة تجريبية لرائد ثلاثي الأبعاد على الجهاز: حركات، تعابير، تدوير بالسحب.
const ANIMS := [["idle", "وقوف"], ["walk", "مشي"], ["run", "جري"], ["turn", "التفات"], ["point", "إشارة"], ["joy", "فرح"],
	["surprised", "دهشة"], ["worried", "قلق"], ["hit", "ضربة"], ["collect", "التقاط"], ["celebrate", "احتفال"], ["talk", "حديث"]]
const EXPRS := [["Smile", "ابتسامة"], ["Surprised", "دهشة"], ["Worried", "قلق"], ["Blink", "رمش"], ["Brows_Up", "حواجب"], ["Mouth_Open", "فم"]]
var hero: Hero3D
var cam: Camera3D
var info: Label

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#cfe6ff")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 0.9
	cyl.height = 0.04
	ground.mesh = cyl
	ground.position = Vector3(0, -0.02, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#9bd3a8")
	ground.material_override = gm
	add_child(ground)
	hero = Hero3D.new()
	add_child(hero)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.position = Vector3(0, 0.75, 2.8)
	add_child(cam)
	cam.current = true
	cam.look_at(Vector3(0, 0.6, 0))
	_ui()
	await get_tree().process_frame
	info.text = "عظام: %d  |  حركات: %d  |  تعابير: %d  |  تحميل: %s" % [
		hero.skeleton.get_bone_count() if hero.skeleton else 0,
		hero.anim.get_animation_list().size() if hero.anim else 0,
		EXPRS.size(), "نجح" if hero.loaded else "فشل"]

func _ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	info = UI.glow_label("", 24, Color("#1d2a5a"))
	info.set_anchors_preset(Control.PRESET_TOP_WIDE)
	info.offset_top = 20.0
	info.offset_bottom = 120.0
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	root.add_child(info)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 12.0
	panel.offset_right = -12.0
	panel.offset_top = -520.0
	panel.offset_bottom = -12.0
	panel.add_theme_stylebox_override("panel", UI.holo_style())
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UI.glow_label("الحركات (اسحب فوق لتدوير رائد)", 26))
	var g1 := GridContainer.new()
	g1.columns = 4
	g1.add_theme_constant_override("h_separation", 8)
	g1.add_theme_constant_override("v_separation", 8)
	v.add_child(g1)
	for a in ANIMS:
		var n: String = a[0]
		g1.add_child(_small(a[1], func(): hero.play(n)))
	v.add_child(UI.glow_label("تعابير الوجه (اضغط للتبديل)", 26))
	var g2 := GridContainer.new()
	g2.columns = 4
	g2.add_theme_constant_override("h_separation", 8)
	g2.add_theme_constant_override("v_separation", 8)
	v.add_child(g2)
	for e in EXPRS:
		var en: String = e[0]
		g2.add_child(_small(e[1], func(): _toggle(en)))
	g2.add_child(_small("إعادة ضبط", func(): hero.clear_expressions()))
	v.add_child(UI.button("رجوع", func(): GameState.go("res://scenes/settings.tscn"), Color("#6c63ff")))

func _small(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, Color("#2a9d8f"))
	b.custom_minimum_size = Vector2(0, 66)
	b.add_theme_font_size_override("font_size", 26)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

func _toggle(n: String) -> void:
	var to := 0.0 if hero.get_expression(n) > 0.5 else 1.0
	var tw := create_tween()
	tw.tween_method(func(x: float): hero.set_expression(n, x), hero.get_expression(n), to, 0.2)

func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var mm: InputEventMouseMotion = e
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and mm.position.y < get_viewport().get_visible_rect().size.y * 0.5:
			hero.rotation.y += mm.relative.x * 0.01
