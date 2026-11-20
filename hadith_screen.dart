import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_service.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});
  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final hadiths = DataService.instance.content['H'] as List;
    final filtered = List.generate(hadiths.length, (i) => i)
        .where((i) => _q.isEmpty || hadiths[i][0].toString().contains(_q) || hadiths[i][4].toString().contains(_q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('الأحاديث الصحيحة (الأربعون النووية)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'ابحث في الأحاديث', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
          const SizedBox(height: 10),
          ...filtered.map((i) {
            final h = hadiths[i] as List;
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF0F3D33), child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                title: Text(h[0].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${h[1]} · ${h[3]}'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _HadithDetailScreen(index: i, item: h))),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HadithDetailScreen extends StatelessWidget {
  final int index;
  final List item;
  const _HadithDetailScreen({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الحديث ${index + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${item[0]}\n${item[4]}\n(${item[1]})'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item[0].toString(), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF0F3D33))),
          const SizedBox(height: 4),
          Text('${item[1]} · ${item[3]}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item[4].toString(), style: const TextStyle(fontSize: 20, height: 1.9)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFEADFC2), borderRadius: BorderRadius.circular(14)),
            child: Text('قصة الحديث ومناسبته: ${item[5]}', style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF1D2B26))),
          ),
        ],
      ),
    );
  }
}
