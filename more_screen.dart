import 'package:flutter/material.dart';
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
                Icon(it.icon, size: 28, color: const Color(0xFF0F3D33)),
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

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget page;
  _MenuItem(this.title, this.icon, this.page);
}
