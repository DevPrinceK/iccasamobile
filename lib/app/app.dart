import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state/app_controller.dart';
import '../core/services/push_notifications.dart';
import '../core/models/field_models.dart';
import 'router.dart';
import 'theme.dart';

class IccasaFieldApp extends ConsumerStatefulWidget {
  const IccasaFieldApp({super.key});

  @override
  ConsumerState<IccasaFieldApp> createState() => _IccasaFieldAppState();
}

class _IccasaFieldAppState extends ConsumerState<IccasaFieldApp> {
  late final GoRouter _router;
  late final AppController _controller;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _pendingNotificationRoute;

  @override
  void initState() {
    super.initState();
    final controller = _controller = ref.read(appControllerProvider);
    _router = createAppRouter(controller);
    controller.addListener(_openPendingNotification);
    controller.pushNotifications.onForeground = (message) {
      unawaited(controller.refreshAll(silent: true));
      final title = message.notification?.title ?? 'ICCASA update';
      final body = message.notification?.body ?? 'You have a new notification.';
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () =>
                _openNotificationRoute(mobileNotificationRoute(message.data)),
          ),
        ),
      );
    };
    controller.pushNotifications.onOpen = _openNotificationRoute;
  }

  void _openNotificationRoute(String route) {
    if (_controller.stage == AppStage.signedIn) {
      unawaited(_controller.refreshAll(silent: true));
    }
    _pendingNotificationRoute = route;
    _openPendingNotification();
  }

  void _openPendingNotification() {
    if (_pendingNotificationRoute == null ||
        _controller.stage != AppStage.signedIn) {
      return;
    }
    final route = _pendingNotificationRoute!;
    _pendingNotificationRoute = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _router.go(route);
    });
  }

  @override
  void dispose() {
    final controller = _controller;
    controller.removeListener(_openPendingNotification);
    controller.pushNotifications.onForeground = null;
    controller.pushNotifications.onOpen = null;
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
      scaffoldMessengerKey: _messengerKey,
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
