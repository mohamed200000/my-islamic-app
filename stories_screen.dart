import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_service.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});
  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  int _cat = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cats = DataService.instance.storyCats;
    final stories = DataService.instance.stories;
    final filtered = stories.where((s) {
      final okCat = _cat == 0 || (s['c'] as num).toInt() == _cat - 1;
      final okQ = _q.isEmpty || s['t'].toString().contains(_q) || s['b'].toString().contains(_q);
      return okCat && okQ;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('قصص وعبر (أثر)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'ابحث في القصص', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
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
                ...List.generate(cats.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(label: Text(cats[i]), selected: _cat == i + 1, onSelected: (_) => setState(() => _cat = i + 1)),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...filtered.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(cats[(s['c'] as num).toInt()], style: const TextStyle(color: Color(0xFF7A5A1A), fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(s['t'].toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F3D33))),
                      const SizedBox(height: 8),
                      Text(s['b'].toString(), style: const TextStyle(fontSize: 16, height: 1.8)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFEADFC2), borderRadius: BorderRadius.circular(12)),
                        child: Text('الأثر والعبرة: ${s["l"]}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D2B26))),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('المصدر: ${s["s"]}', style: Theme.of(context).textTheme.bodySmall)),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: '${s["t"]}\n${s["b"]}\n${s["l"]}'));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                            },
                          ),
                        ],
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
