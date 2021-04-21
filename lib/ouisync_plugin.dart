
import 'dart:async';

import 'package:flutter/services.dart';

class OuisyncPlugin {
  static const MethodChannel _channel =
      const MethodChannel('ouisync_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
