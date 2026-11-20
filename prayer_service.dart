import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimes {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;
  final bool fromApi;
  PrayerTimes(this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib,
      this.isha, this.fromApi);

  List<MapEntry<String, DateTime>> get allSix => [
        MapEntry('الفجر', fajr),
        MapEntry('الشروق', sunrise),
        MapEntry('الظهر', dhuhr),
        MapEntry('العصر', asr),
        MapEntry('المغرب', maghrib),
        MapEntry('العشاء', isha),
      ];

  List<MapEntry<String, DateTime>> get prayers => [
        MapEntry('الفجر', fajr),
        MapEntry('الظهر', dhuhr),
        MapEntry('العصر', asr),
        MapEntry('المغرب', maghrib),
        MapEntry('العشاء', isha),
      ];
}

class PrayerService {
  PrayerService({
    this.lat = 30.0444,
    this.lng = 31.2357,
    this.adjust = const [0, 0, 0, 0, 0, 0],
    this.hanafiAsr = false,
    this.method = 5, // 5 = الهيئة المصرية، 3 = رابطة العالم، 4 = أم القرى
  });

  final double lat, lng;
  final List<int> adjust;
  final bool hanafiAsr;
  final int method;

  String _key(DateTime d) =>
      'pt_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_${method}_${hanafiAsr ? 1 : 0}_${d.year}_${d.month}';

  Future<PrayerTimes> forDate(DateTime d) async {
    final prefs = await SharedPreferences.getInstance();
    List? days;
    int ageMs = 1 << 50;
    final raw = prefs.getString(_key(d));
    if (raw != null) {
      final m = jsonDecode(raw);
      days = m['days'] as List;
      ageMs = DateTime.now().millisecondsSinceEpoch - (m['at'] as int);
    }
    if (days == null || ageMs > 24 * 3600 * 1000) {
      days = await _fetchMonth(d, prefs) ?? days;
    }
    if (days != null && d.day <= days.length) return _parse(days, d);
    return local(d);
  }

  Future<List?> _fetchMonth(DateTime d, SharedPreferences prefs) async {
    try {
      final u = Uri.https('api.aladhan.com', '/v1/calendar/${d.year}/${d.month}', {
        'latitude': '$lat',
        'longitude': '$lng',
        'method': '$method',
        'school': hanafiAsr ? '1' : '0',
      });
      final r = await http.get(u).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return null;
      final days = jsonDecode(r.body)['data'] as List;
      await prefs.setString(_key(d),
          jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'days': days}));
      return days;
    } catch (_) {
      return null;
    }
  }

  PrayerTimes _parse(List days, DateTime d) {
    final e = days[d.day - 1]['timings'] as Map;
    DateTime t(String k, int i) {
      final p = (e[k] as String).substring(0, 5).split(':');
      return DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]))
          .add(Duration(minutes: adjust[i]));
    }

    return PrayerTimes(t('Fajr', 0), t('Sunrise', 1), t('Dhuhr', 2), t('Asr', 3),
        t('Maghrib', 4), t('Isha', 5), true);
  }

  PrayerTimes local(DateTime d) {
    const rd = math.pi / 180;
    double sn(double a) => math.sin(a * rd);
    double cs(double a) => math.cos(a * rd);
    double tn(double a) => math.tan(a * rd);
    double fa(double a) => ((a % 360) + 360) % 360;
    double fh(double h) => ((h % 24) + 24) % 24;

    var y = d.year, m = d.month;
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a0 = (y / 100).floor(), b = 2 - a0 + (a0 / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d.day +
        b -
        1524.5 -
        lng / 360;

    List<double> sp(double t) {
      final dd = jd + t - 2451545;
      final g = fa(357.529 + .98560028 * dd);
      final q = fa(280.459 + .98564736 * dd);
      final l = fa(q + 1.915 * sn(g) + .02 * sn(2 * g));
      final e = 23.439 - 3.6e-7 * dd;
      final ra = fh(math.atan2(cs(e) * sn(l), cs(l)) / rd / 15);
      return [math.asin(sn(e) * sn(l)) / rd, q / 15 - ra];
    }

    double md(double t) => fh(12 - sp(t)[1]);
    double sa(double a, double t, bool cw) {
      final dec = sp(t)[0];
      final raw = ((-sn(a) - sn(dec) * sn(lat)) / (cs(dec) * cs(lat))).clamp(-1.0, 1.0);
      final x = 1 / 15 * math.acos(raw) / rd;
      return md(t) + (cw ? x : -x);
    }

    final fajrAngle = method == 3 ? 18.0 : (method == 4 ? 18.5 : 19.5);
    final ishaAngle = method == 3 ? 17.0 : 17.5;

    final f = sa(fajrAngle, 5 / 24, false);
    final sr = sa(.833, 6 / 24, false);
    final dh = md(12 / 24);
    final factor = hanafiAsr ? 2.0 : 1.0;
    final asr = sa(-math.atan(1 / (factor + tn((lat - sp(13 / 24)[0]).abs()))) / rd, 13 / 24, true);
    final mg = sa(.833, 18 / 24, true);
    final ish = method == 4 ? mg + 1.5 : sa(ishaAngle, 18 / 24, true);

    DateTime at(double h, int i) => DateTime.utc(d.year, d.month, d.day)
        .add(Duration(minutes: ((h - lng / 15) * 60).round() + adjust[i]))
        .toLocal();

    return PrayerTimes(at(f, 0), at(sr, 1), at(dh, 2), at(asr, 3), at(mg, 4), at(ish, 5), false);
  }
}
