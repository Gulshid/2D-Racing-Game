/// 83.456 -> "1:23.46"
String formatTime(double seconds) {
  final total = (seconds * 100).round();
  final cs = total % 100;
  final s = (total ~/ 100) % 60;
  final m = total ~/ 6000;
  return '$m:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
}

/// 1 -> "1st", 2 -> "2nd", 11 -> "11th"
String ordinal(int n) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
