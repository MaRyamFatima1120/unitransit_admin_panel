import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message) {
    debugPrint('[Uni-Transit Admin] $message');
  }

  static void error(String message, [dynamic error]) {
    debugPrint('[ERROR] $message: $error');
  }
}
