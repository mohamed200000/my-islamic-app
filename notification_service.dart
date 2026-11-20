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
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> schedulePrayers(PrayerTimes pt, List<bool> enabled, bool khatmahFajr) async {
    await init();
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(100 + i);
      final entry = pt.prayers[i];
      if (!enabled[i] || entry.value.isBefore(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        100 + i,
        'حان وقت صلاة ${entry.key}',
        'حيّ على الصلاة — اللهم رب هذه الدعوة التامة',
        tz.TZDateTime.from(entry.value, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'تنبيهات الأذان',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await _plugin.cancel(110);
    if (khatmahFajr && pt.fajr.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        110,
        'ورد الختمة اليومي',
        'تذكير بقراءة وردك اليومي من القرآن الكريم بعد الفجر',
        tz.TZDateTime.from(pt.fajr.add(const Duration(minutes: 20)), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('khatmah_channel', 'ورد القرآن'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// جدولة إشعار الاستغفار وإشعار الصلاة على سيدنا محمد ﷺ في الخلفية
  Future<void> scheduleDhikrReminders({required bool istighfarOn, required bool salawatOn, int minutes = 5}) async {
    await init();
    await _plugin.cancel(201);
    await _plugin.cancel(202);
    if (istighfarOn) {
      await _plugin.periodicallyShow(
        201,
        'الاستغفار',
        'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
        RepeatInterval.everyMinute, // في الإنتاج يمكن جدولته كل 5 دقائق عبر WorkManager/zonedSchedule
        const NotificationDetails(
          android: AndroidNotificationDetails('dhikr_channel', 'أذكار وتنبيهات دورية'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    if (salawatOn) {
      await _plugin.zonedSchedule(
        202,
        'صلِّ على سيدنا محمد ﷺ',
        'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ',
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes)),
        const NotificationDetails(
          android: AndroidNotificationDetails('salawat_channel', 'الصلاة على النبي ﷺ'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
