import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/adhkar_screen.dart';
import 'screens/duas_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await DataService.instance.loadAll();
  runApp(const IslamicApp());
}

class IslamicApp extends StatefulWidget {
  const IslamicApp({super.key});
  @override
  State<IslamicApp> createState() => _IslamicAppState();
}

class _IslamicAppState extends State<IslamicApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool dark) {
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق مواقيت الصلاة والأذكار',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF114B3E),
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8F3),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF63),
          brightness: Brightness.dark,
          surface: const Color(0xFF122620),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1915),
      ),
      home: AppShell(onThemeChanged: _toggleTheme, themeMode: _themeMode),
    );
  }
}

class AppShell extends StatefulWidget {
  final void Function(bool dark) onThemeChanged;
  final ThemeMode themeMode;
  const AppShell({super.key, required this.onThemeChanged, required this.themeMode});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const AdhkarScreen(),
      const DuasScreen(),
      const QiblaScreen(),
      MoreScreen(onThemeChanged: widget.onThemeChanged, themeMode: widget.themeMode),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'الأدعية'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'القبلة'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'الأقسام'),
        ],
      ),
    );
  }
}
