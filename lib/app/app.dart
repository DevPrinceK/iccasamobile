import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class IccasaMobileApp extends ConsumerWidget {
  const IccasaMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ICCASA Field',
      debugShowCheckedModeBanner: false,
      theme: buildIccasaTheme(Brightness.light),
      darkTheme: buildIccasaTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
