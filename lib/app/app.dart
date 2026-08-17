import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state/app_controller.dart';
import 'router.dart';
import 'theme.dart';

class IccasaFieldApp extends ConsumerStatefulWidget {
  const IccasaFieldApp({super.key});

  @override
  ConsumerState<IccasaFieldApp> createState() => _IccasaFieldAppState();
}

class _IccasaFieldAppState extends ConsumerState<IccasaFieldApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref.read(appControllerProvider));
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return MaterialApp.router(
      title: 'ICCASA Field',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(highContrast: controller.highContrast),
      darkTheme: buildDarkTheme(highContrast: controller.highContrast),
      themeMode: controller.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(controller.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
