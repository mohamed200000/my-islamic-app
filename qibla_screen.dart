import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../data/governorates.dart';
import '../services/data_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double _bearing = 136.0;

  @override
  void initState() {
    super.initState();
    _loadBearing();
  }

  Future<void> _loadBearing() async {
    final p = await DataService.prefs();
    final idx = p.getInt('govIdx') ?? 0;
    final lat = (idx == 27 ? p.getDouble('gpsLat') : null) ?? governorates[idx.clamp(0, 26)].lat;
    final lng = (idx == 27 ? p.getDouble('gpsLng') : null) ?? governorates[idx.clamp(0, 26)].lng;
    if (mounted) setState(() => _bearing = qiblaBearing(lat, lng));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snap) {
          final heading = snap.data?.heading ?? 0.0;
          final angleRad = ((_bearing - heading) * math.pi) / 180.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('اتجاه القبلة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Transform.rotate(
                angle: angleRad,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F3D33), width: 4),
                    color: Theme.of(context).cardColor,
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation, size: 96, color: Color(0xFF0F3D33)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('${_bearing.round()}° من الشمال', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(snap.hasData && snap.data?.heading != null ? 'البوصلة الحية نشطة' : 'حرّك الهاتف لمعايرة البوصلة'),
            ],
          );
        },
      ),
    );
  }
}
