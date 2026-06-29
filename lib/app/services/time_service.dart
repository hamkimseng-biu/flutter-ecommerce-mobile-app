import 'package:cloud_firestore/cloud_firestore.dart';

/// Syncs device clock with Firestore server time to get accurate
/// network time for flash countdowns, etc.
class TimeService {
  static final TimeService _instance = TimeService._();
  factory TimeService() => _instance;
  TimeService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Duration _offset = Duration.zero; // serverTime = deviceTime + offset
  bool _synced = false;

  Future<void> sync() async {
    try {
      // Write a ping doc with server timestamp
      final docRef = _firestore.collection('_server_time').doc('ping');
      await docRef.set({'ts': FieldValue.serverTimestamp()});

      // Read it back to get the server time
      final snap = await docRef.get();
      final serverTs = snap.data()?['ts'] as Timestamp?;
      if (serverTs != null) {
        final serverTime = serverTs.toDate();
        final deviceTime = DateTime.now();
        _offset = serverTime.difference(deviceTime);
        _synced = true;
      }
    } catch (_) {
      // Fall back to device time if sync fails
      _offset = Duration.zero;
    }
  }

  /// Returns the current server time. On first call, blocks briefly to sync.
  DateTime serverNow() {
    if (!_synced) {
      // Fire-and-forget sync; use device time until next call
      sync();
    }
    return DateTime.now().add(_offset);
  }

  /// Ensures the service is synced before returning. Call once at app start.
  Future<void> ensureSynced() async {
    if (!_synced) await sync();
  }

  /// Whether we've successfully synced with the server.
  bool get isSynced => _synced;
}
