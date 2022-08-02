import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ouisync_plugin_platform_interface.dart';

/// An implementation of [OuisyncPluginPlatform] that uses method channels.
class MethodChannelOuisyncPlugin extends OuisyncPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ouisync_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
