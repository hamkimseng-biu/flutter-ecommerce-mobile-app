import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String productId;
  final String name;
  final String image;
  final double price;
  int quantity;
  String selectedSize;
  String selectedColor;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
    this.selectedSize = 'M',
    this.selectedColor = '',
  });

  double get totalPrice => price * quantity;

  // ── Firestore ──

  factory CartItemModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CartItemModel(
      productId: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      selectedSize: data['selectedSize'] ?? 'M',
      selectedColor: data['selectedColor'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
    };
  }
}
