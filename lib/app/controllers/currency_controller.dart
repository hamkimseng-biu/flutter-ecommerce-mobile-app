import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _listenCurrency();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _listenCurrency() {
    _sub?.cancel();
    _sub = _firestore.collection('settings').doc('app').snapshots().listen((
      doc,
    ) {
      if (doc.exists) {
        final data = doc.data()!;
        final raw = data['currency'] as String? ?? 'USD (\$)';
        final code = raw.contains('USD')
            ? 'USD'
            : raw.contains('KHR')
            ? 'KHR'
            : raw.contains('EUR')
            ? 'EUR'
            : 'USD';
        if (currency.value != code) currency.value = code;
      }
    });
    // Initial one-shot fetch to ensure latest value on startup
    _firestore.collection('settings').doc('app').get().then((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final raw = data['currency'] as String? ?? 'USD (\$)';
        final code = raw.contains('USD')
            ? 'USD'
            : raw.contains('KHR')
            ? 'KHR'
            : raw.contains('EUR')
            ? 'EUR'
            : 'USD';
        currency.value = code;
      }
    });
  }

  /// Uses abbreviated format for KHR to avoid overflow (e.g., "82K" instead of "81,959").
  String formatPrice(double usdAmount) {
    final converted = usdAmount * rate;
    switch (currency.value) {
      case 'KHR':
        // Abbreviate: 81959 → "82K ៛" to prevent overflow
        if (converted >= 100000) {
          return '${(converted / 1000).toStringAsFixed(0)}K $symbol';
        }
        if (converted >= 10000) {
          return '${(converted / 1000).toStringAsFixed(1)}K $symbol';
        }
        return '${converted.toStringAsFixed(0)} $symbol';
      case 'EUR':
        return '$symbol${converted.toStringAsFixed(2)}';
      default:
        return '\$${converted.toStringAsFixed(2)}';
    }
  }

  /// Short format for tight spaces (product cards).
  /// Drops decimals for KHR, keeps 2 decimals for USD/EUR.
  String formatPriceCompact(double usdAmount) {
    final converted = usdAmount * rate;
    switch (currency.value) {
      case 'KHR':
        if (converted >= 100000) {
          return '${(converted / 1000).toStringAsFixed(0)}K ៛';
        }
        if (converted >= 1000) {
          return '${(converted / 1000).toStringAsFixed(1)}K ៛';
        }
        return '${converted.toInt()} ៛';
      case 'EUR':
        return '€${converted.toStringAsFixed(2)}';
      default:
        return '\$${converted.toStringAsFixed(2)}';
    }
  }

  /// Plain numeric string (no symbol) for use where symbol is separate
  String formatPriceValue(double usdAmount) {
    final converted = usdAmount * rate;
    switch (currency.value) {
      case 'KHR':
        if (converted >= 100000) {
          return '${(converted / 1000).toStringAsFixed(0)}K';
        }
        if (converted >= 1000) {
          return '${(converted / 1000).toStringAsFixed(1)}K';
        }
        return converted.toStringAsFixed(0);
      case 'EUR':
        return converted.toStringAsFixed(2);
      default:
        return converted.toStringAsFixed(2);
    }
  }
}
