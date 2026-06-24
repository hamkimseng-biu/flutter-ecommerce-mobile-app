// Seed Script — Populate Firestore with demo products
//
// USAGE:
//   cd tiny_chicken
//   dart run scripts/seed_products.dart
//
// REQUIREMENTS:
//   - Firebase project configured with Firestore
//   - google-services.json in android/app/
//   - Run `flutterfire configure` first if needed
//
// This script adds 12 demo products to your Firestore 'products' collection.
// Images use picsum.photos (free stock photos from Unsplash — looks like real items).
// To replace images later, use the Admin Panel (Settings → App Version → Products tab).
// Or upload your own images to Firebase Storage via the admin UI.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore_for_file: avoid_relative_lib_imports
import '../lib/firebase_options.dart';

final products = [
  {
    'name': 'Classic White T-Shirt',
    'description':
        'Premium cotton crew neck t-shirt. Soft, breathable, and perfect for everyday wear. Available in multiple colors.',
    'price': 19.99,
    'originalPrice': 29.99,
    'images': [
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&h=800&fit=crop',
    ],
    'category': 'Clothing',
    'rating': 4.7,
    'reviewCount': 234,
    'stock': 150,
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'sellerName': 'Tiny Chicken Official',
    'sellerAvatar': '🐔',
    'soldCount': 1520,
    'isFeatured': true,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Slim Fit Denim Jacket',
    'description':
        'Vintage-style denim jacket with a modern slim fit. Features button closure, chest pockets, and a comfortable cotton blend.',
    'price': 74.99,
    'originalPrice': 99.99,
    'images': [
      'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=600&h=800&fit=crop',
    ],
    'category': 'Clothing',
    'rating': 4.8,
    'reviewCount': 189,
    'stock': 45,
    'sizes': ['S', 'M', 'L', 'XL'],
    'sellerName': 'Urban Streetwear',
    'sellerAvatar': '🧢',
    'soldCount': 890,
    'isFeatured': true,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Wireless Bluetooth Earbuds',
    'description':
        'True wireless earbuds with active noise cancellation, 30-hour battery life, and IPX5 water resistance. Crystal clear audio.',
    'price': 89.99,
    'originalPrice': 129.99,
    'images': [
      'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=600&h=800&fit=crop',
    ],
    'category': 'Electronics',
    'rating': 4.5,
    'reviewCount': 567,
    'stock': 200,
    'sellerName': 'TechGear Hub',
    'sellerAvatar': '🎧',
    'soldCount': 3400,
    'isFeatured': false,
    'isFlashSale': true,
    'flashSalePrice': 59.99,
  },
  {
    'name': 'Summer Floral Dress',
    'description':
        'Light and airy floral print dress perfect for summer days. Features a flattering A-line cut and adjustable waist tie.',
    'price': 45.99,
    'originalPrice': 65.99,
    'images': [
      'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&h=800&fit=crop',
    ],
    'category': 'Clothing',
    'rating': 4.6,
    'reviewCount': 312,
    'stock': 75,
    'sizes': ['XS', 'S', 'M', 'L'],
    'sellerName': 'Tiny Chicken Official',
    'sellerAvatar': '🐔',
    'soldCount': 2100,
    'isFeatured': true,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Leather Crossbody Bag',
    'description':
        'Genuine leather crossbody bag with adjustable strap. Multiple compartments keep your essentials organized in style.',
    'price': 54.99,
    'originalPrice': 79.99,
    'images': [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&h=800&fit=crop',
    ],
    'category': 'Accessories',
    'rating': 4.9,
    'reviewCount': 145,
    'stock': 30,
    'sellerName': 'Tiny Chicken Official',
    'sellerAvatar': '🐔',
    'soldCount': 670,
    'isFeatured': false,
    'isFlashSale': true,
    'flashSalePrice': 34.99,
  },
  {
    'name': 'Running Performance Sneakers',
    'description':
        'Lightweight running shoes with responsive cushioning and breathable mesh upper. Designed for speed and comfort.',
    'price': 119.99,
    'originalPrice': 149.99,
    'images': [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600&h=800&fit=crop',
    ],
    'category': 'Shoes',
    'rating': 4.4,
    'reviewCount': 423,
    'stock': 60,
    'sizes': ['7', '8', '9', '10', '11', '12'],
    'sellerName': 'SportFlex',
    'sellerAvatar': '⚽',
    'soldCount': 2800,
    'isFeatured': true,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Stainless Steel Water Bottle',
    'description':
        'Double-wall vacuum insulated bottle. Keeps drinks cold 24hrs or hot 12hrs. BPA-free, leak-proof, 750ml capacity.',
    'price': 29.99,
    'originalPrice': 39.99,
    'images': [
      'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1570831739435-6601aa3fa4fb?w=600&h=800&fit=crop',
    ],
    'category': 'Home & Living',
    'rating': 4.8,
    'reviewCount': 890,
    'stock': 300,
    'sellerName': 'HomeStyle Living',
    'sellerAvatar': '🏠',
    'soldCount': 5600,
    'isFeatured': false,
    'isFlashSale': true,
    'flashSalePrice': 19.99,
  },
  {
    'name': 'Cotton Linen Pants',
    'description':
        'Relaxed-fit cotton-linen blend pants. Perfect for casual and semi-formal occasions. Comes with elastic waistband.',
    'price': 39.99,
    'originalPrice': 0.0,
    'images': [
      'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&h=800&fit=crop',
    ],
    'category': 'Clothing',
    'rating': 4.3,
    'reviewCount': 178,
    'stock': 90,
    'sizes': ['S', 'M', 'L', 'XL'],
    'sellerName': 'Tiny Chicken Official',
    'sellerAvatar': '🐔',
    'soldCount': 1200,
    'isFeatured': false,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Smart Watch Fitness Tracker',
    'description':
        'Track your health 24/7 with heart rate monitoring, SpO2, sleep tracking, and 14-day battery life. Water resistant to 50m.',
    'price': 199.99,
    'originalPrice': 249.99,
    'images': [
      'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=600&h=800&fit=crop',
    ],
    'category': 'Electronics',
    'rating': 4.6,
    'reviewCount': 756,
    'stock': 40,
    'sellerName': 'TechGear Hub',
    'sellerAvatar': '🎧',
    'soldCount': 4100,
    'isFeatured': true,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Hydrating Face Cream',
    'description':
        'Daily moisturizer with hyaluronic acid and vitamin E. Lightweight, non-greasy formula for all skin types. 50ml.',
    'price': 34.99,
    'originalPrice': 0.0,
    'images': [
      'https://images.unsplash.com/photo-1570194065650-d99fb4ee8e39?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=600&h=800&fit=crop',
    ],
    'category': 'Beauty',
    'rating': 4.7,
    'reviewCount': 534,
    'stock': 120,
    'sellerName': 'BeautyGlow',
    'sellerAvatar': '✨',
    'soldCount': 3200,
    'isFeatured': false,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
  {
    'name': 'Minimalist Desk Lamp',
    'description':
        'LED desk lamp with adjustable brightness and color temperature. USB charging port, touch control, eye-care technology.',
    'price': 49.99,
    'originalPrice': 69.99,
    'images': [
      'https://images.unsplash.com/photo-1507473885765-e6ed057ab6fe?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600&h=800&fit=crop',
    ],
    'category': 'Home & Living',
    'rating': 4.4,
    'reviewCount': 267,
    'stock': 85,
    'sellerName': 'HomeStyle Living',
    'sellerAvatar': '🏠',
    'soldCount': 950,
    'isFeatured': false,
    'isFlashSale': true,
    'flashSalePrice': 34.99,
  },
  {
    'name': 'Polarized Aviator Sunglasses',
    'description':
        'Classic aviator style with polarized UV400 lenses. Lightweight metal frame with comfortable nose pads. Includes case.',
    'price': 24.99,
    'originalPrice': 44.99,
    'images': [
      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&h=800&fit=crop',
      'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&h=800&fit=crop',
    ],
    'category': 'Accessories',
    'rating': 4.5,
    'reviewCount': 198,
    'stock': 200,
    'sellerName': 'Tiny Chicken Official',
    'sellerAvatar': '🐔',
    'soldCount': 1800,
    'isFeatured': false,
    'isFlashSale': false,
    'flashSalePrice': 0.0,
  },
];

Future<void> main() async {
  print('🐔 Tiny Chicken — Product Seeder');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');

  // Initialize Firebase with explicit options (needed for standalone Dart scripts)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase init failed: $e');
    print('   Make sure google-services.json is in android/app/');
    print('   Or run: flutterfire configure');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  int added = 0;
  int skipped = 0;

  // ── Seed promo codes ──
  await _seedPromoCodes(firestore);

  // ── Seed products ──
  for (final product in products) {
    try {
      // Check if product with same name already exists
      final existing = await firestore
          .collection('products')
          .where('name', isEqualTo: product['name'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('⏭️  SKIPPED: ${product['name']} (already exists)');
        skipped++;
        continue;
      }

      // Ensure colors field has defaults if not specified
      final data = Map<String, dynamic>.from(product);
      if (!data.containsKey('colors') || (data['colors'] as List).isEmpty) {
        data['colors'] = _defaultColors(data['category'] as String);
      }
      data['createdAt'] = FieldValue.serverTimestamp();

      await firestore.collection('products').add(data);

      print('✅ ADDED: ${product['name']}');
      added++;
    } catch (e) {
      print('❌ FAILED: ${product['name']} — $e');
    }
  }

  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ $added products added, $skipped skipped');
  print('🌐 Now check your app — products should appear!');
}

/// Seeds default promo codes into Firestore
Future<void> _seedPromoCodes(FirebaseFirestore firestore) async {
  final codes = [
    {
      'code': 'CHICKEN10',
      'discountPercent': 10,
      'description': '10% off your first order!',
      'active': true,
      'maxUses': 500,
      'usedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'code': 'TINY50',
      'discountPercent': 50,
      'description': '50% off — VIP only!',
      'active': true,
      'maxUses': 50,
      'usedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'code': 'FREESHIP',
      'discountPercent': 100,
      'description': 'Free shipping on orders over \$30!',
      'active': true,
      'maxUses': 1000,
      'usedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  for (final code in codes) {
    final existing = await firestore
        .collection('promo_codes')
        .where('code', isEqualTo: code['code'])
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await firestore.collection('promo_codes').add(code);
      print('🏷️  Promo code added: ${code['code']}');
    } else {
      print('⏭️  Promo code exists: ${code['code']}');
    }
  }
}

/// Default colors per category
List<String> _defaultColors(String category) {
  switch (category.toLowerCase()) {
    case 'clothing':
      return ['Black', 'White', 'Navy', 'Gray'];
    case 'shoes':
      return ['Black', 'White', 'Red', 'Blue'];
    case 'accessories':
      return ['Black', 'Brown', 'Tan'];
    case 'beauty':
      return ['Clear', 'White'];
    default:
      return ['Black'];
  }
}
