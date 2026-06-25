class SellerModel {
  final String id;
  final String name;
  final String avatar;
  final String logoUrl;
  final String banner;
  final String description;
  final double rating;
  final int productCount;
  final int followerCount;
  final bool isOfficial;
  final bool isPopular;
  final List<String> categoryIds;

  SellerModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.logoUrl = '',
    this.banner = '',
    this.description = '',
    this.rating = 0.0,
    this.productCount = 0,
    this.followerCount = 0,
    this.isOfficial = false,
    this.isPopular = false,
    this.categoryIds = const [],
  });
}
