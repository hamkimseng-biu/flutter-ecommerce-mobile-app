import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/seller_model.dart';
import '../services/mock_data_service.dart';
import '../services/firebase_firestore_service.dart';

class ProductController extends GetxController {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> newArrivals = <ProductModel>[].obs;
  final RxList<ProductModel> trendingProducts = <ProductModel>[].obs;
  final RxList<ProductModel> flashSaleProducts = <ProductModel>[].obs;
  final RxList<SellerModel> sellers = <SellerModel>[].obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;

    try {
      // Try to load from Firestore first
      final products = await _firestoreService.getProducts();

      if (products.isNotEmpty) {
        allProducts.value = products;
        filteredProducts.value = products;
        _categorizeProducts(products);
        _loadCategoriesFromProducts(products);
      } else {
        // Fallback to mock data
        _loadMockData();
      }
    } catch (e) {
      // Fallback to mock data on error
      _loadMockData();
    }

    // Load sellers from Firestore shops collection
    _loadSellers();

    isLoading.value = false;
  }

  Future<void> _loadSellers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('shops').get();
      if (snap.docs.isNotEmpty) {
        sellers.value = snap.docs.map((doc) {
          final d = doc.data();
          return SellerModel(
            id: doc.id,
            name: d['name'] ?? 'Shop',
            avatar: d['avatar'] ?? '🏪',
            logoUrl: d['logoUrl'] ?? '',
            banner: d['bannerUrl'] ?? '',
            description: d['description'] ?? '',
            isOfficial: d['isOfficial'] ?? false,
          );
        }).toList();
        return;
      }
    } catch (_) {}
    sellers.value = MockDataService.getSellers();
  }

  void _categorizeProducts(List<ProductModel> products) {
    featuredProducts.value = products.where((p) => p.isFeatured).toList();
    flashSaleProducts.value = products.where((p) => p.isFlashSale).toList();
    // New arrivals: sort by index (or use a createdAt field in Firestore)
    newArrivals.value = products.take(10).toList();
    trendingProducts.value = products.where((p) => p.soldCount > 50).toList();
    if (trendingProducts.isEmpty) {
      trendingProducts.value = products.take(8).toList();
    }
  }

  void _loadCategoriesFromProducts(List<ProductModel> products) {
    final catNames = products.map((p) => p.category).toSet().toList();
    if (catNames.isNotEmpty) {
      categories.value = [
        CategoryModel(id: 'all', name: 'All', icon: '🛍️'),
        ...catNames.map(
          (name) => CategoryModel(
            id: name.toLowerCase(),
            name: name,
            icon: _categoryIcon(name),
          ),
        ),
      ];
    }
  }

  String _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'clothing':
      case 'fashion':
        return '👕';
      case 'electronics':
      case 'tech':
        return '📱';
      case 'home':
      case 'living':
        return '🏠';
      case 'beauty':
        return '✨';
      case 'sports':
        return '⚽';
      case 'shoes':
        return '👟';
      case 'accessories':
        return '👜';
      default:
        return '🛍️';
    }
  }

  void _loadMockData() {
    allProducts.value = MockDataService.getProducts();
    filteredProducts.value = allProducts;
    categories.value = MockDataService.getCategories();
    featuredProducts.value = MockDataService.getFeaturedProducts();
    newArrivals.value = MockDataService.getNewArrivals();
    trendingProducts.value = MockDataService.getTrendingProducts();
    flashSaleProducts.value = MockDataService.getFlashSaleProducts();
  }

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
    filteredProducts.value = index == 0
        ? allProducts
        : allProducts
              .where((p) => p.category == categories[index].name)
              .toList();
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    filteredProducts.value = query.isEmpty
        ? allProducts
        : allProducts
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query.toLowerCase()) ||
                    p.category.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> getProductsBySeller(String sellerId) =>
      allProducts.where((p) => p.sellerId == sellerId).toList();
  SellerModel? getSellerById(String id) {
    try {
      return sellers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
