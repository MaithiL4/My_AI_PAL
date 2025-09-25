import 'package:flutter/foundation.dart';

class ErrorService {
  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
    // In a real app, you would log this to a remote service like Sentry or Firebase Crashlytics
  }
}
