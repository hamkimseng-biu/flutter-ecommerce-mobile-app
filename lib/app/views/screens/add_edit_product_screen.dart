import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_storage_service.dart';
import '../../models/product_model.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';

/// Full-screen page for adding or editing a product.
/// Receives an optional ProductModel via Get.arguments for edit mode.
class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storageService = FirebaseStorageService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _origPriceCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _flashPriceCtrl;

  List<String> _images = [];
  bool _isFeatured = false;
  bool _isFlashSale = false;
  bool _saving = false;
  bool _isEdit = false;
  ProductModel? _existing;
  String _sellerId = '';
  String _sellerName = 'Tiny Chicken Official';
  String _sellerAvatar = '🐔';

  final List<String> _categories = [
    'Clothing',
    'Electronics',
    'Accessories',
    'Shoes',
    'Home & Living',
    'Beauty',
  ];

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is ProductModel) {
      _isEdit = true;
      _existing = arg;
      _nameCtrl = TextEditingController(text: arg.name);
      _descCtrl = TextEditingController(text: arg.description);
      _priceCtrl = TextEditingController(text: arg.price.toString());
      _origPriceCtrl = TextEditingController(
        text: arg.originalPrice.toString(),
      );
      _categoryCtrl = TextEditingController(text: arg.category);
      _stockCtrl = TextEditingController(text: arg.stock.toString());
      _flashPriceCtrl = TextEditingController(
        text: arg.flashSalePrice > 0 ? arg.flashSalePrice.toString() : '',
      );
      _images = List<String>.from(arg.images);
      _isFeatured = arg.isFeatured;
      _isFlashSale = arg.isFlashSale;
      _sellerId = arg.sellerId;
      _sellerName = arg.sellerName;
      _sellerAvatar = arg.sellerAvatar;
    } else {
      _nameCtrl = TextEditingController();
      _descCtrl = TextEditingController();
      _priceCtrl = TextEditingController();
      _origPriceCtrl = TextEditingController();
      _categoryCtrl = TextEditingController(text: 'Clothing');
      _stockCtrl = TextEditingController(text: '50');
      _flashPriceCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _origPriceCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _flashPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final url = await _storageService.pickAndUploadImage();
    if (url != null && mounted) {
      setState(() => _images.add(url));
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Product name is required.');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Price is required.');
      return;
    }
    if (_images.isEmpty) {
      AppSnack.error('Required', 'At least one product image is required.');
      return;
    }

    setState(() => _saving = true);

    try {
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      final origPrice = double.tryParse(_origPriceCtrl.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 50;
      final flashPrice = double.tryParse(_flashPriceCtrl.text.trim()) ?? 0.0;

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': price,
        'originalPrice': origPrice,
        'images': _images,
        'category': _categoryCtrl.text.trim().isEmpty
            ? 'Clothing'
            : _categoryCtrl.text.trim(),
        'rating': _existing?.rating ?? 4.5,
        'reviewCount': _existing?.reviewCount ?? 0,
        'sizes': _existing?.sizes ?? ['S', 'M', 'L', 'XL'],
        'colors': _existing?.colors ?? _defaultColors(),
        'stock': stock,
        'sellerId': _sellerId.isEmpty
            ? (_existing?.sellerId ?? 'admin')
            : _sellerId,
        'sellerName': _sellerName,
        'sellerAvatar': _sellerAvatar,
        'soldCount': _existing?.soldCount ?? 0,
        'isFeatured': _isFeatured,
        'isFlashSale': _isFlashSale,
        'flashSalePrice': _isFlashSale ? flashPrice : 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit && _existing != null) {
        await _firestore.collection('products').doc(_existing!.id).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('products').add(data);
      }

      if (mounted) {
        setState(() => _saving = false);
        AppSnack.success(
          _isEdit ? 'Updated' : 'Added',
          _isEdit ? 'Product updated successfully.' : 'Product added to shop.',
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Failed to save: $e');
      }
    }
  }

  List<String> _defaultColors() {
    switch (_categoryCtrl.text.trim().toLowerCase()) {
      case 'clothing':
        return ['Black', 'White', 'Navy', 'Gray'];
      case 'shoes':
        return ['Black', 'White', 'Red', 'Blue'];
      case 'accessories':
        return ['Black', 'Brown', 'Tan'];
      default:
        return ['Black'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    _isEdit ? 'Update' : 'Save',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Images section ─────────────────────────────
            const Text(
              'Product Images',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Add up to 6 images. First image is the main display.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + (_images.length < 6 ? 1 : 0),
                itemBuilder: (_, i) {
                  // Add-image button
                  if (i == _images.length) {
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.primaryColor.withValues(alpha: 0.03),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add Image',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  // Image preview
                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 32,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (i == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Main',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Basic info — full width, no Rows to avoid overflow ──
            _sectionLabel('Basic Info'),
            const SizedBox(height: 10),
            _field(
              _nameCtrl,
              'Product Name',
              Icons.shopping_bag_outlined,
              fillColor,
            ),
            const SizedBox(height: 12),
            _field(
              _descCtrl,
              'Description',
              Icons.description_outlined,
              fillColor,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _field(
              _priceCtrl,
              'Price (\$)',
              Icons.attach_money,
              fillColor,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              _origPriceCtrl,
              'Original Price (optional)',
              Icons.money_off,
              fillColor,
              keyboardType: TextInputType.number,
              hint: 'Leave empty if no discount',
            ),
            const SizedBox(height: 12),
            _categoryDropdown(fillColor),
            const SizedBox(height: 12),
            _field(
              _stockCtrl,
              'Stock Quantity',
              Icons.inventory_2_outlined,
              fillColor,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Shop selector
            FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('shops').orderBy('name').get(),
              builder: (ctx, snap) {
                final shops = snap.data?.docs ?? [];
                if (shops.isEmpty) return const SizedBox.shrink();
                String curId = _sellerId.isNotEmpty
                    ? _sellerId
                    : (_existing?.sellerId ?? shops.first.id);
                final idx = shops.indexWhere((s) => s.id == curId);
                final curShop = idx >= 0 ? shops[idx] : shops.first;
                return DropdownButtonFormField<String>(
                  value: curShop.id,
                  decoration: InputDecoration(
                    labelText: 'Shop / Seller',
                    prefixIcon: const Icon(Icons.store_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: fillColor,
                    isDense: true,
                  ),
                  items: shops.map((s) {
                    final d = s.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          Text(
                            d['avatar'] ?? '🏪',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            d['name'] ?? 'Shop',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final idx2 = shops.indexWhere((s) => s.id == v);
                      if (idx2 < 0) return;
                      final s = shops[idx2];
                      final d = s.data() as Map<String, dynamic>;
                      setState(() {
                        _sellerId = v;
                        _sellerName = d['name'] ?? 'Tiny Chicken';
                        _sellerAvatar = d['avatar'] ?? '🐔';
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Toggles ────────────────────────────────────
            _sectionLabel('Settings'),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Featured Product',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Shown on home page featured section',
                style: TextStyle(fontSize: 11),
              ),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Flash Sale', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Shown in flash sale with countdown',
                style: TextStyle(fontSize: 11),
              ),
              value: _isFlashSale,
              onChanged: (v) => setState(() => _isFlashSale = v),
              activeColor: AppTheme.flashSaleColor,
            ),
            if (_isFlashSale) ...[
              const SizedBox(height: 8),
              _field(
                _flashPriceCtrl,
                'Flash Sale Price (\$)',
                Icons.bolt,
                fillColor,
                keyboardType: TextInputType.number,
                hint: 'Lower than regular price',
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color fillColor, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        isDense: true,
      ),
    );
  }

  Widget _categoryDropdown(Color fillColor) {
    return DropdownButtonFormField<String>(
      value: _categories.contains(_categoryCtrl.text.trim())
          ? _categoryCtrl.text.trim()
          : 'Clothing',
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        isDense: true,
      ),
      items: _categories
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          _categoryCtrl.text = v;
        }
      },
    );
  }
}
