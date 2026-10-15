String? normalizeGtin(Object? raw) {
  if (raw == null) return null;
  final digits = raw.toString().replaceAll(RegExp(r'\D'), '');
  if (!const {8, 12, 13, 14}.contains(digits.length)) return null;
  return isValidGtin(digits) ? digits : null;
}

bool isValidGtin(String value) {
  if (!RegExp(r'^\d+$').hasMatch(value) ||
      !const {8, 12, 13, 14}.contains(value.length)) {
    return false;
  }
  var sum = 0;
  for (
    var index = value.length - 2, position = 1;
    index >= 0;
    index--, position++
  ) {
    final digit = value.codeUnitAt(index) - 48;
    sum += digit * (position.isOdd ? 3 : 1);
  }
  final expected = (10 - sum % 10) % 10;
  return expected == value.codeUnitAt(value.length - 1) - 48;
}
