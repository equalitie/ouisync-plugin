import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ouisync_plugin/ouisync_plugin_method_channel.dart';

void main() {
  MethodChannelOuisyncPlugin platform = MethodChannelOuisyncPlugin();
  const MethodChannel channel = MethodChannel('ouisync_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
