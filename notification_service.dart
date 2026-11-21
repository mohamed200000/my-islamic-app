import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await requestPermissions();
    _ready = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future checkPermissions() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    bool notif = true;
    bool exact = true;
    try {
      notif = await androidImpl?.areNotificationsEnabled() ?? true;
    } catch (_) {}
    try {
      exact = await androidImpl?.canScheduleExactNotifications() ?? true;
    } catch (_) {}
    return {'notif': notif, 'exact': exact};
  }

  Future<String?> showDhikrNow() async {
    await init();
    try {
      await _plugin.show(
        999,
        'الاستغفار والصلاة على النبي ﷺ',
        'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ ✦ اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dhikr_channel_v5',
            'تنبيه الاستغفار والصلاة على النبي ﷺ',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('istighfar'),
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      return null;
    } catch (_) {
      try {
        await _plugin.show(
          999,
          'الاستغفار والصلاة على النبي ﷺ',
          'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ ✦ اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'dhikr_channel_fallback',
              'تنبيه الاستغفار العام',
              importance: Importance.max,
              priority: Priority.high,
              visibility: NotificationVisibility.public,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
        return null;
      } catch (e2) {
        return e2.toString();
      }
    }
  }

  Future<void> _safeSchedule(
    int id,
    String title,
    String body,
    DateTime when,
    String chId,
    String chName, {
    String? rawSound,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        chId,
        chName,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: rawSound != null ? RawResourceAndroidNotificationSound(rawSound) : null,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final tzTime = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  Future<void> schedulePrayers(PrayerTimes pt, List<bool> enabled, bool khatmahFajr) async {
    await init();
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(100 + i);
      final entry = pt.prayers[i];
      if (!enabled[i]) continue;
      await _safeSchedule(
        100 + i,
        'حان وقت صلاة ${entry.key}',
        'حيّ على الصلاة — اللهم رب هذه الدعوة التامة',
        entry.value,
        'adhan_channel_v5',
        'صوت الأذان',
        rawSound: 'adhan',
      );
    }

    await _plugin.cancel(110);
    if (khatmahFajr) {
      await _safeSchedule(
        110,
        'ورد الختمة اليومي',
        'تذكير بقراءة وردك اليومي من القرآن الكريم بعد الفجر',
        pt.fajr.add(const Duration(minutes: 20)),
        'khatmah_channel_v2',
        'ورد القرآن',
      );
    }
  }

  Future<void> scheduleDhikrReminders({required bool istighfarOn, required bool salawatOn, int minutes = 5}) async {
    await init();
    for (int i = 0; i < 24; i++) {
      await _plugin.cancel(200 + i);
    }
    if (!istighfarOn && !salawatOn) return;
    final parts = <String>[];
    if (istighfarOn) parts.add('أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ');
    if (salawatOn) parts.add('اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ');
    final msg = parts.join(' ✦ ');
    final now = DateTime.now();
    for (int i = 1; i <= 24; i++) {
      await _safeSchedule(
        200 + i,
        'الاستغفار والصلاة على النبي ﷺ',
        msg,
        now.add(Duration(minutes: i * minutes)),
        'dhikr_channel_v5',
        'تنبيه الاستغفار والصلاة على النبي ﷺ',
        rawSound: 'istighfar',
      );
    }
  }
}
