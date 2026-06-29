import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/product_model.dart';
import '../../../models/review_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/wishlist_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/currency_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../services/time_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../routes/app_routes.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    // Accept ProductModel, String id, or Map
    final String productId;
    if (arg is ProductModel) {
      productId = arg.id;
    } else if (arg is String) {
      productId = arg;
    } else if (arg is Map) {
      productId = (arg['id'] ?? arg['productId'] ?? '').toString();
    } else {
      return const Scaffold(body: Center(child: Text('Invalid product')));
    }

    // Pre-selections passed from cart (Map format)
    final String preSelSize = arg is Map
        ? (arg['selSize'] as String?) ?? ''
        : '';
    final String preSelColor = arg is Map
        ? (arg['selColor'] as String?) ?? ''
        : '';
    final Map<String, String> preSelVariants = arg is Map
        ? Map<String, String>.from(arg['selVariants'] ?? {})
        : {};

    // Track recently viewed
    final firestoreService = FirebaseFirestoreService();
    Future.microtask(() => firestoreService.addRecentlyViewed(productId));
    final pc = Get.find<ProductController>();
    final cc = Get.find<CartController>();
    final wc = Get.find<WishlistController>();
    final curCtrl = Get.find<CurrencyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;
    final surface2 = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5);

    // Look up product reactively
    return Obx(() {
      final product = pc.getProductById(productId);
      if (product == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Product')),
          body: const Center(child: Text('Product not found')),
        );
      }

      final RxString selSize =
          (preSelSize.isNotEmpty && product.sizes.contains(preSelSize)
                  ? preSelSize
                  : (product.sizes.isNotEmpty ? product.sizes[0] : 'M'))
              .obs;
      final RxString selColor =
          (preSelColor.isNotEmpty && product.colors.contains(preSelColor)
                  ? preSelColor
                  : (product.colors.isNotEmpty ? product.colors[0] : ''))
              .obs;
      final RxString selMaterial =
          (product.materials.isNotEmpty ? product.materials[0] : '').obs;
      // Reactive selections for custom variant types
      final Map<String, String> customVariantMap = {};
      for (final e in product.customVariants.entries) {
        if (e.value.isNotEmpty) {
          customVariantMap[e.key] = preSelVariants[e.key] ?? e.value.first;
        }
      }
      final customVariantSelections = customVariantMap.map(
        (k, v) => MapEntry(k, v.obs),
      );
      final RxInt qty = 1.obs;

      // Get seller for navigation
      final seller = pc.getSellerById(product.sellerId);

      Widget sellerIcon() {
        final logoUrl = seller?.logoUrl;
        if (logoUrl != null &&
            logoUrl.isNotEmpty &&
            logoUrl.startsWith('http')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              logoUrl,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                seller?.avatar ?? product.sellerAvatar,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        final emoji = seller?.avatar.isNotEmpty == true
            ? seller!.avatar
            : product.sellerAvatar;
        return Text(emoji, style: const TextStyle(fontSize: 16));
      }

      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Full-width image slideshow
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.50,
                          width: double.infinity,
                          child: _ImageSlideshow(
                            images: product.images,
                            productId: product.id,
                            surfaceColor: surface2,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Seller chip → navigates to shop
                              GestureDetector(
                                onTap: () {
                                  Get.toNamed(
                                    AppRoutes.shop,
                                    arguments: product.sellerId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      sellerIcon(),
                                      const SizedBox(width: 6),
                                      Text(
                                        seller?.name ?? product.sellerName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.secondaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.rating}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${product.reviewCount} reviews) · ${product.soldCount} sold',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Obx(
                                    () => Text(
                                      curCtrl.formatPrice(
                                        product.effectivePrice,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  if (product.isFlashSaleActive) ...[
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Obx(
                                        () => Text(
                                          curCtrl.formatPrice(product.price),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF9E9EAA),
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.bolt,
                                              size: 12,
                                              color: AppTheme.errorColor,
                                            ),
                                            Text(
                                              product.flashDiscountPercent > 0
                                                  ? 'FLASH -${product.flashDiscountPercent.round()}%'
                                                  : 'FLASH',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.errorColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!product.isFlashSaleActive &&
                                      product.discountPercentDisplay > 3) ...[
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Obx(
                                        () => Text(
                                          curCtrl.formatPrice(product.price),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF9E9EAA),
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '-${product.discountPercentDisplay.round()}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB8860B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Flash countdown timer
                              if (product.isFlashSaleActive &&
                                  product.saleEndsAt != null) ...[
                                _FlashCountdown(endTime: product.saleEndsAt!),
                                const SizedBox(height: 16),
                              ],
                              Divider(
                                height: 1,
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE0E0E0),
                              ),
                              if (product.colors.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Color',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : const Color(0xFF9E9EAA),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => Wrap(
                                    spacing: 10,
                                    children: product.colors.map((c) {
                                      final a = selColor.value == c;
                                      return GestureDetector(
                                        onTap: () => selColor.value = c,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: a
                                                ? AppTheme.primaryColor
                                                      .withValues(alpha: 0.1)
                                                : surface2,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            c,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (product.sizes.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Size',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : const Color(0xFF9E9EAA),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => Wrap(
                                    spacing: 10,
                                    children: product.sizes.map((s) {
                                      final a = selSize.value == s;
                                      return GestureDetector(
                                        onTap: () => selSize.value = s,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: a
                                                ? AppTheme.primaryColor
                                                      .withValues(alpha: 0.1)
                                                : surface2,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              // ── Materials ──
                              if (product.materials.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Material',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : const Color(0xFF9E9EAA),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => Wrap(
                                    spacing: 10,
                                    children: product.materials.map((m) {
                                      final a = selMaterial.value == m;
                                      return GestureDetector(
                                        onTap: () => selMaterial.value = m,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: a
                                                ? AppTheme.primaryColor
                                                      .withValues(alpha: 0.1)
                                                : surface2,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            m,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: a
                                                  ? AppTheme.primaryColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              // ── Custom Variants ──
                              ...product.customVariants.entries.map((entry) {
                                final variantName = entry.key;
                                final variantValues = entry.value;
                                if (variantValues.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final selRx =
                                    customVariantSelections[variantName]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      variantName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : const Color(0xFF9E9EAA),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Obx(
                                      () => Wrap(
                                        spacing: 10,
                                        children: variantValues.map((v) {
                                          final a = selRx.value == v;
                                          return GestureDetector(
                                            onTap: () => selRx.value = v,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: a
                                                    ? AppTheme.primaryColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                    : surface2,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: a
                                                      ? AppTheme.primaryColor
                                                      : Colors.transparent,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                v,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: a
                                                      ? AppTheme.primaryColor
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 20),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE0E0E0),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  height: 1.65,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    product.stock > 0
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: product.stock > 0
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    product.stock > 0
                                        ? 'In Stock (${product.stock} available)'
                                        : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: product.stock > 0
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (product.freeShipping) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_shipping_outlined,
                                        size: 16,
                                        color: AppTheme.successColor,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Free Shipping',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              // ═══ REVIEWS SECTION ═══
                              _ReviewsSection(product: product),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      // ═══ RELATED PRODUCTS (full-width) ═══
                      SliverToBoxAdapter(
                        child: _RelatedProductsSection(
                          product: product,
                          pc: pc,
                          cc: cc,
                          isDark: isDark,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      // ═══ PRODUCT IMAGES GALLERY (edge-to-edge) ═══
                      if (product.detailImages.isNotEmpty ||
                          product.images.length > 1)
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Product Images',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${product.detailImages.length + product.images.length} photos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Main images first
                              ...product.images.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              // Detail images after
                              ...product.detailImages.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE0E0E0),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: surface2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (qty.value > 1) qty.value--;
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.remove_rounded, size: 20),
                                ),
                              ),
                              Obx(
                                () => SizedBox(
                                  width: 28,
                                  child: Center(
                                    child: Text(
                                      '${qty.value}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => qty.value++,
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: product.stock > 0
                                ? () {
                                    final variants = <String, String>{};
                                    for (final e
                                        in customVariantSelections.entries) {
                                      variants[e.key] = e.value.value;
                                    }
                                    cc.addToCart(
                                      product,
                                      size: selSize.value,
                                      color: selColor.value,
                                      quantity: qty.value,
                                      customVariants: variants,
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              disabledForegroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              product.stock > 0
                                  ? 'Add to Cart'
                                  : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Pinned back button — stays fixed at top, doesn't scroll
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: _circleBtn(
                onTap: () => Get.back(),
                icon: Icons.arrow_back_rounded,
                bg: bg,
              ),
            ),
            // Pinned heart button — stays fixed at top, doesn't scroll
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: Obx(
                () => _circleBtn(
                  onTap: () => wc.toggleWishlist(product),
                  icon: wc.isInWishlist(product.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  bg: bg,
                  iconColor: wc.isInWishlist(product.id)
                      ? AppTheme.errorColor
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }); // Obx
  }

  Widget _circleBtn({
    required VoidCallback onTap,
    required IconData icon,
    required Color bg,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REVIEWS SECTION
// ═══════════════════════════════════════════════════════════════
class _ReviewsSection extends StatefulWidget {
  final ProductModel product;
  const _ReviewsSection({required this.product});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  int? _starFilter; // null = all, 1-5 = filter
  String _sortBy = 'newest'; // newest, highest, lowest

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirebaseFirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface2 = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5);
    final product = widget.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () =>
                  _showWriteReviewDialog(context, firestoreService),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                'Write a Review',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReviewModel>>(
          stream: firestoreService.getReviewsStream(product.id),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            }

            final allReviews = snapshot.data ?? [];

            if (allReviews.isEmpty) {
              return _buildEmptyReviews(surface2);
            }

            // Compute distribution
            final dist = _computeDistribution(allReviews);
            final avgRating = allReviews.isEmpty
                ? 0.0
                : allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
                      allReviews.length;

            // Apply filter & sort
            var reviews = List<ReviewModel>.from(allReviews);
            if (_starFilter != null) {
              reviews = reviews
                  .where((r) => r.rating.round() == _starFilter)
                  .toList();
            }
            switch (_sortBy) {
              case 'highest':
                reviews.sort((a, b) => b.rating.compareTo(a.rating));
                break;
              case 'lowest':
                reviews.sort((a, b) => a.rating.compareTo(b.rating));
                break;
              default: // newest
                reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                break;
            }

            final displayReviews = reviews
                .where((r) => r.comment.isNotEmpty)
                .take(3)
                .toList();

            return Column(
              children: [
                // ── Rating Summary Card ──
                _buildSummaryCard(
                  avgRating,
                  allReviews.length,
                  dist,
                  surface2,
                  isDark,
                ),
                const SizedBox(height: 12),

                // ── Sort toggle ──
                if (allReviews.length > 1) ...[
                  _buildSortRow(isDark),
                  const SizedBox(height: 8),
                ],

                // ── Filtered count badge ──
                if (_starFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            '${_starFilter}★ only',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF5D4037),
                          ),
                          onDeleted: () => setState(() => _starFilter = null),
                          backgroundColor: AppTheme.secondaryColor.withValues(
                            alpha: isDark ? 0.35 : 0.15,
                          ),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                // ── Reviews list ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: displayReviews.isEmpty
                      ? Container(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surface2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'No reviews match this filter',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9EAA),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          key: const ValueKey('list'),
                          children: displayReviews
                              .map(
                                (r) => _buildSingleReview(r, surface2, isDark),
                              )
                              .toList(),
                        ),
                ),

                // ── See All button ──
                if (reviews.where((r) => r.comment.isNotEmpty).length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.allReviews,
                          arguments: {
                            'productId': product.id,
                            'productName': product.name,
                          },
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'See All ${reviews.where((r) => r.comment.isNotEmpty).length} Reviews',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Summary card: big avg rating + distribution bars ──
  Widget _buildSummaryCard(
    double avg,
    int total,
    Map<int, int> dist,
    Color surface2,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big number + stars
          SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < avg.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF9E9EAA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                final active = _starFilter == star;
                return GestureDetector(
                  onTap: () => setState(() {
                    _starFilter = _starFilter == star ? null : star;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$star★',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: active
                                  ? AppTheme.secondaryColor
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active
                                  ? AppTheme.secondaryColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: active
                                      ? AppTheme.secondaryColor
                                      : AppTheme.secondaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort row ──
  Widget _buildSortRow(bool isDark) {
    final options = {
      'newest': 'Newest',
      'highest': 'Highest',
      'lowest': 'Lowest',
    };
    return Row(
      children: [
        Text(
          'Sort:',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        ...options.entries.map((e) {
          final active = _sortBy == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryColor.withValues(alpha: 0.4)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Map<int, int> _computeDistribution(List<ReviewModel> reviews) {
    final map = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  Widget _buildEmptyReviews(Color surface2) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'No reviews yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first to review this product!',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9EAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleReview(ReviewModel r, Color surface2, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    r.userAvatar.isNotEmpty && r.userAvatar.startsWith('http')
                    ? Image.network(
                        r.userAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            r.userName.isNotEmpty
                                ? r.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          r.userName.isNotEmpty
                              ? r.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(r.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9EAA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comment,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : const Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWriteReviewDialog(
    BuildContext context,
    FirebaseFirestoreService firestoreService,
  ) {
    final auth = Get.find<AuthController>();

    // Guard: user must be logged in
    if (!auth.isLoggedIn.value) {
      AppSnack.error('Login Required', 'Please log in to write a review.');
      Get.toNamed(AppRoutes.login);
      return;
    }

    double rating = 5;
    final commentCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Write a Review',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'How would you rate this product?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setD(() => rating = i + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          i < rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 36,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience (optional)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkInputFill
                        : AppTheme.lightInputFill,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(
                  context,
                ).pop(); // reliable dismiss — won't clash with Get.snackbar
                try {
                  await firestoreService.addReview(
                    productId: widget.product.id,
                    rating: rating,
                    comment: commentCtrl.text.trim(),
                    userName: auth.userName.value.isNotEmpty
                        ? auth.userName.value
                        : 'Chicken Lover',
                    userAvatar:
                        (auth.userPhotoURL.value.isNotEmpty &&
                            auth.userPhotoURL.value.startsWith('http'))
                        ? auth.userPhotoURL.value
                        : '',
                  );
                  AppSnack.success(
                    'Thanks!',
                    'Your review has been submitted.',
                  );
                } catch (e) {
                  AppSnack.error('Oops', 'Could not submit review.');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = TimeService().serverNow().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE REVIEW DIALOG (used by product detail & orders)
// ═══════════════════════════════════════════════════════════════

void showProductReviewDialog({
  required String productId,
  required String productName,
  required FirebaseFirestoreService firestoreService,
}) {
  final auth = Get.find<AuthController>();

  if (!auth.isLoggedIn.value) {
    AppSnack.error('Login Required', 'Please log in to write a review.');
    Get.toNamed(AppRoutes.login);
    return;
  }

  double rating = 5;
  final commentCtrl = TextEditingController();
  final isDark =
      WidgetsBinding.instance.window.platformBrightness == Brightness.dark;

  Get.dialog(
    StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Write a Review',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Review: $productName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'How would you rate this product?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setD(() => rating = i + 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 36,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkInputFill
                      : AppTheme.lightInputFill,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Get.back();
              try {
                await firestoreService.addReview(
                  productId: productId,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                  userName: auth.userName.value.isNotEmpty
                      ? auth.userName.value
                      : 'Chicken Lover',
                  userAvatar:
                      (auth.userPhotoURL.value.isNotEmpty &&
                          auth.userPhotoURL.value.startsWith('http'))
                      ? auth.userPhotoURL.value
                      : '',
                );
                AppSnack.success('Thanks!', 'Your review has been submitted.');
              } catch (e) {
                AppSnack.error(
                  'Oops',
                  'Could not submit review: ${e.toString().replaceFirst("Exception: ", "")}',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// IMAGE SLIDESHOW
// ═══════════════════════════════════════════════════════════════
class _ImageSlideshow extends StatefulWidget {
  final List<String> images;
  final String productId;
  final Color surfaceColor;
  const _ImageSlideshow({
    required this.images,
    required this.productId,
    required this.surfaceColor,
  });

  @override
  State<_ImageSlideshow> createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends State<_ImageSlideshow> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return Container(
        color: widget.surfaceColor,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: Colors.grey),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'product-${widget.productId}',
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Image.network(
              images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: widget.surfaceColor,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        // Dot indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RELATED PRODUCTS SECTION
// ═══════════════════════════════════════════════════════════════
class _RelatedProductsSection extends StatelessWidget {
  final ProductModel product;
  final ProductController pc;
  final CartController cc;
  final bool isDark;
  const _RelatedProductsSection({
    required this.product,
    required this.pc,
    required this.cc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final related = pc.getRelatedProducts(
      product.id,
      category: product.category,
    );
    if (related.isEmpty) return const SizedBox.shrink();

    final curCtrl = Get.find<CurrencyController>();
    final wc = Get.find<WishlistController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface2 : const Color(0xFFECEDF0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'You Might Also Like',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${related.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: related.map((p) {
                  final bg = isDark ? AppTheme.darkSurface : Colors.white;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 170,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Get.to(
                            () => const ProductDetailScreen(),
                            arguments: p,
                            preventDuplicates: false,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Image + Badges ──
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: SizedBox(
                                      height: 150,
                                      width: double.infinity,
                                      child: p.images.isNotEmpty
                                          ? Image.network(
                                              p.images[0],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.image_outlined,
                                                    size: 36,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image_outlined,
                                              size: 36,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  // FLASH badge (shown first, overrides normal discount)
                                  if (p.isFlashSaleActive)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: _badge(
                                        p.flashDiscountPercent > 0
                                            ? 'FLASH -${p.flashDiscountPercent.round()}%'
                                            : 'FLASH',
                                        AppTheme.errorColor,
                                        icon: Icons.bolt,
                                        sz: 8,
                                      ),
                                    ),
                                  // Discount badge — only when no flash sale
                                  if (!p.isFlashSaleActive &&
                                      p.discountPercentDisplay > 3)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: _badge(
                                        '-${p.discountPercentDisplay.round()}%',
                                        Colors.amber,
                                      ),
                                    ),
                                  // Sold count badge
                                  if (p.showSoldCount && p.soldCount > 1000)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: _badge(
                                        '${(p.soldCount / 1000).toStringAsFixed(1)}k sold',
                                        Colors.black54,
                                      ),
                                    ),
                                  // Free shipping badge
                                  if (p.freeShipping)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: _badge(
                                        'Free Ship',
                                        AppTheme.successColor.withValues(
                                          alpha: 0.85,
                                        ),
                                        sz: 7,
                                      ),
                                    ),
                                  // Wishlist heart
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Obx(() {
                                      final fav = wc.isInWishlist(p.id);
                                      return GestureDetector(
                                        onTap: () => wc.toggleWishlist(p),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.white.withValues(
                                                    alpha: 0.85,
                                                  ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: isDark ? 0.3 : 0.06,
                                                ),
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            fav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: fav
                                                ? AppTheme.errorColor
                                                : (isDark
                                                      ? Colors.white54
                                                      : Colors.grey),
                                            size: 16,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              // ── Info ──
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Obx(() {
                                        final s = pc.getSellerById(p.sellerId);
                                        return Text(
                                          s?.name ?? p.sellerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600,
                                          ),
                                        );
                                      }),
                                      if (p.showRating)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: AppTheme.secondaryColor,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${p.rating}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (p.showReviewCount) ...[
                                              const SizedBox(width: 2),
                                              Text(
                                                '(${p.reviewCount})',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF9E9EAA),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                curCtrl.formatPriceCompact(
                                                  p.effectivePrice,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                              if (p.discountPercentDisplay >
                                                      0 ||
                                                  p.isFlashSaleActive)
                                                Text(
                                                  curCtrl.formatPriceCompact(
                                                    p.price,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : const Color(
                                                            0xFF9E9EAA,
                                                          ),
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () => cc.addToCart(p),
                                            child: Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.add_shopping_cart_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _badge(String text, Color bg, {IconData? icon, double sz = 8}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sz, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FLASH SALE COUNTDOWN
// ═══════════════════════════════════════════════════════════════
class _FlashCountdown extends StatefulWidget {
  final DateTime endTime;
  const _FlashCountdown({required this.endTime});

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    _remaining = widget.endTime.difference(TimeService().serverNow());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _tick());
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String twoDigit(int n) => n.toString().padLeft(2, '0');
    final h = twoDigit(_remaining.inHours);
    final m = twoDigit(_remaining.inMinutes.remainder(60));
    final s = twoDigit(_remaining.inSeconds.remainder(60));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.flashSaleColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.flashSaleColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: AppTheme.flashSaleColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Ends in',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          _box(h, isDark),
          const Text(
            ':',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.flashSaleColor,
            ),
          ),
          _box(m, isDark),
          const Text(
            ':',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.flashSaleColor,
            ),
          ),
          _box(s, isDark),
        ],
      ),
    );
  }

  Widget _box(String val, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.flashSaleColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        val,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
