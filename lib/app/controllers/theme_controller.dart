import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadPreference();
    // Reload preference when user logs in/out
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _loadPreference();
    });
  }

  Future<void> _loadPreference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isDarkMode.value = false;
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final dark = doc.data()?['darkMode'] as bool? ?? false;
      isDarkMode.value = dark;
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    // Persist to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set({
        'darkMode': isDarkMode.value,
      }, SetOptions(merge: true));
    }
  }
}
