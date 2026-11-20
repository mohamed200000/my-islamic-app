import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/governorates.dart';
import '../services/data_service.dart';
import '../services/prayer_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _monthOffset = 0;
  double _lat = 30.0444;
  double _lng = 31.2357;
  String _locName = 'القاهرة';

  @override
  void initState() {
    super.initState();
    DataService.prefs().then((p) {
      final idx = p.getInt('govIdx') ?? 0;
      if (mounted) {
        setState(() {
          if (idx == 27 && p.getDouble('gpsLat') != null) {
            _lat = p.getDouble('gpsLat')!;
            _lng = p.getDouble('gpsLng')!;
            _locName = 'موقعي الحالي';
          } else {
            final g = governorates[idx.clamp(0, 26)];
            _lat = g.lat;
            _lng = g.lng;
            _locName = g.name;
          }
        });
      }
    });
  }

  String _fmt(DateTime dt) =>
      '${(dt.hour % 12 == 0 ? 12 : dt.hour % 12)}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + _monthOffset, 1);
    final daysInMonth = DateTime(target.year, target.month + 1, 0).day;
    final ps = PrayerService(lat: _lat, lng: _lng);

    return Scaffold(
      appBar: AppBar(title: Text('جدول المواقيت الشهري ($_locName)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => setState(() => _monthOffset--), child: const Text('السابق')),
                Text('${target.month} / ${target.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                OutlinedButton(onPressed: () => setState(() => _monthOffset++), child: const Text('التالي')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 14,
                  columns: const [
                    DataColumn(label: Text('اليوم')),
                    DataColumn(label: Text('الفجر')),
                    DataColumn(label: Text('الشروق')),
                    DataColumn(label: Text('الظهر')),
                    DataColumn(label: Text('العصر')),
                    DataColumn(label: Text('المغرب')),
                    DataColumn(label: Text('العشاء')),
                  ],
                  rows: List.generate(daysInMonth, (i) {
                    final d = DateTime(target.year, target.month, i + 1);
                    final pt = ps.local(d);
                    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                    return DataRow(
                      color: isToday ? WidgetStatePropertyAll(Theme.of(context).colorScheme.primary.withOpacity(0.15)) : null,
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(_fmt(pt.fajr))),
                        DataCell(Text(_fmt(pt.sunrise))),
                        DataCell(Text(_fmt(pt.dhuhr))),
                        DataCell(Text(_fmt(pt.asr))),
                        DataCell(Text(_fmt(pt.maghrib))),
                        DataCell(Text(_fmt(pt.isha))),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SunnahSurahsScreen extends StatelessWidget {
  const SunnahSurahsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = DataService.instance.content['SU'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('سور من السنة')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final x = list[i] as List;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(x[0].toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text('${x[1]} · ${x[2]}', style: Theme.of(context).textTheme.bodySmall),
                  if (x.length > 3 && x[3].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(x[3].toString(), style: const TextStyle(fontSize: 16, height: 1.7)),
                  ],
                  if (x.length > 4 && x[4].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(x[4].toString(), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HijriCalScreen extends StatefulWidget {
  const HijriCalScreen({super.key});
  @override
  State<HijriCalScreen> createState() => _HijriCalScreenState();
}

class _HijriCalScreenState extends State<HijriCalScreen> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    final now = DateTime.now();
    final first = DateTime(now.year, now.month + _offset, 1);
    final days = DateTime(first.year, first.month + 1, 0).day;
    final satPad = (first.weekday == DateTime.saturday) ? 0 : first.weekday;
    final hFirst = HijriCalendar.fromDate(first);

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => setState(() => _offset--), child: const Text('السابق')),
                Text('${hFirst.longMonthName} ${hFirst.hYear} هـ / ${first.month}-${first.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton(onPressed: () => setState(() => _offset++), child: const Text('التالي')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']
                  .map((d) => Text(d, style: TextStyle(fontWeight: FontWeight.bold)))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.9),
                itemCount: (satPad % 7) + days,
                itemBuilder: (_, idx) {
                  final pad = satPad % 7;
                  if (idx < pad) return const SizedBox.shrink();
                  final day = idx - pad + 1;
                  final d = DateTime(first.year, first.month, day);
                  final h = HijriCalendar.fromDate(d);
                  final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF114B3E) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? Colors.white : null)),
                        Text('${h.hDay}', style: TextStyle(fontSize: 11, color: isToday ? const Color(0xFFE8D9B0) : Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Text('التاريخ الهجري حسب أم القرى، وقد يختلف يوماً حسب الرؤية.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});
  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  final _prayers = const ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  final _days = const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
  final Map<String, bool> _done = {};

  String _weekKey() {
    final now = DateTime.now();
    final wk = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor();
    return '${now.year}_$wk';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await DataService.prefs();
    final wk = _weekKey();
    for (int i = 0; i < 5; i++) {
      for (int d = 0; d < 7; d++) {
        _done['$i-$d'] = p.getBool('tr_${wk}_$i-$d') ?? false;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle(int i, int d) async {
    final k = '$i-$d';
    final next = !(_done[k] ?? false);
    setState(() => _done[k] = next);
    final p = await DataService.prefs();
    await p.setBool('tr_${_weekKey()}_$k', next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الصلاة الأسبوعية')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 64),
                    ..._days.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))))),
                  ],
                ),
                const Divider(),
                ...List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 64, child: Text(_prayers[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                      ...List.generate(7, (d) {
                        final ok = _done['$i-$d'] ?? false;
                        return Expanded(
                          child: InkWell(
                            onTap: () => _toggle(i, d),
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ok ? const Color(0xFF114B3E) : Colors.transparent,
                                border: Border.all(color: const Color(0xFF114B3E), width: 2),
                              ),
                              child: ok ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FiqhGuideScreen extends StatelessWidget {
  final String title;
  final List<List<String>> sections;
  const FiqhGuideScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...sections.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s[0], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 6),
                      Text(s[1], style: const TextStyle(fontSize: 15, height: 1.8)),
                    ],
                  ),
                ),
              )),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('هذا ملخص تعليمي، وفي التفاصيل خلاف بين المذاهب. راجع دار الإفتاء أو أهل العلم.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المصادر والتراخيص')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('نص القرآن الكريم والتفسير الميسر', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('النص العثماني والتفسير من مشروع تنزيل (tanzil.net) مع الالتزام بعدم تغيير النص وذكر المصدر.'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('حصن المسلم', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('من كتاب الشيخ سعيد بن علي بن وهف القحطاني، وبيانات التطبيق بترخيص MIT (Abdellah SELLAM 2021).'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('تطبيق آثر المؤذن (نسخة مجانية)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('صدقة جارية عني وعن عائلتي وعن جميع المسلمين\nتصميم: محمد بن جاسر بن محمد حسين'),
            ),
          ),
        ],
      ),
    );
  }
}
