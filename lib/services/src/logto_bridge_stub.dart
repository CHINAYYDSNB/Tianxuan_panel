/// Stub for native — Logto callback via MethodChannel (TODO)
import 'dart:async';

class LogtoBridge {
  static void redirect(String url) {
    // Native: open URL via platform channel (TODO)
  }

  static Map<String, String> extractCallbackParams() => {};

  static void clearCallbackParams() {}

  static String get callbackUri => 'com.tianxuan.app://callback';

  static String get origin => 'http://localhost:25568';

  static Stream<Uri> get onCallback => const Stream.empty();

  static Future<Uri?> getInitialLink() async => null;
}
