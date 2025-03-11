import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test within subfolder', () async {
    // ignore: avoid_print
    print('print from test');
  });

  test('another test within subfolder', () async {
    fail('expected to fail');
  });
}
