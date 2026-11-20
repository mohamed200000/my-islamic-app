import 'package:flutter/material.dart';
import '../data/governorates.dart';
import '../services/data_service.dart';
import '../services/prayer_service.dart';
import 'quran_screen.dart';
import 'stories_screen.dart';
import 'hadith_screen.dart';
import 'sunan_prayers_screen.dart';
import 'tools_screens.dart';

class MoreScreen extends StatelessWidget {
  final void Function(bool dark) onThemeChanged;
  final ThemeMode themeMode;
  const MoreScreen({super.key, required this.onThemeChanged, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('القرآن الكريم', Icons.menu_book, const QuranScreen()),
      _MenuItem('تفسير الميسر', Icons.book_outlined, const TafsirScreen()),
      _MenuItem('حصن المسلم', Icons.shield_outlined, const HisnScreen()),
      _MenuItem('قصص وعبر (أثر)', Icons.auto_stories, const StoriesScreen()),
      _MenuItem('الأحاديث الصحيحة', Icons.format_quote, const HadithScreen()),
      _MenuItem('الصلوات المسنونة والنوافل', Icons.star_outline, const SunanPrayersScreen()),
      _MenuItem('السبحة', Icons.touch_app, const TasbihScreen()),
      _MenuItem('ختمة القرآن', Icons.bookmark_added, const KhatmahScreen()),
      _MenuItem('حاسبة الزكاة', Icons.calculate, const ZakatScreen()),
      _MenuItem('تنبيه الاستغفار والصلاة على النبي ﷺ', Icons.notifications_active, const RemindersScreen()),
      _MenuItem('إعدادات الأذان', Icons.volume_up, const AdhanScreen()),
      _MenuItem('كيف أصلي والوضوء', Icons.accessibility_new, const PrayerGuideScreen()),
      _MenuItem('أقرب المساجد', Icons.location_on, const MosquesScreen()),
      _MenuItem('الويدجت والساعة', Icons.watch, const WidgetsScreen()),
      _MenuItem('المستخدمون والإحصائيات', Icons.people_outline, const UsersStatsScreen()),
      _MenuItem('الإعدادات', Icons.settings, SettingsScreen(onThemeChanged: onThemeChanged, themeMode: themeMode)),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => it.page)),
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(it.icon, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(it.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});
  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  PrayerTimes? _pt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await DataService.prefs();
    final idx = p.getInt('govIdx') ?? 0;
    final lat = (idx == 27 ? p.getDouble('gpsLat') : null) ?? governorates[idx.clamp(0, 26)].lat;
    final lng = (idx == 27 ? p.getDouble('gpsLng') : null) ?? governorates[idx.clamp(0, 26)].lng;
    final pt = PrayerService(lat: lat, lng: lng).local(DateTime.now());
    if (mounted) setState(() => _pt = pt);
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "ص" : "م"}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = _pt?.prayers.firstWhere((e) => e.value.isAfter(now), orElse: () => _pt!.prayers.first);
    return Scaffold(
      appBar: AppBar(title: const Text('الويدجت والساعة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_pt != null && next != null)
              Row(
                children: [
                  Container(
                    width: 155,
                    height: 155,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF114B3E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFB68D40).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('القادمة', style: TextStyle(color: Color(0xFFE8D9B0), fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(next.key, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(_fmt(next.value), style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _pt!.prayers.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(e.key), Text(_fmt(e.value), style: const TextStyle(fontWeight: FontWeight.bold))],
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('معاينة شكل الويدجت للشاشة الرئيسية وساعة اليد. لتثبيت ويدجت أصلية على شاشة الهاتف الرئيسية، يلزم ربطها بمشروع Android Widget / WearOS في التطوير المتقدم.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget page;
  _MenuItem(this.title, this.icon, this.page);
}
