import 'package:example/ide/testing/test_discoverer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lsp/test_tools.dart';

void main() {
  group('TestDiscoverer >', () {
    testLsp('extracts tests from folders', (lspTester) async {
      final discoverer = LspTestDiscoverer(
        lspClient: lspTester.client,
      );

      final tests = await discoverer.discoverTests();

      expect(tests, isNotEmpty);
    });
  });
}
