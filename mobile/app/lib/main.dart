import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/inbox_app.dart';
import 'app/provider_logger.dart';
import 'di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setUp();
  runApp(
    ProviderScope(
      observers: kDebugMode ? const [ProviderLogger()] : const [],
      child: const InboxApp(),
    ),
  );
}
