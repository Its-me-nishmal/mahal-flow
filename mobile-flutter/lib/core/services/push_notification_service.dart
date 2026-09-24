import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/alerts/screens/alert_details_screen.dart';
import '../network/api_service.dart';

/// Root navigator, so a notification tap can route from outside any widget.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Handles messages that arrive while the app is terminated or in the
/// background. Messages with a `notification` block are already drawn by the
/// system tray, so nothing needs to be shown here. Must be top-level and kept
/// through tree shaking.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}

/// Firebase Cloud Messaging for the app.
///
/// Payload contract (FCM `data`, all strings, every key optional):
///   type           ALERT | DUES_REMINDER | RECEIPT | PAYMENT_FAILED | AUTOPAY
///   alert_id       notice to open and acknowledge (type ALERT)
///   severity       INFO | WARNING | ERROR | SUCCESS (type ALERT)
///   receipt_number receipt the push refers to (type RECEIPT)
///   route          explicit named route; wins over the type mapping
///
/// Taps are held until [markSessionReady] is called from a dashboard: a cold
/// start goes splash → login first, and routing before then would be
/// replaced by that flow.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mahalflow_default',
    'Notices & payments',
    description: 'Committee notices, dues reminders and payment updates',
    importance: Importance.high,
  );

  /// Bumped whenever a push arrives in the foreground, so open inbox screens
  /// can reload instead of showing a stale list.
  final ValueNotifier<int> inboxChanged = ValueNotifier<int>(0);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  bool _initialized = false;
  bool _sessionReady = false;
  Map<String, dynamic>? _pendingTap;

  /// Call once after Firebase.initializeApp(). Never throws: notifications
  /// are best-effort and must not block app start.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _initLocalNotifications();

      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      // iOS: let FCM draw foreground notifications itself. Android ignores
      // this, so foreground messages are drawn by [_showForeground].
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

      // App launched from terminated state by tapping a push.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleTap(initial.data);

      // App launched by tapping a notification drawn by [_showForeground].
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _handleTap(_decode(launch!.notificationResponse?.payload));
      }

      await registerToken();
      _messaging.onTokenRefresh.listen(_sendToken);
    } catch (e) {
      debugPrint('[FCM] init failed: $e');
    }
  }

  /// Registers the current device token with the backend. Called at startup
  /// and again after sign-in, so the token is tied to the signed-in member.
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      debugPrint('[FCM] token: ${token.substring(0, 12)}…');
      await _sendToken(token);
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }
  }

  /// Called on sign-out: the backend stops targeting this device and the old
  /// token is invalidated, so the next member on this phone gets a fresh one.
  Future<void> onSignOut() async {
    _sessionReady = false;
    _pendingTap = null;
    try {
      final token = await _messaging.getToken();
      if (token != null) await _api.unregisterDeviceToken(token);
      await _messaging.deleteToken();
      await _local.cancelAll();
    } catch (e) {
      debugPrint('[FCM] sign-out cleanup failed: $e');
    }
  }

  /// Called by the dashboards once the user is signed in. Re-registers the
  /// token under the new session and replays a tap that arrived before then
  /// (cold start from a notification).
  void markSessionReady() {
    if (!_sessionReady) unawaited(registerToken());
    _sessionReady = true;
    final pending = _pendingTap;
    if (pending == null) return;
    _pendingTap = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _route(pending));
  }

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
        // Permission is requested through FirebaseMessaging instead.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _handleTap(_decode(r.payload)),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] foreground: ${message.notification?.title}');
    // Keep the bell badge in step with the notice that just arrived.
    if (_sessionReady) unawaited(_api.getAlerts());
    inboxChanged.value++;
    if (Platform.isAndroid) await _showForeground(message);
  }

  /// Android never draws a push while the app is open; draw it locally so the
  /// member still sees it, carrying the data payload through to the tap.
  Future<void> _showForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    await _local.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
          color: const Color(0xFF146C5B),
          styleInformation: BigTextStyleInformation(body ?? ''),
        ),
      ),
      payload: jsonEncode({
        ...message.data,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      }),
    );
  }

  void _handleTap(Map<String, dynamic> data) {
    debugPrint('[FCM] tapped: $data');
    if (!_sessionReady) {
      _pendingTap = data;
      return;
    }
    _route(data);
  }

  void _route(Map<String, dynamic> data) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    final explicit = data['route']?.toString();
    if (explicit != null && explicit.startsWith('/')) {
      nav.pushNamed(explicit);
      return;
    }

    switch (data['type']?.toString().toUpperCase()) {
      case 'ALERT':
        final alertId = data['alert_id']?.toString();
        if (alertId != null && alertId.isNotEmpty) {
          unawaited(_api.acknowledgeAlert(alertId));
        }
        nav.push(MaterialPageRoute(
          builder: (_) => AlertDetailsScreen(
            title: data['title']?.toString() ?? 'Notice',
            body: data['body']?.toString() ?? '',
            time: 'Just now',
            type: _alertTypeFor(data),
          ),
        ));
      case 'DUES_REMINDER':
      case 'PAYMENT_FAILED':
        nav.pushNamed('/member/pay');
      case 'RECEIPT':
        nav.pushNamed('/member/receipts');
      case 'AUTOPAY':
        nav.pushNamed('/member/setup-autopay');
      default:
        nav.pushNamed('/member/alerts');
    }
  }

  AlertType _alertTypeFor(Map<String, dynamic> data) {
    switch (data['severity']?.toString().toUpperCase()) {
      case 'WARNING':
      case 'ERROR':
        return AlertType.overdue;
      case 'SUCCESS':
        return AlertType.success;
    }
    final title = (data['title']?.toString() ?? '').toLowerCase();
    if (title.contains('payment') || title.contains('due')) {
      return AlertType.payment;
    }
    return AlertType.system;
  }

  Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await _api.registerDeviceToken(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('[FCM] token registration failed: $e');
    }
  }
}
