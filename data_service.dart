import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataService {
  DataService._();
  static final DataService instance = DataService._();

  List<dynamic> quran = [];
  List<dynamic> tafsir = [];
  List<dynamic> hisn = [];
  Map<String, dynamic> content = {};
  List<dynamic> stories = [];
  List<String> storyCats = [];
  List<dynamic> sunanPrayers = [];
  List<String> sunanCats = [];
  bool loaded = false;

  Future<void> loadAll() async {
    if (loaded) return;
    final qStr = await rootBundle.loadString('assets/data/quran.json');
    final tStr = await rootBundle.loadString('assets/data/tafsir.json');
    final hStr = await rootBundle.loadString('assets/data/hisn.json');
    final cStr = await rootBundle.loadString('assets/data/content.json');
    final sStr = await rootBundle.loadString('assets/data/stories.json');
    final spStr = await rootBundle.loadString('assets/data/sunan_prayers.json');

    quran = jsonDecode(qStr) as List<dynamic>;
    tafsir = jsonDecode(tStr) as List<dynamic>;
    hisn = jsonDecode(hStr) as List<dynamic>;
    content = jsonDecode(cStr) as Map<String, dynamic>;
    final sMap = jsonDecode(sStr) as Map<String, dynamic>;
    stories = sMap['ST'] as List<dynamic>;
    storyCats = List<String>.from(sMap['ST_CT'] as List);
    final spMap = jsonDecode(spStr) as Map<String, dynamic>;
    sunanPrayers = spMap['SP'] as List<dynamic>;
    sunanCats = List<String>.from(spMap['SP_CT'] as List);
    loaded = true;
  }

  static double parseArabicNumber(String input) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    var out = input.trim();
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(ar[i], '$i');
    }
    out = out.replaceAll('٫', '.').replaceAll(',', '.');
    return double.tryParse(out) ?? 0.0;
  }

  static Future<SharedPreferences> prefs() => SharedPreferences.getInstance();
}
