import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/seller_model.dart';
import '../services/mock_data_service.dart';

class ProductController extends GetxController {
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

  void loadProducts() {
    isLoading.value = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      allProducts.value = MockDataService.getProducts();
      filteredProducts.value = allProducts;
      categories.value = MockDataService.getCategories();
      featuredProducts.value = MockDataService.getFeaturedProducts();
      newArrivals.value = MockDataService.getNewArrivals();
      trendingProducts.value = MockDataService.getTrendingProducts();
      flashSaleProducts.value = MockDataService.getFlashSaleProducts();
      sellers.value = MockDataService.getSellers();
      isLoading.value = false;
    });
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
