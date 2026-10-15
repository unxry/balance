import 'dart:math';

final Random _secureRandom = Random.secure();

String newEntryId() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
