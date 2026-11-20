# تطبيق مواقيت الصلاة والأذكار — نسخة Flutter

هيكل مشروع Flutter متكامل يعتمد على `prayer_service.dart` ويحتوي على كافة البيانات والملفات الصوتية للعمل **بدون إنترنت**.

## خطوات التشغيل السريعة
1. افتح الطرفية داخل مجلد `islamic_app_flutter` وأنشئ ملفات المنصات (`android/` و `ios/`):
   ```bash
   flutter create . --org com.islamicapp
   ```
2. حمّل الحزم:
   ```bash
   flutter pub get
   ```
3. أضف الأذونات التالية داخل `android/app/src/main/AndroidManifest.xml` قبل وسم `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   ```
4. شغّل التطبيق على هاتفك أو المحاكي:
   ```bash
   flutter run
   ```
5. لبناء ملف التثبيت `APK`:
   ```bash
   flutter build apk --release
   ```
