extends Node
# حالة اللعبة، الحفظ المحلي، الصوت، تحميل المراحل.
signal changed
const SAVE_PATH := "user://save.json"
const LEVEL_COUNT := 26
var data := {}
var levels := {}
var selected_level := 1
var local_mode := false
var _sfx := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer

func _default() -> Dictionary:
	return {"name": "", "created_at": "", "current_level": 1, "total_stars": 0, "total_score": 0,
		"unlocked": [1], "completed": {}, "played_sec": 0.0, "last_ad_at": 0.0,
		"settings": {"music": 0.7, "sfx": 1.0}}

func _ready() -> void:
	data = _default()
	for i in range(1, LEVEL_COUNT + 1):
		var f := FileAccess.open("res://data/levels/level_%02d.json" % i, FileAccess.READ)
		if f:
			var j = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				levels[i] = j
	for n in ["collect", "hit", "tap", "win", "fail"]:
		_sfx[n] = load("res://assets/audio/%s.wav" % n)
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var ms = load("res://assets/audio/music.wav")
	if ms is AudioStreamWAV:
		ms.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ms.loop_end = ms.data.size() / 2
	_music.stream = ms
	load_local()
	apply_audio()

func go(path: String) -> void:
	get_tree().change_scene_to_file(path)

# ---------- الحفظ المحلي ----------
func load_local() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var j = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		var d := _default()
		d.merge(j, true)
		d["unlocked"] = (d["unlocked"] as Array).map(func(x): return int(x))
		data = d
		if not data["unlocked"].has(1):
			data["unlocked"].append(1)

func save_local() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
	changed.emit()

# ---------- التقدم ----------
func is_unlocked(id: int) -> bool:
	return data["unlocked"].has(id)

func stars_of(id: int) -> int:
	return int(data["completed"].get(str(id), {}).get("stars", 0))

func record_attempt(id: int) -> void:
	var c: Dictionary = data["completed"].get(str(id), {"stars": 0, "best": 0, "attempts": 0})
	c["attempts"] = int(c.get("attempts", 0)) + 1
	c["updated"] = Time.get_datetime_string_from_system(true)
	data["completed"][str(id)] = c
	save_local()

func complete_level(id: int, stars: int, score: int) -> void:
	var c: Dictionary = data["completed"].get(str(id), {"stars": 0, "best": 0, "attempts": 0})
	c["stars"] = maxi(int(c.get("stars", 0)), stars)
	c["best"] = maxi(int(c.get("best", 0)), score)
	c["attempts"] = int(c.get("attempts", 0)) + 1
	c["updated"] = Time.get_datetime_string_from_system(true)
	data["completed"][str(id)] = c
	if id < LEVEL_COUNT and not data["unlocked"].has(id + 1):
		data["unlocked"].append(id + 1)
	data["current_level"] = mini(id + 1, LEVEL_COUNT)
	_recalc()
	save_local()
	Cloud.push_async()

func _recalc() -> void:
	var s := 0
	var sc := 0
	for k in data["completed"]:
		s += int(data["completed"][k].get("stars", 0))
		sc += int(data["completed"][k].get("best", 0))
	data["total_stars"] = s
	data["total_score"] = sc

func merge_remote(users: Dictionary, progress: Dictionary) -> void:
	# دمج آمن: أعلى نجوم/نقاط لكل مرحلة + اتحاد المراحل المفتوحة
	var rc: Dictionary = progress.get("levels", {})
	for k in rc:
		var r: Dictionary = rc[k]
		var l: Dictionary = data["completed"].get(k, {"stars": 0, "best": 0, "attempts": 0})
		l["stars"] = maxi(int(l.get("stars", 0)), int(r.get("stars", 0)))
		l["best"] = maxi(int(l.get("best", 0)), int(r.get("best", 0)))
		l["attempts"] = maxi(int(l.get("attempts", 0)), int(r.get("attempts", 0)))
		l["updated"] = str(r.get("updated", l.get("updated", "")))
		data["completed"][k] = l
	for x in users.get("unlockedLevels", []):
		if not data["unlocked"].has(int(x)):
			data["unlocked"].append(int(x))
	data["current_level"] = maxi(int(data["current_level"]), int(users.get("currentLevel", 1)))
	if data["name"] == "" and users.has("displayName"):
		data["name"] = users["displayName"]
	_recalc()
	save_local()

func achievements() -> Array:
	var done := data["completed"].size()
	var three := 0
	for k in data["completed"]:
		if int(data["completed"][k].get("stars", 0)) >= 3:
			three += 1
	return [
		{"title": "أول خطوة", "desc": "أنهِ مرحلة واحدة", "done": done >= 1},
		{"title": "نجم لامع", "desc": "احصل على 3 نجوم في مرحلة", "done": three >= 1},
		{"title": "مستكشف", "desc": "أنهِ 5 مراحل", "done": done >= 5},
		{"title": "عالِم صغير", "desc": "اجمع 30 نجمة", "done": int(data["total_stars"]) >= 30},
		{"title": "بطل الجسم", "desc": "أنهِ المراحل الـ26", "done": done >= LEVEL_COUNT},
	]

# ---------- الصوت ----------
func sfx(n: String) -> void:
	var v: float = data["settings"].get("sfx", 1.0)
	if v <= 0.0 or not _sfx.has(n):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[n]
			p.volume_db = linear_to_db(v)
			p.play()
			return

func apply_audio() -> void:
	var v: float = data["settings"].get("music", 0.7)
	if v <= 0.0:
		_music.stop()
	else:
		_music.volume_db = linear_to_db(v * 0.6)
		if not _music.playing and _music.stream:
			_music.play()

func speak(text: String) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices := DisplayServer.tts_get_voices_for_language("ar")
	if voices.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voices[0], int(50 * data["settings"].get("sfx", 1.0)))
