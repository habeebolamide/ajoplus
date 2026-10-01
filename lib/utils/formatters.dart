import 'package:intl/intl.dart';

String money(int amountKobo) {
  final naira = NumberFormat.decimalPattern('en_NG').format(amountKobo ~/ 100);
  final kobo = amountKobo % 100;
  return kobo == 0 ? '₦$naira' : '₦$naira.${kobo.toString().padLeft(2, '0')}';
}

String shortDate(DateTime value) => DateFormat('d MMM yyyy').format(value);

int? parseNairaToKobo(String input) {
  final match = RegExp(r'^\s*(\d{1,10})(?:\.(\d{1,2}))?\s*$').firstMatch(input);
  if (match == null) return null;
  final naira = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final amount = naira * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
  return amount > 0 && amount <= 1000000000000 ? amount : null;
}
