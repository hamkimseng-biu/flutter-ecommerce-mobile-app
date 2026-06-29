import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String productId;
  final String name;
  final String image;
  final double price;
  int quantity;
  String selectedSize;
  String selectedColor;
  String sellerId;
  String sellerName;
  bool freeShipping;
  Map<String, String> selectedVariants;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
    this.selectedSize = 'M',
    this.selectedColor = '',
    this.sellerId = '',
    this.sellerName = '',
    this.freeShipping = false,
    this.selectedVariants = const {},
  });

  double get totalPrice => price * quantity;

  /// Unified variant display: size · color · custom variants
  String get variantDisplay {
    final parts = <String>[];
    if (selectedSize.isNotEmpty) parts.add(selectedSize);
    if (selectedColor.isNotEmpty) parts.add(selectedColor);
    for (final e in selectedVariants.entries) {
      parts.add('${e.key}: ${e.value}');
    }
    return parts.join(' · ');
  }

  // ── Firestore ──

  factory CartItemModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CartItemModel(
      productId: data['productId'] as String? ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      selectedSize: data['selectedSize'] ?? 'M',
      selectedColor: data['selectedColor'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      freeShipping: data['freeShipping'] ?? false,
      selectedVariants: data['selectedVariants'] is Map
          ? Map<String, String>.from(data['selectedVariants'])
          : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'freeShipping': freeShipping,
      'selectedVariants': selectedVariants,
    };
  }
}
