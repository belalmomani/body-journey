class_name StartIoProvider
extends AdProvider
# هيكل مزود Start.io. غير مفعّل وغير مُختبَر.
# Godot لا يملك إضافة رسمية لـ Start.io؛ يلزم إضافة Android (Kotlin) مخصصة تُسجَّل كـ Engine singleton.
# أسماء الدوال أدناه افتراضية ويجب مطابقتها مع الإضافة التي تكتبها بعد مراجعة https://docs.start.io/
# معرّف التطبيق في Start.io (غير سري). غير مستخدم الآن: Start.io لا يُسمح به في تطبيقات موجّهة للأطفال فقط.
const APP_ID := "209771676"
const SINGLETON := "StartIoBridge"
var test_mode := true
func _plugin():
	return Engine.get_singleton(SINGLETON) if Engine.has_singleton(SINGLETON) else null
func load_interstitial() -> void:
	var p = _plugin()
	if p: p.loadInterstitial(test_mode)
func is_ready() -> bool:
	var p = _plugin()
	return p != null and p.isInterstitialReady()
func show_interstitial(on_closed: Callable) -> void:
	var p = _plugin()
	if p == null or not p.isInterstitialReady():
		on_closed.call(); return
	p.showInterstitial()
	# يُفترض أن الإضافة ترسل إشارة إغلاق؛ هذا مؤقّت أمان كي لا يتجمد اللعب.
	var t: SceneTreeTimer = (Engine.get_main_loop() as SceneTree).create_timer(1.0)
	t.timeout.connect(on_closed)
