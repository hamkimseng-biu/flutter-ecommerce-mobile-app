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
    _loadFromStream();
  }

  void _loadFromStream() {
    isLoading.value = true;

    _firestoreService.getProductsStream().listen(
      (products) {
        if (products.isNotEmpty) {
          allProducts.value = products;
          filteredProducts.value = products;
          _categorizeProducts(products);
        }
        _loadSellers();
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );

    // Listen to categories from Firestore collection (admin-managed)
    _firestoreService.getCategoriesStream().listen((cats) {
      categories.value = [
        CategoryModel(id: 'all', name: 'All', icon: '🛍️'),
        ...cats.map(
          (c) => CategoryModel(
            id: (c['name'] as String).toLowerCase(),
            name: c['name'] as String,
            icon: (c['icon'] as String?) ?? '🛍️',
          ),
        ),
      ];
    });
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    final products = await _firestoreService.getProducts();
    if (products.isNotEmpty) {
      allProducts.value = products;
      filteredProducts.value = products;
      _categorizeProducts(products);
    }
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
            isPopular: d['isPopular'] ?? false,
          );
        }).toList();
        return;
      }
    } catch (_) {}
    sellers.value = MockDataService.getSellers();
  }

  /// Only sellers marked as popular by admin
  List<SellerModel> get popularSellers =>
      sellers.where((s) => s.isPopular).toList();

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
              .where(
                (p) =>
                    p.category.toLowerCase() ==
                    categories[index].name.toLowerCase(),
              )
              .toList();
  }

  /// Flash sale products filtered by selected category
  List<ProductModel> get filteredFlashSale {
    if (selectedCategoryIndex.value == 0) return flashSaleProducts;
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return flashSaleProducts
        .where((p) => p.category.toLowerCase() == cat)
        .toList();
  }

  /// Featured products filtered by selected category
  List<ProductModel> get filteredFeatured {
    if (selectedCategoryIndex.value == 0) return featuredProducts;
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return featuredProducts
        .where((p) => p.category.toLowerCase() == cat)
        .toList();
  }

  /// New arrivals filtered by selected category
  List<ProductModel> get filteredNewArrivals {
    if (selectedCategoryIndex.value == 0) return newArrivals;
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return newArrivals.where((p) => p.category.toLowerCase() == cat).toList();
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
