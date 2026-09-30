import 'package:intl/intl.dart';

String money(int amountKobo) {
  final naira = NumberFormat.decimalPattern('en_NG').format(amountKobo ~/ 100);
  final kobo = amountKobo % 100;
  return kobo == 0 ? '₦$naira' : '₦$naira.${kobo.toString().padLeft(2, '0')}';
}

String shortDate(DateTime value) => DateFormat('d MMM yyyy').format(value);
