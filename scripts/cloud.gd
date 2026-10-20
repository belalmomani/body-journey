extends Node
# Firebase عبر REST الرسمي (Identity Toolkit + Firestore). لا مفاتيح خادم، ولا تخزين لكلمات المرور.
signal auth_changed
const SESSION := "user://session.dat"
const COL_USERS := "bj_users"        # مجلدات خاصة بهذه اللعبة داخل مشروع Firebase المشترك
const COL_PROGRESS := "bj_progress"
var cfg := {}
var configured := false
var uid := ""
var id_token := ""
var refresh_token := ""
var email := ""
var is_guest := false
var dirty := false
var _busy := false

func _ready() -> void:
	var f := FileAccess.open("res://config/firebase_config.json", FileAccess.READ)
	if f:
		var j = JSON.parse_string(f.get_as_text())
		if j is Dictionary and str(j.get("apiKey", "")) != "" and not str(j["apiKey"]).begins_with("YOUR_"):
			cfg = j
			configured = true
	var t := Timer.new()
	t.wait_time = 30.0
	t.timeout.connect(func(): if dirty: push_async())
	add_child(t)
	t.start()
	_load_session()

func signed_in() -> bool:
	return uid != "" and configured

# ---------- طلبات HTTP ----------
func _req(method: int, url: String, body = null, auth := false) -> Dictionary:
	var h := PackedStringArray(["Content-Type: application/json"])
	if auth:
		h.append("Authorization: Bearer " + id_token)
	var r := HTTPRequest.new()
	r.timeout = 15.0
	add_child(r)
	var err := r.request(url, h, method, "" if body == null else JSON.stringify(body))
	if err != OK:
		r.queue_free()
		return {"code": 0, "json": {}}
	var res = await r.request_completed
	r.queue_free()
	var code: int = res[1] if res[0] == HTTPRequest.RESULT_SUCCESS else 0
	var j = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return {"code": code, "json": j if j is Dictionary else {}}

func _auth_call(endpoint: String, body: Dictionary) -> Dictionary:
	if not configured:
		return {"ok": false, "error": "FIREBASE_NOT_CONFIGURED"}
	var r = await _req(HTTPClient.METHOD_POST, "https://identitytoolkit.googleapis.com/v1/%s?key=%s" % [endpoint, cfg["apiKey"]], body)
	if r["code"] == 200:
		return {"ok": true, "json": r["json"]}
	var msg := "NETWORK" if r["code"] == 0 else str(r["json"].get("error", {}).get("message", "UNKNOWN"))
	return {"ok": false, "error": msg}

func error_text(code: String) -> String:
	if code.begins_with("WEAK_PASSWORD"): return "كلمة المرور ضعيفة (6 أحرف على الأقل)."
	match code:
		"NETWORK": return "لا يوجد اتصال بالإنترنت. حاول لاحقاً."
		"FIREBASE_NOT_CONFIGURED": return "الخدمة السحابية غير مُعدّة في هذه النسخة."
		"EMAIL_EXISTS": return "هذا البريد مسجّل مسبقاً."
		"INVALID_EMAIL": return "البريد الإلكتروني غير صالح."
		"EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS": return "البريد أو كلمة المرور غير صحيحة."
		"TOO_MANY_ATTEMPTS_TRY_LATER": return "محاولات كثيرة. انتظر قليلاً."
	return "حدث خطأ (%s)." % code

# ---------- المصادقة ----------
func _apply(j: Dictionary, guest: bool) -> void:
	uid = j["localId"]
	id_token = j["idToken"]
	refresh_token = j["refreshToken"]
	email = str(j.get("email", ""))
	is_guest = guest
	_save_session()
	auth_changed.emit()

func sign_in(mail: String, pw: String) -> Dictionary:
	var r = await _auth_call("accounts:signInWithPassword", {"email": mail, "password": pw, "returnSecureToken": true})
	if r["ok"]:
		_apply(r["json"], false)
		await pull()
	return r

func register(mail: String, pw: String, display: String) -> Dictionary:
	var r = await _auth_call("accounts:signUp", {"email": mail, "password": pw, "returnSecureToken": true})
	if r["ok"]:
		_apply(r["json"], false)
		GameState.data["name"] = display
		if GameState.data["created_at"] == "":
			GameState.data["created_at"] = Time.get_datetime_string_from_system(true) + "Z"
		GameState.save_local()
		await push()
	return r

func guest() -> Dictionary:
	var r = await _auth_call("accounts:signUp", {"returnSecureToken": true})
	if r["ok"]:
		_apply(r["json"], true)
	return r

func link_guest(mail: String, pw: String) -> Dictionary:
	# نفس الـ uid يبقى، فيبقى التقدم كما هو.
	var r = await _auth_call("accounts:update", {"idToken": id_token, "email": mail, "password": pw, "returnSecureToken": true})
	if r["ok"]:
		var j: Dictionary = r["json"]
		id_token = j.get("idToken", id_token)
		refresh_token = j.get("refreshToken", refresh_token)
		email = mail
		is_guest = false
		_save_session()
		auth_changed.emit()
		await push()
	return r

func reset_password(mail: String) -> Dictionary:
	return await _auth_call("accounts:sendOobCode", {"requestType": "PASSWORD_RESET", "email": mail})

func sign_out() -> void:
	uid = ""; id_token = ""; refresh_token = ""; email = ""; is_guest = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION))
	auth_changed.emit()

func delete_account() -> Dictionary:
	if not signed_in():
		return {"ok": false, "error": "NOT_SIGNED_IN"}
	await _fs(HTTPClient.METHOD_DELETE, COL_USERS + "/" + uid)
	await _fs(HTTPClient.METHOD_DELETE, COL_PROGRESS + "/" + uid)
	var r = await _auth_call("accounts:delete", {"idToken": id_token})
	if r["ok"]:
		sign_out()
	return r

func _refresh() -> bool:
	if refresh_token == "" or not configured:
		return false
	var r = await _req(HTTPClient.METHOD_POST, "https://securetoken.googleapis.com/v1/token?key=%s" % cfg["apiKey"],
		{"grant_type": "refresh_token", "refresh_token": refresh_token})
	if r["code"] == 200:
		id_token = r["json"].get("id_token", "")
		refresh_token = r["json"].get("refresh_token", refresh_token)
		_save_session()
		return true
	return false

func _key() -> String:
	return OS.get_unique_id() + "body-journey"

func _save_session() -> void:
	var f := FileAccess.open_encrypted_with_pass(SESSION, FileAccess.WRITE, _key())
	if f:
		f.store_string(JSON.stringify({"uid": uid, "refresh": refresh_token, "email": email, "guest": is_guest}))

func _load_session() -> void:
	if not configured or not FileAccess.file_exists(SESSION):
		return
	var f := FileAccess.open_encrypted_with_pass(SESSION, FileAccess.READ, _key())
	if not f:
		return
	var j = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		uid = j.get("uid", ""); refresh_token = j.get("refresh", ""); email = j.get("email", ""); is_guest = j.get("guest", false)
		if not await _refresh():
			id_token = ""  # بلا اتصال: نُبقي الجلسة ونعيد المحاولة لاحقاً
		auth_changed.emit()

# ---------- Firestore ----------
func _enc(v) -> Dictionary:
	match typeof(v):
		TYPE_BOOL: return {"booleanValue": v}
		TYPE_INT: return {"integerValue": str(v)}
		TYPE_FLOAT: return {"doubleValue": v}
		TYPE_STRING: return {"stringValue": v}
		TYPE_ARRAY:
			var vals := []
			for x in v: vals.append(_enc(x))
			return {"arrayValue": {"values": vals}}
		TYPE_DICTIONARY:
			var f := {}
			for k in v: f[str(k)] = _enc(v[k])
			return {"mapValue": {"fields": f}}
	return {"nullValue": null}

func _dec(v: Dictionary):
	if v.has("integerValue"): return int(v["integerValue"])
	if v.has("doubleValue"): return float(v["doubleValue"])
	if v.has("stringValue"): return v["stringValue"]
	if v.has("booleanValue"): return v["booleanValue"]
	if v.has("arrayValue"):
		var a := []
		for x in v["arrayValue"].get("values", []): a.append(_dec(x))
		return a
	if v.has("mapValue"):
		var m := {}
		var f: Dictionary = v["mapValue"].get("fields", {})
		for k in f: m[k] = _dec(f[k])
		return m
	return null

func _fs(method: int, path: String, body = null) -> Dictionary:
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s" % [cfg.get("projectId", ""), path]
	var r = await _req(method, url, body, true)
	if r["code"] == 401 and await _refresh():
		r = await _req(method, url, body, true)
	return r

func push_async() -> void:
	dirty = true
	if signed_in() and not _busy:
		push()

func push() -> bool:
	if not signed_in() or id_token == "":
		dirty = true
		return false
	_busy = true
	var d: Dictionary = GameState.data
	var done := []
	var lv := {}
	for k in d["completed"]:
		done.append(int(k))
		var c: Dictionary = d["completed"][k]
		lv[k] = {"stars": int(c.get("stars", 0)), "best": int(c.get("best", 0)),
			"attempts": int(c.get("attempts", 0)), "updated": str(c.get("updated", ""))}
	var unlocked := []
	for x in d["unlocked"]: unlocked.append(int(x))
	var now := Time.get_datetime_string_from_system(true) + "Z"
	var user_doc := {"displayName": str(d["name"]), "createdAt": str(d["created_at"]), "lastLoginAt": now,
		"currentLevel": int(d["current_level"]), "totalStars": int(d["total_stars"]), "totalScore": int(d["total_score"]),
		"unlockedLevels": unlocked, "completedLevels": done,
		"settings": {"music": float(d["settings"]["music"]), "sfx": float(d["settings"]["sfx"])}}
	var a = await _fs(HTTPClient.METHOD_PATCH, COL_USERS + "/" + uid, _enc(user_doc)["mapValue"])
	var b = await _fs(HTTPClient.METHOD_PATCH, COL_PROGRESS + "/" + uid, _enc({"levels": lv, "updatedAt": now})["mapValue"])
	_busy = false
	var ok: bool = a["code"] == 200 and b["code"] == 200
	dirty = not ok  # عند الفشل/انقطاع الإنترنت يُعاد تلقائياً كل 30 ثانية
	return ok

func pull() -> bool:
	if not signed_in():
		return false
	var a = await _fs(HTTPClient.METHOD_GET, COL_USERS + "/" + uid)
	var b = await _fs(HTTPClient.METHOD_GET, COL_PROGRESS + "/" + uid)
	var u := {}
	var p := {}
	if a["code"] == 200: u = _dec({"mapValue": {"fields": a["json"].get("fields", {})}})
	if b["code"] == 200: p = _dec({"mapValue": {"fields": b["json"].get("fields", {})}})
	if a["code"] == 0 and b["code"] == 0:
		return false
	GameState.merge_remote(u, p)
	await push()
	return true
