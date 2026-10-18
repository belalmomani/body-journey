# البناء على Android
المتطلبات: Godot 4.3 + Export Templates، JDK 17، Android SDK (build-tools 34، platform 34)، ومفتاح توقيع (keystore) خاص بك.
1. Editor ▸ Editor Settings ▸ Export ▸ Android: مسار SDK وJDK وKeystore.
2. Project ▸ Install Android Build Template، وPreset أندرويد: Portrait، Min SDK 24.
3. **مهم:** في Resources ▸ Filters to export non-resource files ضع: `data/*,config/*.json` (وإلا لن تُصدَّر ملفات JSON/TXT فيتعطل اللعب).
4. فعّل صلاحية INTERNET. Export Project ▸ APK/AAB.
5. الخط العربي: الخط الافتراضي قد لا يحوي العربية؛ على أندرويد يُستخدم خط النظام احتياطياً. للتحكم الكامل أضف خط Noto Sans Arabic (SIL OFL) إلى `assets/fonts` وعيّنه في Theme.
الاختبارات: `godot --headless -s tests/run_tests.gd`
