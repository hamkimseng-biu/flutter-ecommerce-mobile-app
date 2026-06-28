import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../../config/app_snack.dart';

/// Firebase Cloud Messaging — push notification service.
///
/// - Requests notification permission
/// - Stores FCM token per-user in Firestore
/// - Shows in-app snackbar for foreground messages
/// - Saves notifications to Firestore for history
/// - Handles notification-tap deep-linking
class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call once at app startup after Firebase.initializeApp() and auth
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus.name}');

    // Get & store FCM token
    await _refreshToken();

    // Token refresh listener
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages → in-app snackbar + save to history
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background tap → navigate
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App opened from terminated state via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  // ── Token ─────────────────────────────────────────────────────

  Future<void> _refreshToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) _saveToken(token);
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('[FCM] Token saved for $uid');
  }

  // ── Foreground ────────────────────────────────────────────────

  void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ?? 'Tiny Chicken';
    final body = message.notification?.body ?? '';
    debugPrint('[FCM] Foreground: $title');

    try {
      AppSnack.info(title, body);
    } catch (_) {}

    _saveToHistory(title, body);
  }

  // ── Tap / deep link ───────────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    debugPrint('[FCM] Tapped: ${message.data}');
    _saveToHistory(
      message.notification?.title ?? 'Tiny Chicken',
      message.notification?.body ?? '',
    );
    _navigate(message.data);
  }

  void _navigate(Map<String, dynamic> data) {
    final screen = data['screen'] ?? data['orderId'];
    if (screen == null) {
      Get.toNamed(AppRoutes.main);
      return;
    }
    final s = screen.toString();
    if (s.startsWith('order:')) {
      final orderId = s.substring(6);
      Get.toNamed(
        AppRoutes.orderDetail,
        arguments: {
          'id': '#${orderId.substring(0, 8).toUpperCase()}',
          'firestoreId': orderId,
        },
      );
    } else if (s == 'orders') {
      Get.toNamed(AppRoutes.orders);
    } else {
      Get.toNamed(AppRoutes.main);
    }
  }

  // ── Notification history in Firestore ─────────────────────────

  CollectionReference get _notifsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  Future<void> _saveToHistory(String title, String body) async {
    try {
      await _notifsRef.add({
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    try {
      return _notifsRef.orderBy('createdAt', descending: true).snapshots();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> markAsRead(String docId) async {
    try {
      await _notifsRef.doc(docId).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final unread = await _notifsRef.where('read', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Stream of unread notification count for badge display
  Stream<int> getUnreadCountStream() {
    try {
      return _notifsRef
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.docs.length);
    } catch (_) {
      return Stream.value(0);
    }
  }
}
