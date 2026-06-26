# Tiny Chicken — Flutter E-Commerce App

## Project Overview

A full-featured mobile e-commerce app built with Flutter, GetX state management, and Firebase (Firestore, Auth, Storage). Users can browse products without login, add items to cart with variant selection, check out with address/payment, and manage orders. Admin panel for product/shop/order management.

## Tech Stack

- **Framework**: Flutter (SDK ^3.11.5)
- **State Management**: GetX (^4.6.6)
- **Backend**: Firebase Firestore, Firebase Auth, Firebase Storage
- **Auth**: Email/password, Google Sign-In, Phone OTP
- **Image Loading**: `cached_network_image` (^3.3.1)
- **Icons**: Material Icons, Iconsax

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── config/
│   │   ├── app_constants.dart    # App name, tagline
│   │   ├── app_snack.dart        # Toast notification helper
│   │   └── app_theme.dart        # Theme (colors, dark/light)
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   ├── cart_controller.dart
│   │   ├── home_controller.dart
│   │   ├── product_controller.dart
│   │   ├── theme_controller.dart
│   │   └── wishlist_controller.dart
│   ├── models/
│   │   ├── cart_item_model.dart
│   │   ├── category_model.dart
│   │   ├── product_model.dart
│   │   ├── review_model.dart
│   │   └── seller_model.dart
│   ├── routes/
│   │   └── app_routes.dart       # GetX route definitions
│   ├── services/
│   │   ├── firebase_auth_service.dart
│   │   ├── firebase_firestore_service.dart
│   │   ├── firebase_storage_service.dart
│   │   ├── fcm_service.dart
│   │   ├── mock_data_service.dart
│   │   └── seed_data.dart
│   └── views/
│       ├── widgets/
│       │   ├── category_chip.dart
│       │   ├── flash_countdown.dart
│       │   ├── product_card.dart
│       │   ├── search_bar_widget.dart
│       │   └── section_header.dart
│       └── screens/
│           ├── auth/             # login, register, splash
│           ├── home/             # home, main, search
│           ├── product/          # product_detail
│           ├── shop/             # shop
│           ├── cart/             # cart
│           ├── checkout/         # checkout
│           ├── wishlist/         # wishlist
│           ├── profile/          # profile, edit_profile, profile_sub_screens, add_edit_address/card/bank
│           ├── order/            # order_detail
│           └── admin/            # admin_products, add_edit_product, add_edit_shop
assets/
├── images/
│   ├── icon.png                  # App icon (87KB)
│   ├── logo.png
│   ├── placeholder.png
│   └── google_logo.png
└── logo/
    ├── icons8-google-logo-48.png
    └── icons8-google-logo-96.png

```

## Key Features Implemented

### Authentication
- Email/password sign-up and sign-in with validation
- Google Sign-In (requires SHA-1 in Firebase Console)
- Phone OTP sign-in (dialog-based: enter phone → receive SMS → enter code)
- Guest browsing allowed (splash goes to main, login accessible from profile)

### Product Browsing
- Real-time Firestore stream for product list (no manual refresh needed)
- Category filtering across ALL sections (Flash Deals, Recently Viewed, Guess You Like)
- Sections auto-hide when no products match the selected category
- Product cards use CachedNetworkImage for reliable loading
- Product detail: first image in header, remaining images as scrollable gallery below reviews

### Cart — TaoBao-Style
- Items grouped by shop with colored header showing shop name
- Per-item checkboxes for selection (variant-aware: same product, different size/color = separate items)
- Shop-level and global "Select All" toggles
- Persisted to Firestore per user, auto-loads on app start
- Auto-selects all items on load; selections survive restarts
- Bottom bar: Total = $0.00 when nothing selected, shows selected total otherwise
- "Checkout (N)" button only sends selected items
- Swipe left to delete individual items
- Quantity +/- inline controls
- Clear cart with confirmation dialog
- Tap shop name → shop page; tap item → product detail

### Checkout
- Address validation (blocks order if no address)
- Taobao-style fixed bottom bar: "Total payment: $X.XX" + "Place Order (N)"
- Payment method: bottom sheet picker grouped by type (Cards / Banks / COD)
  - Same design as Settings → Language picker
  - "Add new payment method" option navigates to Payment Methods screen
- Order placed dialog with confetti
- Only selected items go to checkout (no fallback to all items if nothing selected and cart has >1 item)

### Orders (My Orders)
- Twitter-style tab bar: All, Processing, Shipping, Delivered, Cancelled, To Review
- Swipe to delete cancelled orders (Dismissible with red background)
- Per-order cancel button with confirmation dialog
- Status timeline in order detail

### Profile & Payment Methods
- Addresses, Cards, Bank Accounts — all stored in Firestore per user
- NO mock/placeholder data — shows empty states instead (fixed)
- All add/edit screens use bottom save button (not AppBar button)
- Snackbar notifications shown on parent screens (not edit screens) for reliable display
- Delete with confirmation dialogs

### Admin Panel
- Products tab: add/edit/delete with snackbar confirmations
- Orders tab: collection-group query for all users' orders (needs Firestore composite index)
  - Search bar + status filter dropdown
  - Status change via 3-dot menu
- Shops tab: create/edit/delete shops
- Seed demo data button
- Image input via URL dialog (Firebase Storage not available — no Blaze plan)

### UX Patterns
- All snackbar notifications: 5-second duration, close button, appear on parent screen
- Empty states everywhere (no fake data)
- Image URLs via paste dialog (with helpful hints for working services)
- App logo icon.png used in splash, home bar, profile avatar fallback
- No 🐔 emoji in user-facing text (replaced with logo image)
- Settings: Clear All Data shows snackbar directly (no dialog)

## Firestore Data Model

```
products/{docId}
  name, description, price, originalPrice, images[], category,
  rating, reviewCount, sizes[], colors[], stock,
  sellerId, sellerName, sellerAvatar,
  isFeatured, isFlashSale, flashSalePrice,
  createdAt, updatedAt

users/{uid}
  recentlyViewed[]       # product IDs
  cart/{cartItemKey}     # key = productId_size_color
  wishlist/{productId}
  orders/{docId}         # items[], subtotal, tax, shipping, discount, total, status, createdAt
  addresses/{docId}      # recipient, phone, label, street, city, province, zip, isDefault
  cards/{docId}          # number, holder, expiry, brand, isDefault
  bank_accounts/{docId}  # bankName, accountHolder, accountNumber, routingNumber, accountType, isDefault

shops/{docId}
  name, description, logoUrl, bannerUrl, isOfficial, createdAt, updatedAt
```

## Required Firebase Console Setup

1. **Firestore Rules**: See `firestore.rules` — allows public read on products/categories/shops, requires auth for user data
2. **Storage Rules**: `allow read, write: if request.auth != null;` (if using Storage)
3. **SHA-1 Fingerprint** (for Google Sign-In): `5A:42:7C:44:18:72:37:6B:9F:42:1B:3E:69:7D:A7:69:EE:1B:92:92`
4. **SHA-256 Fingerprint** (REQUIRED for Phone Auth on Android): `63:E3:07:73:5F:B2:8D:AC:65:33:76:08:43:A9:E9:11:FC:7D:DF:41:56:79:2A:1D:65:02:8C:AD:24:5E:3F:3C`
   - Add BOTH SHA-1 and SHA-256 in Firebase Console → Project Settings → Your Android App → Add fingerprint
5. **Phone Auth**: Enable in Firebase Console → Authentication → Sign-in method → Phone
6. **Composite Index** for admin orders: `collectionGroup('orders')` with `createdAt DESC`

## Known Limitations

- **Firebase Storage unavailable** (no Blaze plan) → image URLs must be externally hosted
- **Pinterest/Instagram URLs blocked** (hotlink protection) — use Picsum, Imgur, or Unsplash direct links
- **Cart selections don't persist across FULL app uninstall** (stored in Firestore per user, not local)
- **Phone auth** requires Firebase Blaze plan for production use
- **Admin orders collectionGroup** requires composite index creation in Firebase Console
- **No stock enforcement** at checkout (stock field exists but isn't validated)

## Critical Code Patterns

### Snackbar Notifications
```dart
// Show on CALLING screen (after Get.back), not on edit screen
AppSnack.success('Title', 'Message');
AppSnack.error('Title', 'Message');
AppSnack.info('Title', 'Message');
```

### Cart Item Keys (Variant-Aware)
```dart
String _cartKeyFromItem(CartItemModel item) =>
    '${item.productId}_${item.selectedSize}_${item.selectedColor}';
```

### Category Filtering
```dart
// In ProductController — filtered getters react to selectedCategoryIndex
List<ProductModel> get filteredFlashSale { ... }
List<ProductModel> get filteredFeatured { ... }
```

## Color Palette

| Name | Value |
|---|---|
| Primary | Orange (`AppTheme.primaryColor`) |
| Secondary | Amber/Gold (`AppTheme.secondaryColor`) |
| Flash Sale | Red/Orange (`AppTheme.flashSaleColor`) |
| Success | Green (#43A047) |
| Error | Red (#E53935) |
| Checkout Button | #FF6B35 (Taobao orange) |

## Memory File

See `/memories/repo/ux-flow-rules.md` for UX validation checklist.

