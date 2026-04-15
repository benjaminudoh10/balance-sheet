import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// [GetStorage] needs [path_provider] in tests; this stubs the platform channel.
void setupPathProviderMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    return '/tmp';
  });
}
