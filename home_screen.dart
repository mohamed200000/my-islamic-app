import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../main.dart';
import '../data/governorates.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _govIdx = 0;
  double? _gpsLat;
  double? _gpsLng;
  PrayerTimes? _pt;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  String _nextName = '';
  DateTime? _nextTime;
  bool _locLoading = false;
  bool _showFontBar = false;

  static const _langs = ['العربية', 'English', 'Français', 'Türkçe', 'اردو', 'Indonesia'];
  static const _tTitle = ['مواقيت الصلاة', 'Prayer Times', 'Heures de prière', 'Namaz Vakitleri', 'نماز کے اوقات', 'Waktu Salat'];
  static const _tNext = ['الصلاة القادمة', 'Next prayer', 'Prochaine prière', 'Sıradaki namaz', 'اگلی نماز', 'Salat berikutnya'];
  static const _tLang = ['اللغة', 'Language', 'Langue', 'Dil', 'زبان', 'Bahasa'];
  static const _tGov = ['المحافظة / الموقع', 'Governorate / Location', 'Gouvernorat', 'Vilayet', 'محافظہ', 'Provinsi'];
  static const _tGps = ['تحديث من موقعي (GPS)', 'Use my location (GPS)', 'Utiliser ma position', 'Konumumu kullan', 'میرا مقام استعمال کریں', 'Gunakan lokasi saya'];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await DataService.prefs();
    final govIdx = p.getInt('govIdx') ?? 0;
    final gpsLat = p.getDouble('gpsLat');
    final gpsLng = p.getDouble('gpsLng');

    final lat = (govIdx == 27 && gpsLat != null) ? gpsLat : governorates[govIdx.clamp(0, 26)].lat;
    final lng = (govIdx == 27 && gpsLng != null) ? gpsLng : governorates[govIdx.clamp(0, 26)].lng;
    final method = p.getInt('calcMethod') ?? 5;
    final hanafi = p.getBool('hanafiAsr') ?? false;

    final service = PrayerService(lat: lat, lng: lng, method: method, hanafiAsr: hanafi);

    final localPt = service.local(DateTime.now());
    if (mounted) {
      setState(() {
        _govIdx = govIdx;
        _gpsLat = gpsLat;
        _gpsLng = gpsLng;
        _pt = localPt;
      });
      _updateCountdown();
    }

    PrayerTimes pt = localPt;
    try {
      pt = await service.forDate(DateTime.now());
      if (mounted) {
        setState(() => _pt = pt);
        _updateCountdown();
      }
    } catch (_) {}

    try {
      final enabled = List.generate(5, (i) => p.getBool('an_$i') ?? true);
      final khatmahFajr = p.getBool('khatmahFajr') ?? true;
      await NotificationService.instance.schedulePrayers(pt, enabled, khatmahFajr);
    } catch (_) {}
  }

  void _updateCountdown() {
    if (_pt == null) return;
    final now = DateTime.now();
    MapEntry<String, DateTime>? next;
    for (final e in _pt!.prayers) {
      if (e.value.isAfter(now)) {
        next = e;
        break;
      }
    }
    next ??= MapEntry(_pt!.prayers.first.key, _pt!.prayers.first.value.add(const Duration(days: 1)));
    if (mounted) {
      setState(() {
        _nextName = next!.key;
        _nextTime = next.value;
        _remaining = next.value.difference(now);
      });
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _useGps() async {
    if (_locLoading) return;
    setState(() => _locLoading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _msg('يرجى تشغيل خدمة الموقع (GPS) في الهاتف أولاً');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _msg('يرجى السماح للتطبيق بالوصول إلى الموقع من الإعدادات');
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        _msg('تعذر تحديد الموقع حالياً، تأكد من إشارة GPS');
        return;
      }
      final p = await DataService.prefs();
      await p.setDouble('gpsLat', pos.latitude);
      await p.setDouble('gpsLng', pos.longitude);
      await p.setInt('govIdx', 27);
      await _load();
      _msg('تم تحديث المواقيت من موقعك بنجاح');
    } catch (e) {
      _msg('تعذر تحديد الموقع: حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "ص" : "م"}';
  }

  String _fmtDur(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.now();
    final hijriText = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    final primary = Theme.of(context).colorScheme.primary;
    final lg = IslamicApp.langIndex.value.clamp(0, 5);
    final sc = IslamicApp.fontScale.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_tTitle[lg], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
            OutlinedButton(
              onPressed: () => setState(() => _showFontBar = !_showFontBar),
              child: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        if (_showFontBar)
          Card(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final next = (sc - 0.1).clamp(0.85, 1.5);
                      IslamicApp.fontScale.value = next;
                      (await DataService.prefs()).setDouble('fontScale', next);
                      setState(() {});
                    },
                    child: const Text('أ-'),
                  ),
                  Text('${(sc * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  OutlinedButton(
                    onPressed: () async {
                      final next = (sc + 0.1).clamp(0.85, 1.5);
                      IslamicApp.fontScale.value = next;
                      (await DataService.prefs()).setDouble('fontScale', next);
                      setState(() {});
                    },
                    child: const Text('أ+'),
                  ),
                  TextButton(
                    onPressed: () async {
                      IslamicApp.fontScale.value = 1.0;
                      (await DataService.prefs()).setDouble('fontScale', 1.0);
                      setState(() {});
                    },
                    child: const Text('الافتراضي'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: lg,
          decoration: InputDecoration(labelText: _tLang[lg], border: const OutlineInputBorder()),
          items: List.generate(_langs.length, (i) => DropdownMenuItem(value: i, child: Text(_langs[i]))),
          onChanged: (v) async {
            if (v == null) return;
            IslamicApp.langIndex.value = v;
            (await DataService.prefs()).setInt('langIndex', v);
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _govIdx,
          decoration: InputDecoration(labelText: _tGov[lg], border: const OutlineInputBorder()),
          items: [
            ...List.generate(governorates.length, (i) => DropdownMenuItem(value: i, child: Text(governorates[i].name))),
            if (_gpsLat != null) const DropdownMenuItem(value: 27, child: Text('موقعي الحالي (GPS)')),
          ],
          onChanged: (v) async {
            if (v == null) return;
            final p = await DataService.prefs();
            await p.setInt('govIdx', v);
            await _load();
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF114B3E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFB68D40).withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_govIdx == 27 ? "موقعك الحالي" : governorates[_govIdx.clamp(0, 26)].name} · $hijriText',
                style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(_tNext[lg], style: const TextStyle(color: Colors.white70)),
              Text(
                _nextTime != null ? '$_nextName ${_fmt(_nextTime!)}' : 'جارٍ الحساب...',
                style: const TextStyle(color: Color(0xFFFAF8F3), fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(_fmtDur(_remaining), style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_pt != null)
          Card(
            child: Column(
              children: _pt!.allSix.map((e) {
                final isNext = e.key == _nextName;
                return ListTile(
                  tileColor: isNext ? primary.withOpacity(0.14) : null,
                  title: Text(e.key, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
                  trailing: Text(_fmt(e.value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _locLoading ? null : _useGps,
          icon: _locLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(_locLoading ? 'جارٍ تحديد الموقع...' : _tGps[lg]),
        ),
      ],
    );
  }
}
