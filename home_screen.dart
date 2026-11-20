import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
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
    _govIdx = p.getInt('govIdx') ?? 0;
    _gpsLat = p.getDouble('gpsLat');
    _gpsLng = p.getDouble('gpsLng');

    final lat = (_govIdx == 27 && _gpsLat != null) ? _gpsLat! : governorates[_govIdx.clamp(0, 26)].lat;
    final lng = (_govIdx == 27 && _gpsLng != null) ? _gpsLng! : governorates[_govIdx.clamp(0, 26)].lng;
    final method = p.getInt('calcMethod') ?? 5;
    final hanafi = p.getBool('hanafiAsr') ?? false;

    final service = PrayerService(lat: lat, lng: lng, method: method, hanafiAsr: hanafi);
    final pt = await service.forDate(DateTime.now());
    final enabled = List.generate(5, (i) => p.getBool('an_$i') ?? true);
    final khatmahFajr = p.getBool('khatmahFajr') ?? true;
    await NotificationService.instance.schedulePrayers(pt, enabled, khatmahFajr);

    if (mounted) {
      setState(() => _pt = pt);
      _updateCountdown();
    }
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

  Future<void> _useGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      final p = await DataService.prefs();
      await p.setDouble('gpsLat', pos.latitude);
      await p.setDouble('gpsLng', pos.longitude);
      await p.setInt('govIdx', 27);
      await _load();
    } catch (_) {}
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('مواقيت الصلاة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F3D33))),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _govIdx,
          decoration: const InputDecoration(labelText: 'المحافظة / الموقع', border: OutlineInputBorder()),
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
          decoration: BoxDecoration(color: const Color(0xFF0F3D33), borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_govIdx == 27 ? "موقعك الحالي" : governorates[_govIdx.clamp(0, 26)].name} · $hijriText',
                style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 13),
              ),
              const SizedBox(height: 10),
              const Text('الصلاة القادمة', style: TextStyle(color: Colors.white70)),
              Text(
                _nextTime != null ? '$_nextName ${_fmt(_nextTime!)}' : 'جارٍ الحساب...',
                style: const TextStyle(color: Color(0xFFF6F1E6), fontSize: 32, fontWeight: FontWeight.bold),
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
                  tileColor: isNext ? const Color(0xFFEADFC2) : null,
                  title: Text(e.key, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
                  trailing: Text(_fmt(e.value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _useGps,
          icon: const Icon(Icons.my_location),
          label: const Text('تحديث من موقعي (GPS)'),
        ),
      ],
    );
  }
}
