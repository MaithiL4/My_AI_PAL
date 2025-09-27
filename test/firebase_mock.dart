import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Firebase Core
  setupFirebaseCoreMocks();
}

Future<T> neverEndingFuture<T>() async {
  // This future never completes
  await Future.delayed(const Duration(days: 1));
  throw 'This should never complete';
}
