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
    );
  }
}
