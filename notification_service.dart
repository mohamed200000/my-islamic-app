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
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
    _ready = true;
  }

  Future<void> _safeSchedule(int id, String title, String body, DateTime when, String chId, String chName) async {
    if (when.isBefore(DateTime.now())) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        chId,
        chName,
        importance: Importance.max,
        priority: Priority.high,
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
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
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
        'adhan_channel_v2',
        'تنبيهات الأذان',
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
    for (int i = 0; i < 12; i++) {
      await _plugin.cancel(200 + i);
      await _plugin.cancel(300 + i);
    }
    final now = DateTime.now();
    for (int i = 1; i <= 12; i++) {
      if (istighfarOn) {
        await _safeSchedule(
          200 + i,
          'الاستغفار',
          'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
          now.add(Duration(minutes: i * minutes)),
          'dhikr_channel_v2',
          'تنبيه الاستغفار',
        );
      }
      if (salawatOn) {
        await _safeSchedule(
          300 + i,
          'صلِّ على سيدنا محمد ﷺ',
          'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ',
          now.add(Duration(minutes: i * minutes + (istighfarOn ? 2 : 0))),
          'salawat_channel_v2',
          'الصلاة على النبي ﷺ',
        );
      }
    }
  }
}
