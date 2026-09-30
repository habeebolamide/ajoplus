import 'dart:math';

class PaymentService {
  Future<String> simulate({required bool succeed}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!succeed) {
      throw StateError('The simulated payment failed. Please try again.');
    }
    return 'AJO-PAY-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';
  }
}
