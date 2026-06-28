import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CurrencyController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current currency code: 'USD', 'KHR', 'EUR'
  final RxString currency = 'USD'.obs;

  /// Symbol for the current currency
  String get symbol {
    switch (currency.value) {
      case 'KHR':
        return '៛';
      case 'EUR':
        return '€';
      default:
        return '\$';
    }
  }

  /// Rate from USD to target currency
  double get rate {
    switch (currency.value) {
      case 'KHR':
        return 4100;
      case 'EUR':
        return 0.92;
      default:
        return 1.0;
    }
  }

  StreamSubscription? _userSub;
  String _currentUid = '';

  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? '';
      if (uid != _currentUid) {
        _currentUid = uid;
        _loadCurrency();
      }
    });
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    _userSub?.cancel();
    if (_currentUid.isNotEmpty) {
      _userSub = _firestore
          .collection('users')
          .doc(_currentUid)
          .snapshots()
          .listen((doc) {
            if (doc.exists) {
              final userCurrency = doc.data()?['currency'] as String?;
              if (userCurrency != null && userCurrency.isNotEmpty) {
                final code = _parseCode(userCurrency);
                if (currency.value != code) currency.value = code;
                return;
              }
            }
            _loadGlobalDefault();
          });
    } else {
      _loadGlobalDefault();
    }
  }

  Future<void> _loadGlobalDefault() async {
    try {
      final doc = await _firestore.collection('settings').doc('app').get();
      if (doc.exists) {
        final raw = doc.data()?['currency'] as String? ?? 'USD (\$)';
        final code = _parseCode(raw);
        if (currency.value != code) currency.value = code;
      }
    } catch (_) {}
  }

  String _parseCode(String raw) {
    if (raw.contains('USD')) return 'USD';
    if (raw.contains('KHR')) return 'KHR';
    if (raw.contains('EUR')) return 'EUR';
    return 'USD';
  }

  Future<void> setCurrency(String raw) async {
    final code = _parseCode(raw);
    currency.value = code;
    if (_currentUid.isNotEmpty) {
      await _firestore.collection('users').doc(_currentUid).set({
        'currency': raw,
      }, SetOptions(merge: true));
    }
    await _firestore.collection('settings').doc('app').set({
      'currency': raw,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void onClose() {
    _userSub?.cancel();
    super.onClose();
  }

  String formatPrice(double usdAmount) {
    final converted = usdAmount * rate;
    switch (currency.value) {
      case 'KHR':
        if (converted >= 100000) {
          return (converted / 1000).toStringAsFixed(0) + 'K ' + symbol;
        }
        if (converted >= 10000) {
          return (converted / 1000).toStringAsFixed(1) + 'K ' + symbol;
        }
        return converted.toStringAsFixed(0) + ' ' + symbol;
      case 'EUR':
        return symbol + converted.toStringAsFixed(2);
      default:
        return symbol + converted.toStringAsFixed(2);
    }
  }

  String formatPriceCompact(double usdAmount) {
    final converted = usdAmount * rate;
    switch (currency.value) {
      case 'KHR':
        if (converted >= 100000)
          return (converted / 1000).toStringAsFixed(0) + 'K ' + symbol;
        if (converted >= 10000)
          return (converted / 1000).toStringAsFixed(1) + 'K ' + symbol;
        return converted.toStringAsFixed(0) + ' ' + symbol;
      case 'EUR':
        return symbol + converted.toStringAsFixed(2);
      default:
        return symbol + converted.toStringAsFixed(2);
    }
  }
}
