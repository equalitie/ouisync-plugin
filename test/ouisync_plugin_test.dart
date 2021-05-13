import 'package:test/test.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

void main() {
  Session? session;

  setUp(() async {
    session = await Session.open(':memory:');
  });

  tearDown(() {
    session!.close();
    session = null;
  });

  test('stuff happens', () {
    expect(false, equals(true));
  });
}
