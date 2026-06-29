import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/seller_model.dart';
import '../services/mock_data_service.dart';
import '../services/firebase_firestore_service.dart';

enum SortOption {
  featured,
  priceAsc,
  priceDesc,
  ratingDesc,
  ratingAsc,
  newestFirst,
  oldestFirst,
}

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

  // Sorting
  final Rx<SortOption> sortOption = SortOption.featured.obs;
  final RxBool isSorting = false.obs;

  /// Returns the display direction arrow for the current sort.
  String get sortPriceArrow =>
      sortOption.value == SortOption.priceAsc ? '↑' : '↓';
  String get sortRatingArrow =>
      sortOption.value == SortOption.ratingAsc ? '↑' : '↓';
  String get sortNewestArrow =>
      sortOption.value == SortOption.oldestFirst ? '↑' : '↓';

  void setSort(SortOption opt) {
    sortOption.value = opt;
    _triggerSortRefresh();
  }

  void _triggerSortRefresh() {
    isSorting.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      isSorting.value = false;
    });
  }

  List<ProductModel> _applySort(List<ProductModel> list) {
    switch (sortOption.value) {
      case SortOption.priceAsc:
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      case SortOption.priceDesc:
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
      case SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.ratingAsc:
        list.sort((a, b) => a.rating.compareTo(b.rating));
      case SortOption.newestFirst:
        list = list.reversed.toList();
      case SortOption.oldestFirst:
        // keep original order
        break;
      case SortOption.featured:
        break;
    }
    return list;
  }

  /// Returns related products (same category if possible, else popular).
  List<ProductModel> getRelatedProducts(String productId, {String? category}) {
    final cat = (category ?? '').toLowerCase();

    List<ProductModel> related;
    if (cat.isNotEmpty) {
      related = allProducts
          .where((p) => p.id != productId && p.category.toLowerCase() == cat)
          .toList();
    } else {
      related = [];
    }

    // Fallback: use featured or top-selling products
    if (related.length < 3) {
      related = allProducts.where((p) => p.id != productId).toList();
    }

    related.shuffle();
    return related.take(6).toList();
  }

  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _catsSub;
  StreamSubscription<QuerySnapshot>? _sellersSub;

  @override
  void onInit() {
    super.onInit();
    _loadSellers();
    _loadFromStream();
  }

  @override
  void onClose() {
    _productsSub?.cancel();
    _catsSub?.cancel();
    _sellersSub?.cancel();
    super.onClose();
  }

  void _loadFromStream() {
    isLoading.value = true;

    _productsSub = _firestoreService.getProductsStream().listen(
      (products) {
        if (products.isNotEmpty) {
          allProducts.value = products;
          _categorizeProducts(products);
          _applyCategoryFilter();
        }
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );

    _catsSub = _firestoreService.getCategoriesStream().listen((cats) {
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
      _categorizeProducts(products);
      _applyCategoryFilter();
    }
    _loadSellers();
    isLoading.value = false;
  }

  void _applyCategoryFilter() {
    final idx = selectedCategoryIndex.value;
    if (idx > 0 && idx >= categories.length) return;
    selectCategory(idx);
  }

  void _loadSellers() {
    _sellersSub?.cancel();
    _sellersSub = FirebaseFirestore.instance
        .collection('shops')
        .snapshots()
        .listen((snap) {
          if (snap.docs.isEmpty) {
            sellers.value = MockDataService.getSellers();
            return;
          }
          sellers.value = snap.docs.map((doc) {
            final d = doc.data();
            final raw = (d['followerCount'] ?? 0) as int;
            // Auto-fix any negative followerCount persisted in Firestore
            if (raw < 0) {
              doc.reference.update({'followerCount': 0});
            }
            return SellerModel(
              id: doc.id,
              name: d['name'] ?? 'Shop',
              avatar: d['logoUrl'] ?? d['avatar'] ?? '🏪',
              logoUrl: d['logoUrl'] ?? '',
              banner: d['bannerUrl'] ?? '',
              description: d['description'] ?? '',
              rating: (d['rating'] ?? 0.0).toDouble(),
              productCount: 0,
              followerCount: raw.clamp(0, 999999999),
              isOfficial: d['isOfficial'] ?? false,
              isPopular: d['isPopular'] ?? false,
            );
          }).toList();
        });
  }

  /// Only sellers marked as popular by admin
  List<SellerModel> get popularSellers =>
      sellers.where((s) => s.isPopular).toList();

  void _categorizeProducts(List<ProductModel> products) {
    featuredProducts.value = products.where((p) => p.isFeatured).toList();
    flashSaleProducts.value = products
        .where((p) => p.isFlashSaleActive)
        .toList();
    // New arrivals: sort by index (or use a createdAt field in Firestore)
    newArrivals.value = products.take(10).toList();
    trendingProducts.value = products.where((p) => p.soldCount > 50).toList();
    if (trendingProducts.isEmpty) {
      trendingProducts.value = products.take(8).toList();
    }
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
    if (selectedCategoryIndex.value == 0)
      return _applySort(flashSaleProducts.toList());
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return _applySort(
      flashSaleProducts.where((p) => p.category.toLowerCase() == cat).toList(),
    );
  }

  /// Featured products filtered by selected category
  List<ProductModel> get filteredFeatured {
    if (selectedCategoryIndex.value == 0)
      return _applySort(featuredProducts.toList());
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return _applySort(
      featuredProducts.where((p) => p.category.toLowerCase() == cat).toList(),
    );
  }

  /// New arrivals filtered by selected category
  List<ProductModel> get filteredNewArrivals {
    if (selectedCategoryIndex.value == 0)
      return _applySort(newArrivals.toList());
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return _applySort(
      newArrivals.where((p) => p.category.toLowerCase() == cat).toList(),
    );
  }

  /// Trending filtered by selected category
  List<ProductModel> get filteredTrending {
    if (selectedCategoryIndex.value == 0)
      return _applySort(trendingProducts.toList());
    final cat = categories[selectedCategoryIndex.value].name.toLowerCase();
    return _applySort(
      trendingProducts.where((p) => p.category.toLowerCase() == cat).toList(),
    );
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

  /// Reactive product count for a seller.
  /// Use in Obx to auto-update when products change.
  int getSellerProductCount(String sellerId) =>
      allProducts.where((p) => p.sellerId == sellerId).length;
}
