import 'package:flutter/material.dart';
import '../services/data_service.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _q = '';
  double _fz = 22;

  @override
  Widget build(BuildContext context) {
    final sn = List<String>.from(DataService.instance.content['SN'] as List);
    final quran = DataService.instance.quran;

    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'ابحث عن سورة', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
          const SizedBox(height: 10),
          ...List.generate(sn.length, (i) => i).where((i) => _q.isEmpty || sn[i].contains(_q)).map((i) {
            final surah = quran[i] as Map<String, dynamic>;
            final ayahs = List<String>.from(surah['a'] as List);
            return Card(
              child: ListTile(
                title: Text('${i + 1}. سورة ${sn[i]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${ayahs.length} آية'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _SurahDetailScreen(name: sn[i], bismillah: surah['b'] as String?, ayahs: ayahs, fz: _fz),
                )),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SurahDetailScreen extends StatefulWidget {
  final String name;
  final String? bismillah;
  final List<String> ayahs;
  final double fz;
  const _SurahDetailScreen({required this.name, this.bismillah, required this.ayahs, required this.fz});

  @override
  State<_SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<_SurahDetailScreen> {
  late double _fz = widget.fz;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${widget.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _fz = (_fz - 2).clamp(16, 38))),
          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _fz = (_fz + 2).clamp(16, 38))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (widget.bismillah != null && widget.bismillah!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(widget.bismillah!, style: TextStyle(fontSize: _fz, fontWeight: FontWeight.bold)),
                  ),
                Text(
                  widget.ayahs.asMap().entries.map((e) => '${e.value} ﴿${e.key + 1}﴾').join(' '),
                  style: TextStyle(fontSize: _fz, height: 2.1),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TafsirScreen extends StatelessWidget {
  const TafsirScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sn = List<String>.from(DataService.instance.content['SN'] as List);
    final quran = DataService.instance.quran;
    final tafsir = DataService.instance.tafsir;
    return Scaffold(
      appBar: AppBar(title: const Text('تفسير الميسر')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sn.length,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              title: Text('${i + 1}. تفسير سورة ${sn[i]}'),
              onTap: () {
                final ayahs = List<String>.from((quran[i] as Map)['a'] as List);
                final tfs = List<String>.from(tafsir[i] as List);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text('تفسير سورة ${sn[i]}')),
                    body: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ayahs.length,
                      itemBuilder: (_, j) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('${ayahs[j]} ﴿${j + 1}﴾', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(tfs[j], style: const TextStyle(height: 1.7)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

class HisnScreen extends StatelessWidget {
  const HisnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final hisn = DataService.instance.hisn;
    return Scaffold(
      appBar: AppBar(title: const Text('حصن المسلم')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hisn.length,
        itemBuilder: (_, i) {
          final ch = hisn[i] as List;
          final items = ch[1] as List;
          return Card(
            child: ListTile(
              title: Text(ch[0].toString()),
              trailing: Text('${items.length}'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(ch[0].toString())),
                  body: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, j) => Card(
                      child: ListTile(
                        title: Text(items[j][0].toString(), style: const TextStyle(fontSize: 18, height: 1.8)),
                        subtitle: Text('${items[j][2]} · التكرار: ${items[j][1]}'),
                      ),
                    ),
                  ),
                ),
              )),
            ),
          );
        },
      ),
    );
  }
}
