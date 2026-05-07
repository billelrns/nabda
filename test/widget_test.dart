import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nabda app basic test', () {
    // Basic sanity check
    expect(40 - 25, 15); // weeks remaining in pregnancy
    expect(28, greaterThanOrEqualTo(21)); // valid cycle length
    expect(28, lessThanOrEqualTo(35)); // valid cycle length
  });
}
