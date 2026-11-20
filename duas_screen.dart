import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_service.dart';

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});
  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  int _cat = 0;
  int _istighfar = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ct = List<String>.from(DataService.instance.content['CT'] as List);
    final duas = DataService.instance.content['DU'] as List;
    final filtered = duas.where((d) {
      final matchesCat = _cat == 0 || (d[0] as num).toInt() == _cat - 1;
      final matchesQ = _query.isEmpty || d[1].toString().contains(_query);
      return matchesCat && matchesQ;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF0F3D33),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF6F1E6), fontSize: 18)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _istighfar++);
                  },
                  style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(32)),
                  child: Text('$_istighfar', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() => _istighfar = 0),
                  child: const Text('تصفير', style: TextStyle(color: Color(0xFFE8D9B0))),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(hintText: 'ابحث في الأدعية', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _query = v.trim()),
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
              ...List.generate(ct.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(label: Text(ct[i]), selected: _cat == i + 1, onSelected: (_) => setState(() => _cat = i + 1)),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...filtered.map((d) => Card(
              child: ListTile(
                title: Text(d[1].toString(), style: const TextStyle(fontSize: 18, height: 1.7)),
                subtitle: Text(d[2].toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${d[1]}\n${d[2]}'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                  },
                ),
              ),
            )),
      ],
    );
  }
}
