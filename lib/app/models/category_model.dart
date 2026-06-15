class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl = '',
  });
}
