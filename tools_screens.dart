import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});
  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _idx = 0;
  int _count = 0;
  final _labels = const ['سبحان الله', 'الحمد لله', 'الله أكبر'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السبحة')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              children: List.generate(3, (i) => ChoiceChip(
                label: Text(_labels[i]),
                selected: _idx == i,
                onSelected: (_) => setState(() { _idx = i; _count = 0; }),
              )),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _count++);
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF114B3E),
                foregroundColor: const Color(0xFFFAF8F3),
                padding: const EdgeInsets.all(64),
              ),
              child: Text('$_count', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => setState(() => _count = 0), child: const Text('تصفير')),
          ],
        ),
      ),
    );
  }
}

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});
  @override
  State<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends State<KhatmahScreen> {
  int _juz = 1;
  bool _fajrReminder = true;

  @override
  void initState() {
    super.initState();
    DataService.prefs().then((p) {
      if (mounted) {
        setState(() {
          _juz = p.getInt('khatmahJuz') ?? 1;
          _fajrReminder = p.getBool('khatmahFajr') ?? true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ختمة القرآن')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('الجزء $_juz من ٣٠', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _juz / 30),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () async {
                            final next = (_juz + 1).clamp(0, 30);
                            setState(() => _juz = next);
                            (await DataService.prefs()).setInt('khatmahJuz', next);
                          },
                          child: const Text('أتممت جزءاً'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final next = (_juz - 1).clamp(0, 30);
                            setState(() => _juz = next);
                            (await DataService.prefs()).setInt('khatmahJuz', next);
                          },
                          child: const Text('تراجع'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('تذكير يومي بعد الفجر'),
              value: _fajrReminder,
              onChanged: (v) async {
                setState(() => _fajrReminder = v);
                (await DataService.prefs()).setBool('khatmahFajr', v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});
  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _cash = TextEditingController();
  final _gold = TextEditingController();
  final _price = TextEditingController();
  final _stocks = TextEditingController();
  final _debt = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = DataService.parseArabicNumber(_price.text);
    final total = DataService.parseArabicNumber(_cash.text) +
        DataService.parseArabicNumber(_gold.text) * p +
        DataService.parseArabicNumber(_stocks.text) -
        DataService.parseArabicNumber(_debt.text);
    final nisab = 85 * p;

    String result;
    if (p <= 0) {
      result = 'أدخل سعر جرام الذهب لحساب النصاب';
    } else if (total >= nisab) {
      result = 'المجموع ${total.round()} · الزكاة (٢.٥٪): ${(total * 0.025).toStringAsFixed(2)}';
    } else {
      result = 'المجموع ${total.round()} أقل من النصاب (${nisab.round()}) · لا زكاة الآن';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الزكاة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in [
            ['المال النقدي', _cash],
            ['الذهب (جرام)', _gold],
            ['سعر جرام الذهب اليوم', _price],
            ['الأسهم والتجارة', _stocks],
            ['ديون مستحقة عليك', _debt],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: item[1] as TextEditingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: item[0] as String, border: const OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
            ),
          Card(
            color: const Color(0xFF114B3E),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(result, style: const TextStyle(color: Color(0xFFFAF8F3), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _istighfar = false;
  bool _salawat = false;
  int _minutes = 5;
  int _secLeft = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    DataService.prefs().then((p) {
      if (mounted) {
        setState(() {
          _istighfar = p.getBool('remIstighfar') ?? false;
          _salawat = p.getBool('remSalawat') ?? false;
          _minutes = p.getInt('remMinutes') ?? 5;
          _secLeft = _minutes * 60;
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || (!_istighfar && !_salawat)) return;
      setState(() {
        if (_secLeft > 1) {
          _secLeft--;
        } else {
          _secLeft = _minutes * 60;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _update() async {
    final p = await DataService.prefs();
    await p.setBool('remIstighfar', _istighfar);
    await p.setBool('remSalawat', _salawat);
    await p.setInt('remMinutes', _minutes);
    setState(() => _secLeft = _minutes * 60);
    await NotificationService.instance.scheduleDhikrReminders(
      istighfarOn: _istighfar,
      salawatOn: _salawat,
      minutes: _minutes,
    );
  }

  String _fmtTimer() {
    final m = (_secLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final active = _istighfar || _salawat;
    return Scaffold(
      appBar: AppBar(title: const Text('تنبيه الاستغفار والصلاة على النبي ﷺ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF114B3E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB68D40).withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Text('أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFFAF8F3), fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE8D9B0), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Text(
                  active ? 'العد التنازلي للتنبيه القادم: ${_fmtTimer()}' : 'فعّل أحد التنبيهات بالأسفل لبدء العداد',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('تفعيل تنبيه الاستغفار'),
            value: _istighfar,
            onChanged: (v) { setState(() => _istighfar = v); _update(); },
          ),
          SwitchListTile(
            title: const Text('تفعيل الصلاة على سيدنا محمد ﷺ'),
            value: _salawat,
            onChanged: (v) { setState(() => _salawat = v); _update(); },
          ),
          const SizedBox(height: 8),
          const Text('التكرار كل:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 30].map((m) => ChoiceChip(
              label: Text('$m دقائق'),
              selected: _minutes == m,
              onSelected: (_) { setState(() => _minutes = m); _update(); },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class AdhanScreen extends StatefulWidget {
  const AdhanScreen({super.key});
  @override
  State<AdhanScreen> createState() => _AdhanScreenState();
}

class _AdhanScreenState extends State<AdhanScreen> {
  final _player = AudioPlayer();
  int _selected = 0;
  int _playing = -1;
  final _files = const [
    ['أذان أحمد الكوردي', 'audio/adhan_1_ahmed_alkurdi.mp3'],
    ['أذان الجزائر', 'audio/adhan_2_algeria.mp3'],
    ['أذان قطر', 'audio/adhan_3_qatar.mp3'],
    ['أذان مصر', 'audio/adhan_4_egypt.mp3'],
    ['أذان مشاري راشد', 'audio/adhan_5_mishary_rashid.mp3'],
  ];

  @override
  void initState() {
    super.initState();
    DataService.prefs().then((p) {
      if (mounted) setState(() => _selected = (p.getInt('selectedAdhan') ?? 0).clamp(0, 4));
    });
  }

  Future<void> _select(int i) async {
    setState(() => _selected = i);
    final p = await DataService.prefs();
    await p.setInt('selectedAdhan', i);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الأذان')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _files.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            onTap: () => _select(i),
            leading: Radio<int>(value: i, groupValue: _selected, onChanged: (v) => _select(v!)),
            title: Text(_files[i][0]),
            trailing: FilledButton(
              onPressed: () async {
                if (_playing == i) {
                  await _player.stop();
                  setState(() => _playing = -1);
                } else {
                  await _player.stop();
                  await _player.play(AssetSource(_files[i][1]));
                  setState(() => _playing = i);
                }
              },
              child: Text(_playing == i ? 'إيقاف' : 'تشغيل'),
            ),
          ),
        ),
      ),
    );
  }
}

class PrayerGuideScreen extends StatelessWidget {
  const PrayerGuideScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const steps = ['تكبيرة الإحرام', 'القيام ووضع اليدين', 'الركوع', 'السجود', 'الجلوس للتشهد'];
    return Scaffold(
      appBar: AppBar(title: const Text('كيف أصلي والوضوء (رسوم بدون ملامح)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CustomPaint(size: const Size(84, 84), painter: _FacelessPosePainter(i)),
                const SizedBox(width: 14),
                Text('${i + 1}. ${steps[i]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacelessPosePainter extends CustomPainter {
  final int step;
  _FacelessPosePainter(this.step);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF114B3E)..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF114B3E)..style = PaintingStyle.fill;
    canvas.drawLine(Offset(6, size.height - 6), Offset(size.width - 6, size.height - 6), Paint()..color = Colors.grey..strokeWidth = 2);
    if (step <= 1) {
      canvas.drawCircle(Offset(size.width / 2, 16), 7, fill);
      canvas.drawLine(Offset(size.width / 2, 24), Offset(size.width / 2, 54), p);
      canvas.drawLine(Offset(size.width / 2, 54), Offset(size.width / 2 - 8, 76), p);
      canvas.drawLine(Offset(size.width / 2, 54), Offset(size.width / 2 + 8, 76), p);
    } else if (step == 2) {
      canvas.drawCircle(Offset(size.width * 0.72, 38), 7, fill);
      canvas.drawLine(Offset(size.width * 0.30, 38), Offset(size.width * 0.64, 38), p);
      canvas.drawLine(Offset(size.width * 0.30, 38), Offset(size.width * 0.30, 76), p);
    } else if (step == 3) {
      canvas.drawCircle(Offset(size.width * 0.78, 70), 6, fill);
      canvas.drawLine(Offset(size.width * 0.24, 76), Offset(size.width * 0.42, 54), p);
      canvas.drawLine(Offset(size.width * 0.42, 54), Offset(size.width * 0.70, 70), p);
    } else {
      canvas.drawCircle(Offset(size.width * 0.42, 26), 7, fill);
      canvas.drawLine(Offset(size.width * 0.42, 34), Offset(size.width * 0.42, 62), p);
      canvas.drawLine(Offset(size.width * 0.42, 62), Offset(size.width * 0.70, 72), p);
    }
  }
  @override
  bool shouldRepaint(covariant _FacelessPosePainter oldDelegate) => oldDelegate.step != step;
}

class MosquesScreen extends StatelessWidget {
  const MosquesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أقرب المساجد')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.map),
          label: const Text('افتح المساجد القريبة في الخريطة'),
          onPressed: () async {
            final p = await DataService.prefs();
            final lat = p.getDouble('gpsLat') ?? 30.0444;
            final lng = p.getDouble('gpsLng') ?? 31.2357;
            await launchUrl(Uri.parse('https://www.google.com/maps/search/mosque/@$lat,$lng,15z'), mode: LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }
}

class UsersStatsScreen extends StatefulWidget {
  const UsersStatsScreen({super.key});
  @override
  State<UsersStatsScreen> createState() => _UsersStatsScreenState();
}

class _UsersStatsScreenState extends State<UsersStatsScreen> {
  final _apiCtrl = TextEditingController();
  String _status = 'وضع محلي (بدون خادم) — أدخل رابط API لعرض المستخدمين المباشرين';

  Future<void> _ping() async {
    final url = _apiCtrl.text.trim();
    if (url.isEmpty) return;
    try {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      final d = jsonDecode(r.body);
      final n = d['active'] ?? d['count'] ?? d['users'];
      setState(() => _status = n != null ? '$n مستخدم متصل الآن' : 'تم الاتصال (تنسيق غير معروف)');
    } catch (_) {
      setState(() => _status = 'تعذر الاتصال بالخادم');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون والإحصائيات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('عدد المستخدمين الحاليين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(fontSize: 16, color: Color(0xFFB68D40), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiCtrl,
              decoration: const InputDecoration(labelText: 'رابط خادم الإحصائيات (API)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _ping, child: const Text('تحديث العداد الآن')),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final void Function(bool dark) onThemeChanged;
  final ThemeMode themeMode;
  const SettingsScreen({super.key, required this.onThemeChanged, required this.themeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifOk = true;
  bool _exactOk = true;
  bool _gpsOk = false;
  bool _istighfarOn = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final res = await NotificationService.instance.checkPermissions();
    final perm = await Geolocator.checkPermission();
    final p = await DataService.prefs();
    if (mounted) {
      setState(() {
        _notifOk = res['notif'] ?? false;
        _exactOk = res['exact'] ?? false;
        _gpsOk = perm == LocationPermission.always || perm == LocationPermission.whileInUse;
        _istighfarOn = p.getBool('remIstighfar') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والأذونات')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('الوضع الداكن'),
                  subtitle: const Text('مناسب للقراءة الليلية وتخفيف إجهاد العين'),
                  value: isDark,
                  onChanged: widget.onThemeChanged,
                ),
                SwitchListTile(
                  title: const Text('تفعيل إشعارات الاستغفار والصلاة على النبي ﷺ'),
                  subtitle: const Text('إشعار بصوت الاستغفار كل ٥ دقائق'),
                  value: _istighfarOn,
                  onChanged: (v) async {
                    setState(() => _istighfarOn = v);
                    final p = await DataService.prefs();
                    await p.setBool('remIstighfar', v);
                    await p.setBool('remSalawat', v);
                    await NotificationService.instance.scheduleDhikrReminders(istighfarOn: v, salawatOn: v, minutes: 5);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('حالة أذونات التطبيق على الهاتف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('إذن الإشعارات'),
                    trailing: Text(_notifOk ? 'مفعّل ✓' : 'مغلق ✗', style: TextStyle(color: _notifOk ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('إذن المنبهات الدقيقة (للأذان والذكر)'),
                    trailing: Text(_exactOk ? 'مفعّل ✓' : 'مغلق ✗', style: TextStyle(color: _exactOk ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('إذن الموقع الجغرافي (GPS)'),
                    trailing: Text(_gpsOk ? 'مفعّل ✓' : 'مغلق ✗', style: TextStyle(color: _gpsOk ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await NotificationService.instance.requestPermissions();
                            await Geolocator.requestPermission();
                            await _refresh();
                          },
                          child: const Text('منح الأذونات'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Geolocator.openAppSettings();
                          },
                          child: const Text('إعدادات الهاتف'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('جرّب إشعار الاستغفار والصلاة الآن'),
                    onPressed: () => NotificationService.instance.showDhikrNow(),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('نسخة مجانية · صدقة جارية عني وعن عائلتي وعن جميع المسلمين\nتصميم: محمد بن جاسر بن محمد حسين', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
