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
}
