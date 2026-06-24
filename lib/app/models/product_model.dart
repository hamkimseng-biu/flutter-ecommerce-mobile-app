import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final List<String> images;
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> sizes;
  final List<String> colors;
  final bool isFavorite;
  final int stock;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final int soldCount;
  final bool isFlashSale;
  final double flashSalePrice;
  final DateTime? saleEndsAt;
  final bool isFeatured;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.images,
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.sizes = const ['S', 'M', 'L', 'XL'],
    this.colors = const [],
    this.isFavorite = false,
    this.stock = 10,
    this.sellerId = '',
    this.sellerName = 'Tiny Chicken Official',
    this.sellerAvatar = '',
    this.soldCount = 0,
    this.isFlashSale = false,
    this.flashSalePrice = 0.0,
    this.saleEndsAt,
    this.isFeatured = false,
  });

  double get effectivePrice =>
      isFlashSale && flashSalePrice > 0 ? flashSalePrice : price;

  double get discountPercent => originalPrice > 0
      ? ((originalPrice - effectivePrice) / originalPrice * 100).roundToDouble()
      : 0;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    List<String>? images,
    String? category,
    double? rating,
    int? reviewCount,
    List<String>? sizes,
    List<String>? colors,
    bool? isFavorite,
    int? stock,
    String? sellerId,
    String? sellerName,
    String? sellerAvatar,
    int? soldCount,
    bool? isFlashSale,
    double? flashSalePrice,
    DateTime? saleEndsAt,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      images: images ?? this.images,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      isFavorite: isFavorite ?? this.isFavorite,
      stock: stock ?? this.stock,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      soldCount: soldCount ?? this.soldCount,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSalePrice: flashSalePrice ?? this.flashSalePrice,
      saleEndsAt: saleEndsAt ?? this.saleEndsAt,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // ── Firestore ──

  factory ProductModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      sizes: List<String>.from(data['sizes'] ?? ['S', 'M', 'L', 'XL']),
      colors: List<String>.from(data['colors'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
      stock: data['stock'] ?? 10,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Tiny Chicken Official',
      sellerAvatar: data['sellerAvatar'] ?? '',
      soldCount: data['soldCount'] ?? 0,
      isFlashSale: data['isFlashSale'] ?? false,
      flashSalePrice: (data['flashSalePrice'] ?? 0).toDouble(),
      saleEndsAt: (data['saleEndsAt'] as Timestamp?)?.toDate(),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'sizes': sizes,
      'colors': colors,
      'isFavorite': isFavorite,
      'stock': stock,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'soldCount': soldCount,
      'isFlashSale': isFlashSale,
      'flashSalePrice': flashSalePrice,
      'saleEndsAt': saleEndsAt != null ? Timestamp.fromDate(saleEndsAt!) : null,
      'isFeatured': isFeatured,
    };
  }
}
