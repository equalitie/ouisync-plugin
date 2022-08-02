import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ouisync_plugin_method_channel.dart';

abstract class OuisyncPluginPlatform extends PlatformInterface {
  /// Constructs a OuisyncPluginPlatform.
  OuisyncPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static OuisyncPluginPlatform _instance = MethodChannelOuisyncPlugin();

  /// The default instance of [OuisyncPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelOuisyncPlugin].
  static OuisyncPluginPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OuisyncPluginPlatform] when
  /// they register themselves.
  static set instance(OuisyncPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
