import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

String mobileNotificationRoute(Map<String, dynamic> data) {
  final route = data['route'];
  if (route == '/assignments') return '/assignments';
  if (route == '/records') return '/records';
  return '/home';
}

class PushNotifications {
  PushNotifications(this._api);

  final ApiClient _api;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openSubscription;
  Future<void>? _starting;
  Timer? _retryTimer;
  String? _registeredToken;
  bool _active = false;

  void Function(RemoteMessage)? onForeground;
  void Function(String)? onOpen;

  bool get available =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      Firebase.apps.isNotEmpty;

  Future<void> start() async {
    if (!available) return;
    _active = true;
    if (_starting != null) return _starting;
    _starting = _start();
    try {
      await _starting;
    } finally {
      _starting = null;
    }
  }

  Future<void> _start() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (!_active ||
          permission.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      _tokenSubscription ??= messaging.onTokenRefresh.listen(
        (token) => unawaited(_register(token)),
      );
      _messageSubscription ??= FirebaseMessaging.onMessage.listen((message) {
        if (_active) onForeground?.call(message);
      });
      _openSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        if (_active) onOpen?.call(mobileNotificationRoute(message.data));
      });

      final initial = await messaging.getInitialMessage();
      if (!_active) return;
      if (initial != null) {
        onOpen?.call(mobileNotificationRoute(initial.data));
      }
      if (Platform.isIOS && await messaging.getAPNSToken() == null) {
        _scheduleRetry(start);
        return;
      }
      final token = await messaging.getToken();
      if (token != null) {
        await _register(token);
      } else {
        _scheduleRetry(start);
      }
    } catch (_) {
      debugPrint('Push notification setup is unavailable.');
      _scheduleRetry(start);
    }
  }

  Future<void> _register(String token) async {
    if (!_active || token.isEmpty || token == _registeredToken) return;
    try {
      final previousToken = _registeredToken;
      await _api.registerPushDevice(token, Platform.isIOS ? 'ios' : 'android');
      if (_active) {
        _registeredToken = token;
        _retryTimer?.cancel();
        if (previousToken != null && previousToken != token) {
          try {
            await _api.unregisterPushDevice(
              previousToken,
              Platform.isIOS ? 'ios' : 'android',
            );
          } catch (_) {
            // FCM will identify and remove the stale registration on delivery.
          }
        }
      }
    } catch (_) {
      debugPrint('Push device registration failed.');
      _scheduleRetry(() => _register(token));
    }
  }

  void _scheduleRetry(Future<void> Function() action) {
    if (!_active) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 1), () {
      if (_active) unawaited(action());
    });
  }

  Future<void> stop({bool unregister = true}) async {
    _active = false;
    _retryTimer?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    _openSubscription = null;
    if (!available) return;
    try {
      if (unregister) {
        final token =
            _registeredToken ?? await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _api.unregisterPushDevice(
            token,
            Platform.isIOS ? 'ios' : 'android',
          );
        }
      }
    } catch (_) {
      debugPrint('Push device unregistration failed.');
    } finally {
      _registeredToken = null;
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        debugPrint('Push token cleanup failed.');
      }
    }
  }

  void dispose() {
    _active = false;
    _retryTimer?.cancel();
    unawaited(_tokenSubscription?.cancel());
    unawaited(_messageSubscription?.cancel());
    unawaited(_openSubscription?.cancel());
  }
}
