import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final List<String> images;
  final List<String> detailImages;
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> sizes;
  final List<String> colors;
  final List<String> materials;

  /// Admin-defined custom variant types. e.g. {'Style': ['Modern','Classic'], 'Weight': ['1kg','2kg']}
  final Map<String, List<String>> customVariants;
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
  // Admin-editable discount percent (0-100).  System auto-calculates prices.
  final double discountPercent;
  // Toggle badge visibility
  final bool showSoldCount;
  final bool showRating;
  final bool showReviewCount;
  // Free shipping
  final bool freeShipping;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.images,
    this.detailImages = const [],
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.sizes = const ['S', 'M', 'L', 'XL'],
    this.colors = const [],
    this.materials = const [],
    this.customVariants = const {},
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
    this.discountPercent = 0.0,
    this.showSoldCount = true,
    this.showRating = true,
    this.showReviewCount = true,
    this.freeShipping = false,
  });

  double get effectivePrice =>
      isFlashSale && flashSalePrice > 0 ? flashSalePrice : price;

  double get discountPercentDisplay => originalPrice > 0
      ? ((originalPrice - effectivePrice) / originalPrice * 100).roundToDouble()
      : discountPercent;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    List<String>? images,
    List<String>? detailImages,
    String? category,
    double? rating,
    int? reviewCount,
    List<String>? sizes,
    List<String>? colors,
    List<String>? materials,
    Map<String, List<String>>? customVariants,
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
    double? discountPercent,
    bool? showSoldCount,
    bool? showRating,
    bool? showReviewCount,
    bool? freeShipping,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      images: images ?? this.images,
      detailImages: detailImages ?? this.detailImages,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      materials: materials ?? this.materials,
      customVariants: customVariants ?? this.customVariants,
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
      discountPercent: discountPercent ?? this.discountPercent,
      showSoldCount: showSoldCount ?? this.showSoldCount,
      showRating: showRating ?? this.showRating,
      showReviewCount: showReviewCount ?? this.showReviewCount,
      freeShipping: freeShipping ?? this.freeShipping,
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
      detailImages: List<String>.from(data['detailImages'] ?? []),
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      sizes: List<String>.from(data['sizes'] ?? ['S', 'M', 'L', 'XL']),
      colors: List<String>.from(data['colors'] ?? []),
      materials: List<String>.from(data['materials'] ?? []),
      customVariants: _parseVariants(data['customVariants']),
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
      discountPercent: (data['discountPercent'] ?? 0).toDouble(),
      showSoldCount: data['showSoldCount'] ?? true,
      showRating: data['showRating'] ?? true,
      showReviewCount: data['showReviewCount'] ?? true,
      freeShipping: data['freeShipping'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'detailImages': detailImages,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'sizes': sizes,
      'colors': colors,
      'materials': materials,
      'customVariants': customVariants.map((k, v) => MapEntry(k, v)),
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
      'discountPercent': discountPercent,
      'showSoldCount': showSoldCount,
      'showRating': showRating,
      'showReviewCount': showReviewCount,
      'freeShipping': freeShipping,
    };
  }

  static Map<String, List<String>> _parseVariants(dynamic data) {
    if (data == null) return {};
    final map = Map<String, dynamic>.from(data as Map);
    return map.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }
}
