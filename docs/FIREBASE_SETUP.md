# إعداد Firebase
1. أنشئ مشروعاً في https://console.firebase.google.com ثم فعّل **Authentication**: Email/Password و **Anonymous**.
2. فعّل **Cloud Firestore** (وضع الإنتاج).
3. انشر القواعد: `cd firebase && firebase deploy --only firestore` (أو الصق `firestore.rules` في الكونسول).
4. من إعدادات المشروع انسخ **Web API Key** و**Project ID**، وأنشئ `config/firebase_config.json` (مُتجاهَل في git) بنفس شكل `config/firebase_config.example.json`.
5. اللعبة تستخدم REST الرسمي (Identity Toolkit + Firestore) لأن Godot لا يملك SDK رسمياً لـ Firebase. لا تضع أي مفاتيح Admin.
6. لا يوجد فهرس مركّب مطلوب حالياً (`firestore.indexes.json` فارغ).
حدود معروفة: القواعد تتحقق من الشكل والحدود (نجوم ≤ 78) لكن لا تمنع لاعباً من التلاعب بنقاطه ضمن الحدود؛ هذا مقبول للعبة تعليمية. حقل `lastLoginAt` نص ISO وليس Timestamp.
قبل الإنتاج: فعّل App Check، وراجع حماية مفتاح الـ API بقيود، واختبر السيناريوهات في Firebase Emulator.

## مشروع مشترك (مهم)
مشروع Firebase المرتبط (dreams-3e774) تستخدمه تطبيقات أخرى أيضاً. لذلك:
- بيانات هذه اللعبة تُحفظ في مجموعتين خاصتين: `bj_users` و`bj_progress` (لا تتعارض مع مجموعات التطبيقات الأخرى).
- **لا تنشر `firestore.rules` فوق قواعدك الحالية**؛ أضف كتلتي `bj_users` و`bj_progress` فقط داخل قواعدك الحالية.
- الأفضل لبيانات أطفال: مشروع Firebase مستقل لهذه اللعبة.
- مفتاح الـAPI: لا تقيّده بتطبيق Android (طلبات REST لا تحمل بصمة التطبيق)؛ قيّده بالواجهات (Identity Toolkit وFirestore) فقط.
- أسرار GitHub المطلوبة للبناء: `FIREBASE_API_KEY` و`FIREBASE_PROJECT_ID`.
