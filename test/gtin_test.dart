import 'package:flutter_app/utils/gtin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates EAN-8, EAN-13, UPC-A and ITF-14 check digits', () {
    expect(normalizeGtin('96385074'), '96385074');
    expect(normalizeGtin('4006381333931'), '4006381333931');
    expect(normalizeGtin('036000291452'), '036000291452');
    expect(normalizeGtin('10012345000017'), '10012345000017');
  });

  test('rejects invalid codes and preserves leading zeroes', () {
    expect(normalizeGtin('4006381333932'), isNull);
    expect(normalizeGtin('not a barcode'), isNull);
    expect(normalizeGtin('0036000291452'), '0036000291452');
  });
}
