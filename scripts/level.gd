extends Control
# محرك مرحلة عام. عالم اللعب من Node2D/Sprite2D (لا يتأثر باتجاه الواجهة RTL)، والواجهة في CanvasLayer.
const SPEED := 400.0
const BUILD := "v11"
const ITEM_TEX := {
	"النواة": "res://assets/cell/nucleus.png",
	"الميتوكوندريا": "res://assets/cell/mito.png",
	"الريبوسوم": "res://assets/cell/ribo.png",
	"الغشاء": "res://assets/cell/membrane.png",
	"الشبكة الإندوبلازمية": "res://assets/cell/er.png",
	"جهاز جولجي": "res://assets/cell/golgi.png",
}
const ITEM_SIZE := {"النواة": 300.0, "الميتوكوندريا": 210.0, "الريبوسوم": 180.0, "الغشاء": 220.0, "الشبكة الإندوبلازمية": 210.0, "جهاز جولجي": 200.0}
const ITEM_POS := {"النواة": Vector2(0.50, 0.40), "الميتوكوندريا": Vector2(0.22, 0.24), "الشبكة الإندوبلازمية": Vector2(0.78, 0.25), "جهاز جولجي": Vector2(0.80, 0.55), "الريبوسوم": Vector2(0.20, 0.50), "الغشاء": Vector2(0.76, 0.76)}
const ITEM_KIND := {"النواة": "nucleus", "الميتوكوندريا": "mito", "الريبوسوم": "ribo", "الغشاء": "membrane", "الشبكة الإندوبلازمية": "er", "جهاز جولجي": "golgi"}
const HINTS := {
	"النواة": "ما هذا الشيء الكبير؟ إنها النواة… مركز التحكم!",
	"الميتوكوندريا": "أرى ومضات طاقة تتصاعد من هناك!",
	"الريبوسوم": "جسيمات صغيرة تبني شيئاً ما!",
	"الغشاء": "هذا الغشاء يحرس الخلية ويُدخل إليها الغذاء!",
	"الشبكة الإندوبلازمية": "مواد تنتقل عبر هذه الشبكة!",
	"جهاز جولجي": "حويصلات صغيرة تدور وتخرج من هنا!",
}
var lv := {}
var phase := "intro"   # intro | play | quiz | puzzle | result
var world: Node2D
var player: Sprite2D
var idle_tex: Texture2D
var run_frames: Array = []
var act_tex: Texture2D
var act_t := 0.0
var toast: Control
var qpanel: QuestionPanel
var explanations := {}
var ppos := Vector2(360, 1000)
var pad_dir := Vector2.ZERO
var dpad: DPad
var kb := Vector2.ZERO
var idle_t := 0.0
var puff_t := 0.0
var hop_y := 0.0
var shake_rot := 0.0
var base_k := 1.0
var turn_tex: Texture2D
var point_tex: Texture2D
var glow_tex: GradientTexture2D
var shadow: Sprite2D
var alert: Label
var learn := {}
var world_back: CellWorld
var world_front: CellWorld
var hazards_on := true
var hints_seen := {}
var point_t := 0.0
var look_item: Node2D
var collected := 0
var stories := {}
var items: Array = []
var hazards: Array = []
var hearts := 3
var score := 0
var inv := 0.0
var t := 0.0
var run_t := 0.0
var hud: Label
var overlay: Control
var ui_layer: CanvasLayer
var qi := 0
var qok := 0
var pmiss := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sf := FileAccess.open("res://data/stories.json", FileAccess.READ)
	if sf:
		var sj = JSON.parse_string(sf.get_as_text())
		if sj is Dictionary:
			stories = sj
	var lf := FileAccess.open("res://data/learn.json", FileAccess.READ)
	if lf:
		var lj = JSON.parse_string(lf.get_as_text())
		if lj is Dictionary:
			learn = lj
	var ef := FileAccess.open("res://data/explanations.json", FileAccess.READ)
	if ef:
		var ej = JSON.parse_string(ef.get_as_text())
		if ej is Dictionary:
			explanations = ej
	lv = GameState.levels.get(GameState.selected_level, {})
	var src := "json"
	if lv.is_empty():
		lv = _fallback()
		src = "fallback"
	rng.seed = GameState.selected_level * 7919
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/bg_cell_deep.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color.WHITE if GameState.selected_level == 1 else Color(lv.get("color", "#ffffff")).lerp(Color.WHITE, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	world = Node2D.new()
	add_child(world)
	var vps := get_viewport_rect().size
	ppos = Vector2(vps.x * 0.62, vps.y * 0.8)
	world_back = CellWorld.new()
	world.add_child(world_back)
	world_back.setup("back", 46)
	var tex_item: Texture2D = load("res://assets/characters/item.svg")
	for nm in lv.get("items", []):
		var n := Node2D.new()
		if GameState.selected_level == 1 and ITEM_POS.has(nm):
			n.position = Vector2(vps.x * float(ITEM_POS[nm].x), vps.y * float(ITEM_POS[nm].y))
		else:
			n.position = _free_spot()
		var halo := Sprite2D.new()
		halo.texture = tex_item
		n.add_child(halo)
		var body := Sprite2D.new()
		var bt: Texture2D = tex_item
		var bs := 110.0
		if ITEM_TEX.has(nm):
			bt = load(ITEM_TEX[nm])
			bs = float(ITEM_SIZE.get(nm, 150.0))
		halo.scale = Vector2.ONE * ((bs * 1.5) / 128.0)
		halo.modulate = Color(1, 0.9, 0.2, 0.4)
		body.texture = bt
		body.scale = Vector2.ONE * (bs / maxf(bt.get_width(), bt.get_height()))
		n.add_child(body)
		var fxn: OrganelleFX = null
		if ITEM_KIND.has(nm):
			fxn = OrganelleFX.new()
			fxn.kind = ITEM_KIND[nm]
			fxn.r = bs * 0.5
			n.add_child(fxn)
		var l := UI.label(nm, 24)
		l.size = Vector2(200, 32)
		l.position = Vector2(-100, bs * 0.5 + 8.0)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", Color("#3b1a5a"))
		l.add_theme_constant_override("outline_size", 8)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.add_child(l)
		world.add_child(n)
		items.append({"node": n, "name": nm, "got": false, "halo": halo, "base": n.position, "fx": fxn, "r": bs * 0.5, "hs": (bs * 1.5) / 128.0})
	var germ_tex: Array = [load("res://assets/enemies/virus.png"), load("res://assets/enemies/bact.png")]
	for i in int(lv.get("hazards", 2)):
		var h := Sprite2D.new()
		var gt: Texture2D = germ_tex[i % 2]
		h.texture = gt
		h.set_meta("s", 120.0 / maxf(gt.get_width(), gt.get_height()))
		h.scale = Vector2.ONE * float(h.get_meta("s"))
		h.position = _free_spot()
		if GameState.selected_level == 1:
			h.visible = false
		world.add_child(h)
		var sp := 110.0 + 25.0 * int(lv.get("difficulty", 1))
		hazards.append({"node": h, "vel": Vector2.from_angle(rng.randf() * TAU) * sp})
	hazards_on = GameState.selected_level != 1
	idle_tex = load("res://assets/characters/hero/hero_idle.png")
	act_tex = load("res://assets/characters/hero/hero_interact.png")
	run_frames = [load("res://assets/characters/hero/hero_run.png"), load("res://assets/characters/hero/hero_walk.png")]
	turn_tex = load("res://assets/characters/hero/hero_turn.png")
	point_tex = load("res://assets/characters/hero/hero_point.png")
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 0.9))
	gr.set_color(1, Color(1, 1, 1, 0.0))
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = gr
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 128
	glow_tex.height = 128
	shadow = Sprite2D.new()
	shadow.texture = glow_tex
	shadow.modulate = Color(0, 0, 0, 0.5)
	shadow.scale = Vector2(1.6, 0.42)
	world.add_child(shadow)
	player = Sprite2D.new()
	_set_player_tex(idle_tex)
	player.position = ppos
	world.add_child(player)
	world_front = CellWorld.new()
	world.add_child(world_front)
	world_front.setup("front", 10)
	alert = Label.new()
	alert.text = "!"
	alert.add_theme_font_size_override("font_size", 64)
	alert.add_theme_color_override("font_color", Color("#ff4d4d"))
	alert.add_theme_color_override("font_outline_color", Color.WHITE)
	alert.add_theme_constant_override("outline_size", 10)
	alert.visible = false
	world.add_child(alert)
	# --- واجهة ---
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.8)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 100.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(bar)
	hud = UI.label("", 28)
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_top = 14.0
	hud.offset_bottom = 94.0
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)
	var dbg := Label.new()
	dbg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dbg.text = "build %s | items:%d | src:%s" % [BUILD, items.size(), src]
	dbg.anchor_top = 1.0
	dbg.anchor_bottom = 1.0
	dbg.offset_left = 10.0
	dbg.offset_right = 600.0
	dbg.offset_top = -40.0
	dbg.offset_bottom = -6.0
	dbg.add_theme_font_size_override("font_size", 22)
	dbg.add_theme_color_override("font_color", Color("#c0392b"))
	dbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(dbg)
	dpad = DPad.new()
	dpad.anchor_left = 0.0
	dpad.anchor_right = 0.0
	dpad.anchor_top = 1.0
	dpad.anchor_bottom = 1.0
	dpad.offset_left = 24.0
	dpad.offset_right = 360.0
	dpad.offset_top = -376.0
	dpad.offset_bottom = -40.0
	dpad.dir_changed.connect(func(d: Vector2): pad_dir = d)
	ui_layer.add_child(dpad)
	overlay = Control.new()
	overlay.layout_direction = Control.LAYOUT_DIRECTION_RTL
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(overlay)
	_update_hud()
	_show_intro()

func _free_spot() -> Vector2:
	for k in 40:
		var p := Vector2(rng.randf_range(110, 610), rng.randf_range(260, 900))
		var ok := true
		for it in items:
			if (it["node"] as Node2D).position.distance_to(p) < 140.0:
				ok = false
		if ok:
			return p
	return Vector2(360, 600)

func _update_hud() -> void:
	var got := 0
	for it in items:
		if it["got"]:
			got += 1
	hud.text = "%s  |  الأرواح: %d  |  جمعت: %d/%d  |  النقاط: %d" % [lv.get("title", ""), hearts, got, items.size(), score]

# ---------- لوحات ----------
func _panel(title: String, body: String) -> VBoxContainer:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 40)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 160)
	overlay.add_child(m)
	var bgp := PanelContainer.new()
	bgp.add_theme_stylebox_override("panel", UI.holo_style())
	m.add_child(bgp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	bgp.add_child(v)
	v.add_child(UI.glow_label(title, 44))
	if body != "":
		v.add_child(UI.glow_label(body, 30))
	return v

func _close_panel() -> void:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_intro() -> void:
	phase = "intro"
	var st: Dictionary = stories.get(str(GameState.selected_level), {})
	var story := str(st.get("intro", lv.get("dialogue", "")))
	var v := _panel(lv.get("title", ""), story + "\n\n" + "اجمع العناصر المضيئة، وتجنّب الجراثيم، ثم أجب عن الأسئلة.")
	var g := TextureRect.new()
	g.texture = load("res://assets/characters/hero/hero_idle.png")
	g.custom_minimum_size = Vector2(0, 170)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(g)
	v.move_child(g, 0)
	GameState.speak(story)
	v.add_child(UI.button("هيا نبدأ", _on_start))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- اللعب ----------
func _process(delta: float) -> void:
	t += delta
	world_back.focus = ppos
	world_front.focus = ppos
	point_t = maxf(0.0, point_t - delta)
	dpad.visible = phase == "play"
	if phase != "play":
		pad_dir = Vector2.ZERO
		return
	AdManager.add_play_time(delta)
	act_t = maxf(0.0, act_t - delta)
	var vp := get_viewport_rect().size
	var kd := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dirv := pad_dir if pad_dir != Vector2.ZERO else kd
	var moving := dirv.length() > 0.1
	if moving:
		ppos += dirv.normalized() * SPEED * delta
		run_t += delta
		idle_t = 0.0
		if absf(dirv.x) > 0.25:
			player.flip_h = dirv.x < 0.0
		puff_t -= delta
		if puff_t <= 0.0:
			puff_t = 0.16
			_spawn_puff(ppos + Vector2(0.0, 108.0))
	else:
		idle_t += delta
	ppos += kb * delta
	kb = kb.move_toward(Vector2.ZERO, 900.0 * delta)
	ppos = Vector2(clampf(ppos.x, 50.0, vp.x - 50.0), clampf(ppos.y, 190.0, vp.y - 120.0))
	# --- الوضعية والحركة (تنفّس، خطوات، إشارة إلى أقرب عنصر) ---
	var bob := 2.0 * sin(t * 2.4)
	var sq := 0.012 * sin(t * 2.4)
	var lean := 0.0
	var near_item := _nearest_item()
	if act_t > 0.0:
		_set_player_tex(act_tex)
	elif point_t > 0.0 and look_item != null:
		player.flip_h = look_item.position.x < ppos.x
		_set_player_tex(point_tex)
		bob = -4.0 * absf(sin(t * 7.0))
	elif moving:
		var nd := dirv.normalized()
		if nd.y < -0.6 and absf(nd.x) < 0.55:
			_set_player_tex(turn_tex)
		elif nd.y > 0.6 and absf(nd.x) < 0.55:
			_set_player_tex(idle_tex)
		else:
			_set_player_tex(run_frames[int(run_t * 9.0) % 2])
		bob = -7.0 * absf(sin(run_t * 14.0))
		sq = 0.05 * sin(run_t * 28.0)
		lean = 0.07 * sin(run_t * 14.0) + 0.05 * nd.x
	elif idle_t > 2.0 and near_item != null:
		player.flip_h = near_item.position.x < ppos.x
		_set_player_tex(point_tex)
		bob = -5.0 * absf(sin(t * 5.0))
	else:
		_set_player_tex(idle_tex)
	player.rotation = lean + shake_rot
	player.scale = Vector2(base_k * (1.0 + sq), base_k * (1.0 - sq))
	player.position = ppos + Vector2(0.0, bob + hop_y)
	shadow.position = ppos + Vector2(0.0, 98.0)
	inv = maxf(0.0, inv - delta)
	if inv > 1.2:
		player.modulate = Color(1.0, 0.55, 0.55, 1.0)
	else:
		player.modulate = Color(1, 1, 1, 0.4 if (inv > 0.0 and int(t * 10.0) % 2 == 0) else 1.0)
	# --- الجراثيم ---
	var near := 9999.0
	for hi in hazards.size():
		var h: Dictionary = hazards[hi]
		if not hazards_on:
			continue
		var n: Sprite2D = h["node"]
		var vel: Vector2 = h["vel"]
		if hi % 2 == 1:
			vel = vel.rotated(0.9 * sin(t * 2.0 + float(hi)) * delta)
		n.position += vel * delta
		if n.position.x < 50.0 or n.position.x > vp.x - 50.0:
			vel.x = -vel.x
			n.position.x = clampf(n.position.x, 50.0, vp.x - 50.0)
		if n.position.y < 160.0 or n.position.y > vp.y - 60.0:
			vel.y = -vel.y
			n.position.y = clampf(n.position.y, 160.0, vp.y - 60.0)
		h["vel"] = vel
		n.rotation = 0.15 * sin(t * 3.0 + n.position.x)
		n.flip_h = vel.x < 0.0
		n.scale = Vector2.ONE * float(n.get_meta("s")) * (1.0 + 0.06 * sin(t * 6.0 + n.position.x))
		var dist := n.position.distance_to(ppos)
		near = minf(near, dist)
		if inv <= 0.0 and dist < 70.0:
			hearts -= 1
			inv = 1.5
			GameState.sfx("hit")
			kb = (ppos - n.position).normalized() * 420.0
			_shake()
			_update_hud()
			if hearts <= 0:
				_fail()
				return
	alert.visible = near < 230.0 and inv <= 0.0
	alert.position = ppos + Vector2(-14.0, -230.0 + 5.0 * sin(t * 12.0))
	# --- العناصر ---
	var all := true
	for it in items:
		if not it["got"]:
			all = false
			var nn: Node2D = it["node"]
			var rr: float = float(it["r"])
			var dd := nn.position.distance_to(ppos)
			nn.position.y = float(it["base"].y) + 5.0 * sin(t * 3.0 + float(it["base"].x))
			var hl: Sprite2D = it["halo"]
			hl.modulate.a = 0.25 + 0.2 * sin(t * 5.0)
			hl.scale = Vector2.ONE * float(it["hs"]) * (1.0 + 0.06 * sin(t * 5.0))
			if it["fx"] != null:
				(it["fx"] as OrganelleFX).boost = clampf(1.0 - (dd - rr) / 300.0, 0.0, 1.0)
			if GameState.selected_level == 1 and HINTS.has(it["name"]) and not hints_seen.has(it["name"]) and dd < rr + 280.0:
				hints_seen[it["name"]] = true
				_say(str(HINTS[it["name"]]), 3.2)
				look_item = nn
				point_t = 1.0
				_hop()
			if dd < rr * 0.55 + 55.0:
				it["got"] = true
				_pop(nn)
				_burst(nn.position, rr)
				score += 100
				collected += 1
				GameState.sfx("collect")
				act_t = 0.6
				_hop()
				_update_hud()
				_say_fact(it["name"])
				if collected == 2 and GameState.selected_level == 1 and not hazards_on:
					_activate_hazards()
	if all and not items.is_empty():
		_after_collect()

func _nearest_item() -> Node2D:
	var best: Node2D = null
	var bd := 1.0e9
	for it in items:
		if not it["got"]:
			var n: Node2D = it["node"]
			var d := n.position.distance_to(ppos)
			if d < bd:
				bd = d
				best = n
	return best

func _spawn_puff(p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = glow_tex
	s.position = p + Vector2(randf_range(-16.0, 16.0), randf_range(-4.0, 4.0))
	s.scale = Vector2.ONE * 0.18
	s.modulate = Color(1, 1, 1, 0.5)
	world.add_child(s)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2.ONE * 0.45, 0.4)
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(s.queue_free)

func _hop() -> void:
	var tw := create_tween()
	tw.tween_property(self, "hop_y", -55.0, 0.15)
	tw.tween_property(self, "hop_y", 0.0, 0.18)

func _shake() -> void:
	var tw := create_tween()
	tw.tween_property(self, "shake_rot", 0.25, 0.06)
	tw.tween_property(self, "shake_rot", -0.25, 0.08)
	tw.tween_property(self, "shake_rot", 0.0, 0.08)

# بطاقة تعليمية عند التقاط كل عنصر (قبل الأسئلة)
func _learn(nm: String) -> void:
	var texts: Dictionary = learn.get(str(GameState.selected_level), {})
	var txt := str(texts.get(nm, ""))
	if txt == "":
		return
	phase = "learn"
	var v := _panel(nm, "")
	var tr := TextureRect.new()
	if ITEM_TEX.has(nm):
		tr.texture = load(ITEM_TEX[nm])
	else:
		tr.texture = load("res://assets/characters/item.svg")
	tr.custom_minimum_size = Vector2(0, 220)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(tr)
	v.add_child(UI.glow_label(txt, 32))
	GameState.speak(txt)
	v.add_child(UI.button("استمع", func(): GameState.speak(txt), Color("#6c63ff")))
	var go := func():
		_close_panel()
		phase = "play"
	v.add_child(UI.button("فهمت! أكمل", go, Color("#2a9d8f")))

func _pop(n: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.9, 1.9), 0.25)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.25)

func _fail() -> void:
	phase = "result"
	GameState.sfx("fail")
	GameState.record_attempt(GameState.selected_level)
	var v := _panel("حاول مرة أخرى!", "لا بأس، الجراثيم سريعة. تقدمك السابق محفوظ.")
	v.add_child(UI.button("إعادة المحاولة", func(): GameState.go("res://scenes/level.tscn")))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- الأسئلة ----------
func _start_quiz() -> void:
	phase = "quiz"
	qi = 0
	qok = 0
	for h in hazards:
		(h["node"] as Node2D).visible = false
	var vp := get_viewport_rect().size
	ppos = Vector2(vp.x * 0.5, vp.y * 0.36 - 150.0)   # الشخصية تبقى ظاهرة فوق لوحة السؤال
	player.position = ppos
	player.flip_h = false
	player.rotation = 0.0
	_set_player_tex(idle_tex)
	_ask()

func _ask() -> void:
	var qs: Array = lv.get("questions", [])
	if qi >= qs.size():
		_finish()
		return
	var q: Dictionary = (qs[qi] as Dictionary).duplicate()
	if str(q.get("explain", "")) == "":
		var arr: Array = explanations.get(str(GameState.selected_level), [])
		if qi < arr.size():
			q["explain"] = arr[qi]
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	player.rotation = 0.0
	_set_player_tex(idle_tex)
	qpanel = QuestionPanel.new()
	qpanel.set_anchors_preset(Control.PRESET_FULL_RECT)
	qpanel.anchor_top = 0.36
	qpanel.offset_left = 24.0
	qpanel.offset_right = -24.0
	qpanel.offset_top = 0.0
	qpanel.offset_bottom = -30.0
	overlay.add_child(qpanel)
	qpanel.build(q, qi, qs.size(), score, GameState.selected_level)
	qpanel.answered.connect(_on_answered)
	qpanel.next_pressed.connect(func():
		qi += 1
		_ask())
	GameState.speak(str(q["q"]))

func _on_answered(ok: bool, _q: Dictionary) -> void:
	if ok:
		qok += 1
		score += 200
		GameState.sfx("collect")
	else:
		GameState.sfx("hit")
	_update_hud()
	qpanel.set_score(score)
	_hero_react(ok)

func _hero_react(ok: bool) -> void:
	_set_player_tex(act_tex if ok else idle_tex)
	var tw := create_tween()
	if ok:
		tw.tween_property(player, "position:y", ppos.y - 40.0, 0.18)
		tw.tween_property(player, "position:y", ppos.y, 0.18)
	else:
		tw.tween_property(player, "rotation", 0.12, 0.12)
		tw.tween_property(player, "rotation", -0.12, 0.12)
		tw.tween_property(player, "rotation", 0.0, 0.12)

func _finish() -> void:
	phase = "result"
	var total: int = lv.get("questions", []).size()
	var stars := 1 + (1 if hearts >= 2 else 0) + (1 if qok == total and pmiss <= 2 else 0)
	score += hearts * 50
	GameState.complete_level(GameState.selected_level, stars, score)
	GameState.sfx("win")
	var outro := str((stories.get(str(GameState.selected_level), {}) as Dictionary).get("outro", ""))
	var v := _panel("نجحت!", ("النجوم: %d من 3\nالنقاط: %d" % [stars, score]) + ("\n\n" + outro if outro != "" else ""))
	var id := GameState.selected_level
	if id < GameState.LEVEL_COUNT:
		v.add_child(UI.button("المرحلة التالية", func():
			GameState.selected_level = id + 1
			AdManager.maybe_show(func(): GameState.go("res://scenes/level.tscn"))))
	v.add_child(UI.button("إعادة المرحلة", func(): GameState.go("res://scenes/level.tscn"), Color("#2a9d8f")))
	v.add_child(UI.button("الخريطة", func(): AdManager.maybe_show(func(): GameState.go("res://scenes/map.tscn")), Color("#8d99ae")))

# ---------- الألغاز ----------
func _after_collect() -> void:
	if lv.has("puzzle"):
		_start_puzzle()
	else:
		_start_quiz()

func _start_puzzle() -> void:
	phase = "puzzle"
	for h in hazards:
		(h["node"] as Node2D).visible = false
	var p: Dictionary = lv["puzzle"]
	match p["type"]:
		"order": _puz_order(p)
		"match": _puz_match(p)
		"sort": _puz_sort(p)
		_: _start_quiz()

func _puzzle_done() -> void:
	score += 150
	GameState.sfx("win")
	var v := _panel("أحسنت، حللت اللغز!", "")
	v.add_child(UI.button("التالي", _start_quiz))

func _wrong() -> void:
	pmiss += 1
	GameState.sfx("hit")

func _puz_order(p: Dictionary) -> void:
	var v := _panel(p["title"], "المس الخطوات بالترتيب الصحيح")
	var steps: Array = p["steps"]
	var idx := [0]
	var shuffled := steps.duplicate()
	shuffled.shuffle()
	for s in shuffled:
		var b := UI.button(s, func(): pass, Color("#6c63ff"))
		b.pressed.connect(func():
			if s == steps[idx[0]]:
				idx[0] += 1
				b.disabled = true
				b.text = "%d) %s" % [idx[0], s]
				GameState.sfx("collect")
				if idx[0] >= steps.size():
					_puzzle_done()
			else:
				_wrong())
		v.add_child(b)

func _puz_match(p: Dictionary) -> void:
	var v := _panel(p["title"], "المس عنصراً ثم ما يناسبه")
	var pairs: Array = p["pairs"]
	var lefts: Array = pairs.map(func(x): return x[0])
	var rights: Array = pairs.map(func(x): return x[1])
	lefts.shuffle()
	rights.shuffle()
	var sel := {"l": ""}
	var left_btns := {}
	var done := [0]
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	var lc := VBoxContainer.new()
	var rc := VBoxContainer.new()
	for c in [lc, rc]:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_theme_constant_override("separation", 12)
		cols.add_child(c)
	v.add_child(cols)
	for l in lefts:
		var lb := UI.button(l, func(): pass, Color("#2a9d8f"))
		lb.add_theme_font_size_override("font_size", 28)
		lb.pressed.connect(func(): sel["l"] = l)
		left_btns[l] = lb
		lc.add_child(lb)
	for r in rights:
		var rb := UI.button(r, func(): pass, Color("#f4a261"))
		rb.add_theme_font_size_override("font_size", 24)
		rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rb.pressed.connect(func():
			if sel["l"] == "":
				return
			var ok := false
			for pr in pairs:
				if pr[0] == sel["l"] and pr[1] == r:
					ok = true
			if ok:
				(left_btns[sel["l"]] as Button).disabled = true
				rb.disabled = true
				sel["l"] = ""
				done[0] += 1
				GameState.sfx("collect")
				if done[0] >= pairs.size():
					_puzzle_done()
			else:
				_wrong())
		rc.add_child(rb)

func _puz_sort(p: Dictionary) -> void:
	var its: Array = p["items"].duplicate()
	its.shuffle()
	_sort_next(p, its, [0])

func _sort_next(p: Dictionary, its: Array, i: Array) -> void:
	if i[0] >= its.size():
		_puzzle_done()
		return
	var it: Array = its[i[0]]
	var v := _panel(p["title"], "(%d/%d)  %s" % [i[0] + 1, its.size(), it[0]])
	for k in p["bins"].size():
		var cb := func():
			if k == int(it[1]):
				i[0] += 1
				GameState.sfx("collect")
				_sort_next(p, its, i)
			else:
				_wrong()
		v.add_child(UI.button(p["bins"][k], cb, Color("#6c63ff")))

func _fallback() -> Dictionary:
	return {"id": GameState.selected_level, "title": "الخلية", "color": "#7fd6c2",
		"background": "res://assets/backgrounds/bg_default.svg",
		"intro": "اجمع العناصر المضيئة، وابتعد عن الجراثيم، ثم أجب عن السؤال.",
		"dialogue": "أهلاً! أنا رائد، مستكشف الجسم.",
		"items": ["النواة", "الميتوكوندريا", "الريبوسوم", "الغشاء"], "hazards": 2, "difficulty": 1,
		"questions": [{"q": "أي جزء هو مركز التحكم في الخلية؟", "answer": "النواة", "wrong": ["الغشاء", "الماء"]}]}

func _set_player_tex(tex: Texture2D) -> void:
	player.texture = tex
	base_k = 200.0 / idle_tex.get_height()
	player.scale = Vector2.ONE * base_k
	player.offset = Vector2(0.0, (idle_tex.get_height() - tex.get_height()) / 2.0)

func _toast_fact(nm: String) -> void:
	var f: Dictionary = lv.get("facts", {})
	if not f.has(nm):
		return
	_toast(str(f[nm]))
	GameState.speak(str(f[nm]))

func _toast(text: String) -> void:
	if toast and is_instance_valid(toast):
		toast.queue_free()
	var pc := PanelContainer.new()
	pc.layout_direction = Control.LAYOUT_DIRECTION_RTL
	pc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pc.offset_top = -240.0
	pc.offset_bottom = -70.0
	pc.offset_left = 30.0
	pc.offset_right = -30.0
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.05, 0.25, 0.88)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(16)
	pc.add_theme_stylebox_override("panel", sb)
	var l := UI.label(text, 28, Color.WHITE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	ui_layer.add_child(pc)
	toast = pc
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(pc.queue_free)

func _on_start() -> void:
	_close_panel()
	phase = "play"
	if GameState.selected_level == 1:
		_say("ما أجمل هذا العالم الصغير! لنستكشف الخلية…", 3.5)

# فقاعة قصيرة لا توقف اللعب
func _say(text: String, secs := 3.0) -> void:
	if toast and is_instance_valid(toast):
		toast.queue_free()
	var pc := PanelContainer.new()
	pc.layout_direction = Control.LAYOUT_DIRECTION_RTL
	pc.anchor_left = 0.0
	pc.anchor_right = 1.0
	pc.anchor_top = 0.0
	pc.anchor_bottom = 0.0
	pc.offset_left = 24.0
	pc.offset_right = -24.0
	pc.offset_top = 112.0
	pc.offset_bottom = 112.0
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI.holo_style()
	sb.set_corner_radius_all(30)
	sb.set_content_margin_all(16)
	sb.bg_color = Color(0.07, 0.09, 0.28, 0.82)
	pc.add_theme_stylebox_override("panel", sb)
	var l := UI.glow_label(text, 28)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	ui_layer.add_child(pc)
	toast = pc
	pc.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.2)
	tw.tween_interval(secs)
	tw.tween_property(pc, "modulate:a", 0.0, 0.3)
	tw.tween_callback(pc.queue_free)

func _say_fact(nm: String) -> void:
	var texts: Dictionary = learn.get(str(GameState.selected_level), {})
	var txt := str(texts.get(nm, ""))
	if txt == "":
		return
	_say("%s: %s" % [nm, txt], 7.0)
	GameState.speak(txt)

func _burst(p: Vector2, r: float) -> void:
	var b := OrganelleFX.new()
	b.kind = "burst"
	b.r = r
	b.position = p
	world.add_child(b)
	b.celebrate()

func _activate_hazards() -> void:
	hazards_on = true
	_say("إنذار! جراثيم تحاول تعطيل عمل الخلية!", 3.5)
	GameState.sfx("hit")
	var vp := get_viewport_rect().size
	var sp := 110.0 + 25.0 * int(lv.get("difficulty", 1))
	for i in hazards.size():
		var h: Dictionary = hazards[i]
		var n: Sprite2D = h["node"]
		n.position = Vector2(vp.x * (0.1 if i % 2 == 0 else 0.9), vp.y * 0.2 + float(i) * 120.0)
		n.visible = true
		n.modulate.a = 0.0
		create_tween().tween_property(n, "modulate:a", 1.0, 0.6)
		h["vel"] = Vector2(1.0 if i % 2 == 0 else -1.0, 0.5).normalized() * sp
