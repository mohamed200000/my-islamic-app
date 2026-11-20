import 'dart:math' as math;

class Governorate {
  final String name;
  final double lat;
  final double lng;
  const Governorate(this.name, this.lat, this.lng);
}

const List<Governorate> governorates = [
  Governorate('القاهرة', 30.0444, 31.2357),
  Governorate('الجيزة', 30.0131, 31.2089),
  Governorate('الإسكندرية', 31.2001, 29.9187),
  Governorate('القليوبية', 30.4660, 31.1848),
  Governorate('الشرقية', 30.5877, 31.5020),
  Governorate('الدقهلية', 31.0409, 31.3785),
  Governorate('الغربية', 30.7865, 31.0004),
  Governorate('المنوفية', 30.5594, 31.0119),
  Governorate('البحيرة', 31.0341, 30.4682),
  Governorate('كفر الشيخ', 31.1107, 30.9388),
  Governorate('دمياط', 31.4165, 31.8133),
  Governorate('بورسعيد', 31.2653, 32.3019),
  Governorate('الإسماعيلية', 30.5965, 32.2715),
  Governorate('السويس', 29.9668, 32.5498),
  Governorate('شمال سيناء', 31.1316, 33.7984),
  Governorate('جنوب سيناء', 28.2417, 33.6222),
  Governorate('الفيوم', 29.3084, 30.8428),
  Governorate('بني سويف', 29.0661, 31.0994),
  Governorate('المنيا', 28.1099, 30.7503),
  Governorate('أسيوط', 27.1809, 31.1837),
  Governorate('سوهاج', 26.5569, 31.6948),
  Governorate('قنا', 26.1551, 32.7160),
  Governorate('الأقصر', 25.6872, 32.6396),
  Governorate('أسوان', 24.0889, 32.8998),
  Governorate('البحر الأحمر', 27.2579, 33.8116),
  Governorate('الوادي الجديد', 25.4390, 30.5586),
  Governorate('مطروح', 31.3543, 27.2373),
];

/// حساب زاوية القبلة بالدرجات من الشمال الجغرافي
double qiblaBearing(double lat, double lng) {
  const rd = math.pi / 180;
  const kLat = 21.4225 * rd;
  const kLng = 39.8262 * rd;
  final pLat = lat * rd;
  final dLng = kLng - lng * rd;
  final y = math.sin(dLng) * math.cos(kLat);
  final x = math.cos(pLat) * math.sin(kLat) -
      math.sin(pLat) * math.cos(kLat) * math.cos(dLng);
  return ((math.atan2(y, x) / rd) + 360) % 360;
}
