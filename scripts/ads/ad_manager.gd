extends Node
# إدارة الإعلانات: مفصولة تماماً عن منطق المراحل.
# enabled=false افتراضياً: لعبة أطفال؛ لا تُفعَّل قبل التحقق من أهلية الشبكة وسياسات Families والموافقة.
var enabled := false
var test_mode := true
var interval_sec := 1800.0       # 30 دقيقة من وقت اللعب الفعلي
var debounce_sec := 20.0
var provider: AdProvider = NullAdProvider.new()
var _showing := false
var _last_attempt := -9999.0

func set_provider(p: AdProvider) -> void:
	provider = p
	provider.load_interstitial()

# يُستدعى فقط أثناء اللعب الفعلي (ليس في القوائم ولا في الخلفية).
func add_play_time(delta: float) -> void:
	GameState.data["played_sec"] = float(GameState.data["played_sec"]) + delta

func _due() -> bool:
	var played: float = GameState.data["played_sec"]
	return played - float(GameState.data["last_ad_at"]) >= interval_sec

# نقطة الانتقال الطبيعية بين المراحل. next يُستدعى دائماً.
func maybe_show(next: Callable) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not enabled or _showing or not _due() or now - _last_attempt < debounce_sec or not provider.is_ready():
		next.call()
		return
	_last_attempt = now
	_showing = true
	provider.show_interstitial(func():
		_showing = false
		GameState.data["last_ad_at"] = GameState.data["played_sec"]
		GameState.save_local()
		provider.load_interstitial()
		next.call())
