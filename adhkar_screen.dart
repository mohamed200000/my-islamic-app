import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_service.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});
  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  int _tab = 0;
  final _cats = const ['الصباح', 'المساء', 'بعد الصلاة', 'النوم', 'الاستيقاظ'];
  final _hisnIdx = const [26, 27, 24, 28, 0];
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final p = await DataService.prefs();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (p.getString('ak_day') != today) {
      await p.setString('ak_day', today);
    } else {
      for (int c = 0; c < _hisnIdx.length; c++) {
        final items = DataService.instance.hisn[_hisnIdx[c]][1] as List;
        for (int i = 0; i < items.length; i++) {
          final k = 'ak_${today}_${c}_$i';
          _counts['${c}_$i'] = p.getInt(k) ?? 0;
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _tap(int i, int max) async {
    final key = '${_tab}_$i';
    final cur = _counts[key] ?? 0;
    if (cur >= max) return;
    HapticFeedback.lightImpact();
    final next = cur + 1;
    setState(() => _counts[key] = next);
    final p = await DataService.prefs();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await p.setInt('ak_${today}_${_tab}_$i', next);
  }

  @override
  Widget build(BuildContext context) {
    final items = DataService.instance.hisn[_hisnIdx[_tab]][1] as List;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('أذكار المسلم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _counts.clear()),
                child: const Text('تصفير'),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(_cats.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_cats[i]),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i] as List;
              final count = _counts['${_tab}_$i'] ?? 0;
              final target = (item[1] as num).toInt();
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(item[0].toString(), style: const TextStyle(fontSize: 19, height: 1.8)),
                      const SizedBox(height: 6),
                      Text(item[2].toString(), style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: '${item[0]}\n${item[2]}'));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                            },
                            child: const Text('نسخ'),
                          ),
                          FilledButton(
                            onPressed: () => _tap(i, target),
                            child: Text('$count / $target${count >= target ? " ✓" : ""}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
