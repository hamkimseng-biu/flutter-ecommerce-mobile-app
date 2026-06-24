import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/review_model.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ═══════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════

  CollectionReference get _productsRef => _firestore.collection('products');

  // Get all products stream
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get all products once
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _productsRef.get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    final snapshot = await _productsRef
        .where('isFeatured', isEqualTo: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  // Get flash sale products
  Future<List<ProductModel>> getFlashSaleProducts() async {
    final snapshot = await _productsRef
        .where('isFlashSale', isEqualTo: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  // Get new arrivals (sorted by createdAt descending)
  Future<List<ProductModel>> getNewArrivals() async {
    final snapshot = await _productsRef
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  // Search products with filters
  Future<List<ProductModel>> searchProducts({
    String query = '',
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    var q = _productsRef as Query;
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    final snapshot = await q.get();
    var products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();

    // Client-side filters (Firestore doesn't support multiple range queries easily)
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }
    if (minPrice != null) {
      products = products.where((p) => p.effectivePrice >= minPrice).toList();
    }
    if (maxPrice != null) {
      products = products.where((p) => p.effectivePrice <= maxPrice).toList();
    }
    if (minRating != null) {
      products = products.where((p) => p.rating >= minRating).toList();
    }
    return products;
  }

  // Get all unique categories
  Future<List<String>> getCategories() async {
    final snapshot = await _productsRef.get();
    final cats = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = data['category'] as String?;
      if (cat != null && cat.isNotEmpty) cats.add(cat);
    }
    return cats.toList()..sort();
  }

  // ═══════════════════════════════════════════
  // CART
  // ═══════════════════════════════════════════

  CollectionReference get _cartRef =>
      _firestore.collection('users').doc(_uid).collection('cart');

  // Get cart items stream
  Stream<List<CartItemModel>> getCartStream() {
    if (_uid.isEmpty) return Stream.value([]);
    return _cartRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItemModel.fromFirestore(doc))
          .toList();
    });
  }

  // Add item to cart
  Future<void> addToCart(CartItemModel item) async {
    if (_uid.isEmpty) return;
    await _cartRef.doc(item.productId).set(item.toFirestore());
  }

  // Update cart item quantity
  Future<void> updateCartQuantity(String productId, int quantity) async {
    if (_uid.isEmpty) return;
    await _cartRef.doc(productId).update({'quantity': quantity});
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (_uid.isEmpty) return;
    await _cartRef.doc(productId).delete();
  }

  // Clear entire cart
  Future<void> clearCart() async {
    if (_uid.isEmpty) return;
    final batch = _firestore.batch();
    final snapshot = await _cartRef.get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════
  // WISHLIST
  // ═══════════════════════════════════════════

  CollectionReference get _wishlistRef =>
      _firestore.collection('users').doc(_uid).collection('wishlist');

  // Get wishlist stream
  Stream<List<String>> getWishlistStream() {
    if (_uid.isEmpty) return Stream.value([]);
    return _wishlistRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Get wishlist IDs once (for initial load)
  Future<List<String>> getWishlistIds() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _wishlistRef.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Add to wishlist
  Future<void> addToWishlist(String productId) async {
    if (_uid.isEmpty) return;
    await _wishlistRef.doc(productId).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String productId) async {
    if (_uid.isEmpty) return;
    await _wishlistRef.doc(productId).delete();
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    if (_uid.isEmpty) return false;
    final doc = await _wishlistRef.doc(productId).get();
    return doc.exists;
  }

  // ═══════════════════════════════════════════
  // ORDERS
  // ═══════════════════════════════════════════

  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(_uid).collection('orders');

  // Create an order from cart items
  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double shipping,
    required double discount,
    required double total,
    required String promoCode,
    required String paymentMethod,
  }) async {
    if (_uid.isEmpty) throw Exception('User not logged in');
    final docRef = await _ordersRef.add({
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'promoCode': promoCode,
      'paymentMethod': paymentMethod,
      'status': 'Processing',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _uid,
    });
    return docRef.id;
  }

  // Get all user orders
  Future<List<Map<String, dynamic>>> getOrders() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _ordersRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      return {
        'id': '#${doc.id.substring(0, 8).toUpperCase()}',
        'firestoreId': doc.id,
        'date': ts != null
            ? '${ts.toDate().day} ${_monthName(ts.toDate().month)} ${ts.toDate().year}'
            : 'Just now',
        'status': data['status'] ?? 'Processing',
        'items': List<Map<String, dynamic>>.from(data['items'] ?? []),
        'total': (data['total'] ?? 0).toDouble(),
        'subtotal': (data['subtotal'] ?? 0).toDouble(),
        'tax': (data['tax'] ?? 0).toDouble(),
        'shipping': (data['shipping'] ?? 0).toDouble(),
        'discount': (data['discount'] ?? 0).toDouble(),
      };
    }).toList();
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Stream<QuerySnapshot> getOrdersStream() {
    if (_uid.isEmpty) return Stream.empty();
    return _ordersRef.orderBy('createdAt', descending: true).snapshots();
  }

  // ═══════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════

  CollectionReference _reviewsRef(String productId) =>
      _firestore.collection('products').doc(productId).collection('reviews');

  // Add a review
  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
    required String userName,
    String userAvatar = '',
  }) async {
    if (_uid.isEmpty) throw Exception('User not logged in');
    final review = ReviewModel(
      id: '',
      productId: productId,
      userId: _uid,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await _reviewsRef(productId).add(review.toFirestore());

    // Update product average rating & review count
    final reviews = await _reviewsRef(productId).get();
    final totalRating = reviews.docs.fold<double>(
      0,
      (acc, doc) => acc + ((doc.data() as Map<String, dynamic>)['rating'] ?? 5),
    );
    final avgRating = reviews.docs.isEmpty
        ? rating
        : totalRating / reviews.docs.length;
    await _productsRef.doc(productId).update({
      'rating': double.parse(avgRating.toStringAsFixed(1)),
      'reviewCount': reviews.docs.length,
    });
  }

  // Get reviews stream for a product
  Stream<List<ReviewModel>> getReviewsStream(String productId) {
    return _reviewsRef(productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get reviews once
  Future<List<ReviewModel>> getReviews(String productId) async {
    final snapshot = await _reviewsRef(
      productId,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  // ═══════════════════════════════════════════
  // ADDRESSES
  // ═══════════════════════════════════════════

  CollectionReference get _addressesRef =>
      _firestore.collection('users').doc(_uid).collection('addresses');

  Future<List<Map<String, dynamic>>> getAddresses() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _addressesRef.get();
    return snapshot.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return {
        'firestoreId': doc.id,
        'recipient': d['recipient'] ?? '',
        'phone': d['phone'] ?? '',
        'label': d['label'] ?? 'Address',
        'street': d['street'] ?? '',
        'city': d['city'] ?? '',
        'province': d['province'] ?? '',
        'zip': d['zip'] ?? '',
        'isDefault': d['isDefault'] ?? false,
      };
    }).toList();
  }

  Future<void> saveAddress(
    Map<String, dynamic> address, {
    String? docId,
  }) async {
    if (_uid.isEmpty) return;
    final data = {
      'recipient': address['recipient'],
      'phone': address['phone'],
      'label': address['label'],
      'street': address['street'],
      'city': address['city'],
      'province': address['province'],
      'zip': address['zip'],
      'isDefault': address['isDefault'],
    };
    if (docId != null) {
      await _addressesRef.doc(docId).update(data);
    } else {
      await _addressesRef.add(data);
    }
  }

  Future<void> deleteAddress(String docId) async {
    if (_uid.isEmpty) return;
    await _addressesRef.doc(docId).delete();
  }

  // ═══════════════════════════════════════════
  // RECENTLY VIEWED
  // ═══════════════════════════════════════════

  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);

  Future<void> addRecentlyViewed(String productId) async {
    if (_uid.isEmpty) return;
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final list = List<String>.from(data['recentlyViewed'] ?? []);
    list.remove(productId);
    list.insert(0, productId);
    if (list.length > 20) list.removeRange(20, list.length);
    await _userDoc.update({'recentlyViewed': list});
  }

  Future<List<String>> getRecentlyViewed() async {
    if (_uid.isEmpty) return [];
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return List<String>.from(data['recentlyViewed'] ?? []);
  }

  // ═══════════════════════════════════════════
  // PAYMENT METHODS
  // ═══════════════════════════════════════════

  CollectionReference get _cardsRef =>
      _firestore.collection('users').doc(_uid).collection('cards');

  Future<List<Map<String, dynamic>>> getCards() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _cardsRef.get();
    return snapshot.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return {
        'firestoreId': doc.id,
        'number': d['number'] ?? '',
        'holder': d['holder'] ?? '',
        'expiry': d['expiry'] ?? '',
        'brand': d['brand'] ?? 'visa',
        'isDefault': d['isDefault'] ?? false,
      };
    }).toList();
  }

  Future<void> saveCard(Map<String, dynamic> card, {String? docId}) async {
    if (_uid.isEmpty) return;
    final data = {
      'number': card['number'],
      'holder': card['holder'],
      'expiry': card['expiry'],
      'brand': card['brand'] ?? 'visa',
      'isDefault': card['isDefault'] ?? false,
    };
    if (docId != null) {
      await _cardsRef.doc(docId).update(data);
    } else {
      await _cardsRef.add(data);
    }
  }

  Future<void> deleteCard(String docId) async {
    if (_uid.isEmpty) return;
    await _cardsRef.doc(docId).delete();
  }

  // ═══════════════════════════════════════════
  // BANK ACCOUNTS
  // ═══════════════════════════════════════════

  CollectionReference get _bankRef =>
      _firestore.collection('users').doc(_uid).collection('bank_accounts');

  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    if (_uid.isEmpty) return [];
    final snapshot = await _bankRef.get();
    return snapshot.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return {
        'firestoreId': doc.id,
        'bankName': d['bankName'] ?? '',
        'accountHolder': d['accountHolder'] ?? '',
        'accountNumber': d['accountNumber'] ?? '',
        'routingNumber': d['routingNumber'] ?? '',
        'accountType': d['accountType'] ?? 'checking',
        'isDefault': d['isDefault'] ?? false,
      };
    }).toList();
  }

  Future<void> saveBankAccount(
    Map<String, dynamic> bank, {
    String? docId,
  }) async {
    if (_uid.isEmpty) return;
    final data = {
      'bankName': bank['bankName'],
      'accountHolder': bank['accountHolder'],
      'accountNumber': bank['accountNumber'],
      'routingNumber': bank['routingNumber'] ?? '',
      'accountType': bank['accountType'] ?? 'checking',
      'isDefault': bank['isDefault'] ?? false,
    };
    if (docId != null) {
      await _bankRef.doc(docId).update(data);
    } else {
      await _bankRef.add(data);
    }
  }

  Future<void> deleteBankAccount(String docId) async {
    if (_uid.isEmpty) return;
    await _bankRef.doc(docId).delete();
  }

  // ═══════════════════════════════════════════
  // ORDER ACTIONS
  // ═══════════════════════════════════════════

  Future<void> cancelOrder(String orderId) async {
    if (_uid.isEmpty) return;
    await _ordersRef.doc(orderId).update({'status': 'Cancelled'});
  }

  // ═══════════════════════════════════════════
  // ADMIN — orders across all users
  // ═══════════════════════════════════════════

  /// Fetches all orders from all users via collection group query.
  Stream<QuerySnapshot> getAllOrdersStream() {
    return _firestore
        .collectionGroup('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Updates an order's status (admin only).
  /// Requires both [userId] and [orderId] since orders are nested.
  Future<void> adminUpdateOrderStatus({
    required String userId,
    required String orderId,
    required String newStatus,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    // Optionally save a notification for the user
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'Order ${newStatus}',
            'body': 'Your order status has been updated to "$newStatus".',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  /// Gets a user document for admin purposes (e.g., resolving user names)
  Future<Map<String, dynamic>?> getUserDoc(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════
  // PROMO CODES
  // ═══════════════════════════════════════════

  /// Validates a promo code and returns discount info, or null if invalid.
  /// Returns: { 'code': ..., 'discountPercent': ..., 'description': ... }
  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    if (code.trim().isEmpty) return null;
    final snapshot = await _firestore
        .collection('promo_codes')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    // Check expiry
    final expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
      return null; // expired
    }
    // Check usage limit
    final maxUses = data['maxUses'] as int? ?? 999;
    final usedCount = data['usedCount'] as int? ?? 0;
    if (usedCount >= maxUses) return null;

    return {
      'code': data['code'] ?? code,
      'discountPercent': (data['discountPercent'] ?? 10).toDouble(),
      'description': data['description'] ?? '',
    };
  }

  /// Increments the usage count for a promo code
  Future<void> incrementPromoUsage(String code) async {
    final snapshot = await _firestore
        .collection('promo_codes')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'usedCount': FieldValue.increment(1),
      });
    }
  }
}
