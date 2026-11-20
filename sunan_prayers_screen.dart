import 'package:flutter/material.dart';
import '../services/data_service.dart';

class SunanPrayersScreen extends StatefulWidget {
  const SunanPrayersScreen({super.key});
  @override
  State<SunanPrayersScreen> createState() => _SunanPrayersScreenState();
}

class _SunanPrayersScreenState extends State<SunanPrayersScreen> {
  int _cat = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cats = DataService.instance.sunanCats;
    final items = DataService.instance.sunanPrayers.where((x) {
      final okCat = _cat == 0 || (x['c'] as num).toInt() == _cat - 1;
      final okQ = _q.isEmpty || x['n'].toString().contains(_q) || x['m'].toString().contains(_q);
      return okCat && okQ;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('الصلوات المسنونة والنوافل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'ابحث عن صلاة', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(label: const Text('الكل'), selected: _cat == 0, onSelected: (_) => setState(() => _cat = 0)),
                ),
                ...List.generate(cats.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(label: Text(cats[i]), selected: _cat == i + 1, onSelected: (_) => setState(() => _cat = i + 1)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((x) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(cats[(x['c'] as num).toInt()], style: const TextStyle(color: Color(0xFF7A5A1A), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(x['n'].toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F3D33))),
                  const SizedBox(height: 6),
                  Text('عدد الركعات: ${x["r"]}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A5A1A))),
                  const SizedBox(height: 4),
                  Text('الوقت: ${x["t"]}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text('الفائدة والمعنى: ${x["m"]}', style: const TextStyle(fontSize: 15, height: 1.7)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEADFC2), borderRadius: BorderRadius.circular(10)),
                    child: Text(x['s'].toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF1D2B26))),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
