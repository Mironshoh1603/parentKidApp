/// Sekundlarni o'qiladigan ko'rinishga aylantiradi: "2 soat 15 daq".
String formatDuration(int seconds) {
  if (seconds <= 0) return '0 daq';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0 && m > 0) return '$h soat $m daq';
  if (h > 0) return '$h soat';
  if (m > 0) return '$m daq';
  return '$seconds s';
}
