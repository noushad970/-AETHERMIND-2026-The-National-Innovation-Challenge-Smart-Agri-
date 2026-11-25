import 'package:ai_agri_assistant/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses settings, skipping comments and blank lines', () {
    final values = Env.parse(
      '# comment\r\n\r\nA=1\r\nB = "two" \nC=\nURL=https://x.test/?a=b\n=bad\n',
    );

    expect(values, {
      'A': '1',
      'B': 'two',
      'C': '',
      'URL': 'https://x.test/?a=b',
    });
  });

  test('a dart-define value wins, and the fallback covers a missing key', () {
    expect(Env.value('MISSING', 'defined'), 'defined');
    expect(Env.value('MISSING', '', fallback: 'default'), 'default');
    expect(Env.value('MISSING', ''), '');
  });
}
