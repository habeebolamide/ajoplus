import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

final _algorithm = Argon2id(
  memory: 10 * 1000,
  parallelism: 2,
  iterations: 2,
  hashLength: 32,
);

Future<String> hashPassword(String password) async {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final key = await _algorithm.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );
  final hash = await key.extractBytes();
  return 'argon2id:${base64Url.encode(salt)}:${base64Url.encode(hash)}';
}

Future<bool> verifyPassword(String password, String storedHash) async {
  final parts = storedHash.split(':');
  if (parts.length != 3 || parts.first != 'argon2id') {
    throw const FormatException('Invalid password hash');
  }

  final salt = base64Url.decode(parts[1]);
  final expected = base64Url.decode(parts[2]);
  final key = await _algorithm.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );
  final actual = await key.extractBytes();
  if (actual.length != expected.length) return false;

  var difference = 0;
  for (var index = 0; index < actual.length; index++) {
    difference |= actual[index] ^ expected[index];
  }
  return difference == 0;
}
