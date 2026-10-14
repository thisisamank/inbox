import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class InboxApp extends ConsumerWidget {
  const InboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Agentic Inbox',
    debugShowCheckedModeBanner: false,
    theme: InTheme.build(Brightness.light),
    darkTheme: InTheme.build(Brightness.dark),
    routerConfig: ref.watch(routerProvider),
  );
}
