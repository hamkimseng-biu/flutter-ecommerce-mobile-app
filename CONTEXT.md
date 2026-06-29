# Tiny Chicken — Flutter E-Commerce App

## Project Overview

A full-featured mobile e-commerce app built with Flutter, GetX state management, and Firebase (Firestore, Auth, Storage). Users can browse products without login, add items to cart with variant selection, check out with address/payment, and manage orders. Admin panel for product/shop/order management.

## Tech Stack

- **Framework**: Flutter (SDK ^3.11.5)
- **State Management**: GetX (^4.6.6)
- **Backend**: Firebase Firestore, Firebase Auth, Firebase Storage, Firebase Cloud Messaging
- **Auth**: Email/password, Google Sign-In, Facebook, Phone OTP
- **Image Loading**: `cached_network_image` (^3.3.1), `shimmer` (^3.0.0)
- **Icons**: Material Icons, Iconsax

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── config/
│   │   ├── app_constants.dart    # App name, tagline, logoPath
│   │   ├── app_snack.dart        # Toast notification helper
│   │   └── app_theme.dart        # Theme (colors, dark/light)
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   ├── cart_controller.dart
│   │   ├── home_controller.dart  # + showSortPanel toggle
│   │   ├── product_controller.dart # sellers stream, getSellerProductCount
│   │   ├── theme_controller.dart
│   │   ├── currency_controller.dart
│   │   └── wishlist_controller.dart
│   ├── models/
│   │   ├── cart_item_model.dart
│   │   ├── category_model.dart
│   │   ├── product_model.dart    # includes sellerId, sellerName, sellerAvatar
│   │   ├── review_model.dart
│   │   └── seller_model.dart
│   ├── routes/
│   │   └── app_routes.dart       # GetX routes with custom transitions & curves
│   ├── services/
│   │   ├── firebase_auth_service.dart
│   │   ├── firebase_firestore_service.dart
│   │   ├── firebase_storage_service.dart
│   │   ├── fcm_service.dart      # Push notifications + getUnreadCountStream
│   │   ├── mock_data_service.dart
│   │   └── seed_data.dart
│   └── views/
│       ├── widgets/
│       │   ├── product_card.dart    # Hero + wishlist heart animation
│       │   ├── search_bar_widget.dart
│       │   └── section_header.dart
│       └── screens/
│           ├── auth/             # login, register, splash, phone_otp, forgot_password
│           ├── home/             # home_screen (+ _StaggeredItem, shimmer), main_screen, search_screen, flash_sales, popular_shops
│           ├── product/          # product_detail (+ _RelatedProductsSection, sellerIcon)
│           ├── shop/             # shop_screen (reactive seller via Obx)
│           ├── cart/             # cart_screen
│           ├── checkout/         # checkout_screen (guest + stock enforcement)
│           ├── wishlist/         # wishlist_screen
│           ├── profile/          # profile, edit_profile, profile_sub_screens (orders/addresses/payment/notifications/help), add_edit_address/card/bank
│           ├── order/            # order_detail
│           └── admin/            # admin_products, add_edit_product, add_edit_shop (batch product sync)
assets/
├── logo/
│   ├── Chicken Logo.png          # Primary app logo
│   └── icons8-google-logo-*.png
└── images/
    ├── icon.png
    ├── logo.png
    └── placeholder.png
```

## Key Features Implemented

### Authentication
- Email/password sign-up and sign-in with validation
- Google Sign-In (requires SHA-1 in Firebase Console)
- Facebook Sign-In (flutter_facebook_auth ^7.1.1, client token)
- Phone OTP sign-in (dialog-based: enter phone → receive SMS → enter code)
- Credential linking for account-exists-with-different-credential
- Guest browsing allowed (splash goes to main, login accessible from profile)

### Product Browsing
- Real-time Firestore stream for product list (no manual refresh needed)
- Category filtering across ALL sections (Flash Deals, Recently Viewed, Guess You Like)
- Sections auto-hide when no products match the selected category
- Product cards use CachedNetworkImage + Hero animation for navigation
- Product detail: first image in header, remaining images as scrollable gallery below reviews
- **Related Products** ("You Might Also Like") on product detail — horizontal scroll with full badges (discount %, FLASH, sold count, free shipping, wishlist), reactive seller names, uses `GestureDetector(behavior: HitTestBehavior.opaque)` for reliable taps
- **Staggered fade-in animation** for product grid items on home screen
- **Shimmer loading** using `shimmer` package, respects dark/light mode
- **Wishlist heart** has elasticOut scale bounce animation on toggle

### Page Transitions (app_routes.dart)
- Product detail: `Transition.fadeIn` (300ms, easeOut) — clean with Hero
- Add/edit screens: `Transition.downToUp` (350ms, easeOutCubic) — slides up like a sheet
- Auth screens: `Transition.fadeIn` (250-300ms)
- Navigation flows: `Transition.rightToLeftWithFade` (350ms, easeOutCubic)
- All transitions have explicit `transitionDuration` and `curve`

### Push Notifications (FCM)
- `FcmService` initialized in `main.dart` after Firebase
- Foreground messages → in-app snackbar + saved to Firestore history
- Background/terminated tap → deep-links to order detail, orders list, or home
- Notification bell icon with red badge (real-time unread count) in home AppBar
- `NotificationsScreen` with read/unread states, mark all read, swipe to delete
- Android notification channel: `tiny_chicken_general` (MainActivity.kt)
- `POST_NOTIFICATIONS` permission for Android 13+
- Bug fixed: `markAllAsRead` was setting `read: false` — now `read: true`

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
- Order placed dialog with confetti
- Guest checkout with name/email/address fields
- Stock enforcement at checkout (checks Firestore stock)
- Return/Refund flow with "Return Requested" tab in orders

### Orders (My Orders)
- 8 tabs: All, Processing, Shipping, Delivered, Return Requested, Cancelled, To Review
- Swipe to delete cancelled orders (Dismissible with red background)
- Per-order cancel button with confirmation dialog
- Return request / Cancel return on delivered orders
- Status timeline in order detail

### Profile & Payment Methods
- Addresses, Cards, Bank Accounts — all stored in Firestore per user
- NO mock/placeholder data — shows empty states instead
- All add/edit screens use bottom save button (not AppBar button)
- Snackbar notifications shown on parent screens for reliable display
- Delete with confirmation dialogs

### Shop Page (Reactive)
- Receives `sellerId` as argument (backward-compatible with old SellerModel)
- Uses `Obx(() => pc.getSellerById(_sellerId))` — updates instantly when shop data changes
- Reactive product count via `pc.getSellerProductCount(sellerId)`
- Follower count updates immediately via `FieldValue.increment()` on follow/unfollow
- Follow button with real-time state
- Sort bottom sheet with dark mode text colors (no more unreadable text)
- Size filter removed from sort menu

### Admin Panel
- Products tab: add/edit/delete with snackbar confirmations
- Variants (renamed from "Sizes & Colors"): sizes, colors, materials, custom variant types
- Orders tab: collection-group query for all users' orders
  - Search bar + status filter dropdown
  - Status change via 3-dot menu
- Shops tab: create/edit/delete shops
- **Shop edit → batch product sync**: updating shop name/logo batch-updates all products with matching `sellerId`
- **Shop delete → product cleanup**: marks affected products as "Unknown Shop"
- **Product seller assignment**: reads `logoUrl` (not `avatar`) from shop document
- Seed demo data button
- Image input via URL dialog (Firebase Storage not available)

### Data Reactivity
- `_loadSellers()` uses `.snapshots()` stream (was one-time `.get()`) — all seller data updates in real-time
- `getSellerProductCount()` computes product count from reactive `allProducts` list
- `getSellerById()` returns reactive `SellerModel?` from stream
- Seller chip on product detail uses `seller?.name` (reactive) not `product.sellerName` (stale)
- `sellerIcon()` helper shows shop logo image or emoji fallback
- Related products cards use `Obx(() => pc.getSellerById(p.sellerId)?.name ?? p.sellerName)`

### Variants (Product Detail & Admin)
- Admin: "Variants" ExpansionTile with Sizes, Materials, Colors, and custom variant types
- Product detail: unified "Variants" header, then color chips + size chips + size guide
- Custom variant types can be added dynamically in admin

### App Branding
- **App label**: "Tiny Chicken" (AndroidManifest.xml)
- **Launcher icon**: Chicken Logo (`flutter_launcher_icons.yaml` → regenerated mipmaps)
- **In-app logo**: All screens use `assets/logo/Chicken Logo.png` (splash, home, login, register, forgot password, profile, edit profile)
- **Logo path constant**: `AppConstants.logoPath = 'assets/logo/Chicken Logo.png'`

### UX Patterns
- All snackbar notifications: 5-second duration, close button, appear on parent screen
- Empty states everywhere (no fake data)
- Image URLs via paste dialog
- Settings: Clear All Data shows snackbar directly

## Key Architectural Decisions

### Why `HitTestBehavior.opaque` on related products
Horizontal ListView/SingleChildScrollView inside CustomScrollView slivers caused gesture arena conflicts — taps on child widgets were consumed by the outer scroll view. Solution: `GestureDetector(behavior: HitTestBehavior.opaque)` forces hit testing regardless of parent scroll views. Also uses `SingleChildScrollView` + `Row` instead of `ListView.builder` to minimize gesture conflicts.

### Why `Get.to()` not `Get.toNamed()` for product detail navigation
`Get.to(() => const ProductDetailScreen(), arguments: p, preventDuplicates: false)` — `preventDuplicates: false` is required so users can navigate from product A → product B → product C without GetX blocking same-route pushes.

### Why reactive seller lookup instead of denormalized fields
Products store `sellerName`/`sellerAvatar` as denormalized copies. When admin updates a shop, a batch write syncs all products. But for immediate UI updates without waiting for the batch, the product detail and shop screens look up `pc.getSellerById(sellerId)` reactively via the sellers stream.

## Firestore Data Model

```
products/{docId}
  name, description, price, originalPrice, images[], detailImages[], category,
  rating, reviewCount, sizes[], colors[], materials[], customVariants{}, stock,
  sellerId, sellerName, sellerAvatar,
  isFeatured, isFlashSale, flashSalePrice, showSoldCount, soldCount,
  freeShipping, showRating, showReviewCount,
  createdAt, updatedAt

users/{uid}
  recentlyViewed[]       # product IDs
  cart/{cartItemKey}     # key = productId_size_color
  wishlist/{productId}
  orders/{docId}         # items[], subtotal, tax, shipping, discount, total, status, createdAt
  addresses/{docId}      # recipient, phone, label, street, city, province, zip, isDefault
  cards/{docId}          # number, holder, expiry, brand, isDefault
  bank_accounts/{docId}  # bankName, accountHolder, accountNumber, routingNumber, accountType, isDefault
  notifications/{docId}  # title, body, read, createdAt
  followedShops/{shopId} # followedAt
  fcmToken               # string, fcmTokenUpdatedAt

shops/{docId}
  name, description, logoUrl, bannerUrl, isOfficial, isPopular,
  followerCount, rating,
  createdAt, updatedAt
```

## Required Firebase Console Setup

1. **Firestore Rules**: See `firestore.rules` — allows public read on products/categories/shops, requires auth for user data
2. **Storage Rules**: `allow read, write: if request.auth != null;` (if using Storage)
3. **SHA-1 Fingerprint** (for Google Sign-In): `5A:42:7C:44:18:72:37:6B:9F:42:1B:3E:69:7D:A7:69:EE:1B:92:92`
4. **SHA-256 Fingerprint** (REQUIRED for Phone Auth on Android): `63:E3:07:73:5F:B2:8D:AC:65:33:76:08:43:A9:E9:11:FC:7D:DF:41:56:79:2A:1D:65:02:8C:AD:24:5E:3F:3C`
5. **Phone Auth**: Enable in Firebase Console → Authentication → Sign-in method → Phone
6. **Facebook Auth**: App ID `1471584444982877`, Client Token `dfd9c75205e933df0572702299b485e5`
7. **FCM**: Server key in Firebase Console → Cloud Messaging
8. **Composite Index** for admin orders: `collectionGroup('orders')` with `createdAt DESC`

## Known Limitations

- **Firebase Storage unavailable** (no Blaze plan) → image URLs must be externally hosted
- **Pinterest/Instagram URLs blocked** (hotlink protection) — use Imgur or Unsplash direct links
- **App Check disabled in debug** (kDebugMode) to avoid rate limiting
- **Phone auth** requires Firebase Blaze plan for production use
- **Admin orders collectionGroup** requires composite index creation in Firebase Console

## Critical Code Patterns

### Snackbar Notifications
```dart
AppSnack.success('Title', 'Message');
AppSnack.error('Title', 'Message');
AppSnack.info('Title', 'Message');
```

### Cart Item Keys (Variant-Aware)
```dart
String _cartKeyFromItem(CartItemModel item) =>
    '${item.productId}_${item.selectedSize}_${item.selectedColor}';
```

### Reactive Seller Lookup
```dart
// In shop screen — use Obx for real-time updates
Obx(() {
  final seller = pc.getSellerById(_sellerId);
  final productCount = pc.getSellerProductCount(_sellerId);
  return Text(seller?.name ?? 'Shop');
});
```

### Related Products Navigation (from product detail)
```dart
// preventDuplicates: false required for same-route pushes
Get.to(() => const ProductDetailScreen(), arguments: p, preventDuplicates: false);
```

### Admin Shop Save → Batch Product Sync
```dart
// In add_edit_shop_screen.dart _save()
await _firestore.collection('shops').doc(_docId).update(data);
await _syncProductsSellerInfo(_docId!, shopName, shopLogo);
// _syncProductsSellerInfo queries products where sellerId == shopId, batch updates
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

---

## Recent Fixes & Improvements (June 2026)

### Discount Calculation Fix
- **Bug**: `discountPercentDisplay` used `(originalPrice - effectivePrice) / originalPrice` which combined regular discount + flash discount into wrong number.
- **Fix**: `discountPercentDisplay` now returns `discountPercent` directly (admin-set value). Added `flashDiscountPercent` getter for flash-only %.
- **Files**: `product_model.dart`, `product_card.dart`, `product_detail_screen.dart`

### Flash Sale Expiry + Countdown
- `isFlashSaleActive` check respects `saleEndsAt` — flash sale auto-expires when time is up.
- `_FlashCountdown` widget shows HH:MM:SS timer on product detail, updates every second.
- All badges use `isFlashSaleActive` (not `isFlashSale`). When expired, price reverts to regular, flash badge hides, regular discount badge shows.
- **Files**: `product_model.dart`, `product_detail_screen.dart`, `product_card.dart`, `product_controller.dart`

### Server Time Sync (TimeService)
- `TimeService` syncs device clock with Firestore server time on app startup.
- Used by flash countdown, `isFlashSaleActive`, and `_timeAgo` — accurate even if phone clock is wrong.
- **Files**: `time_service.dart` (new), `main.dart`, `product_model.dart`, `flash_countdown.dart`, `all_reviews_screen.dart`

### Product Detail Reactivity
- **Bug**: Product detail grabbed product from `Get.arguments` once and never updated when admin changed it in Firestore.
- **Fix**: Now looks up `pc.getProductById(productId)` inside `Obx` — updates instantly when Firestore data changes.
- **File**: `product_detail_screen.dart`

### Review Section Redesign
- Added rating summary card (big average, star distribution bars, total count).
- Filter by star rating — tap any bar row to filter, shows dismissible chip.
- Sort toggle: Newest / Highest / Lowest.
- Rating-only reviews (no text) hidden from list but still count in stats.
- `AnimatedSwitcher` for smooth filter/sort transitions (250ms fade).
- All Reviews page has same summary card + filters + sort.
- **Files**: `product_detail_screen.dart`, `all_reviews_screen.dart`

### Orders UX Improvements
- Merged "Shipping" + "On Delivery" → "In Transit" (8 tabs → 7).
- 4-segment progress bar (Processing → Shipping → On Delivery → Delivered).
- Search bar for orders (by ID or product name).
- Inline review dialog from orders (no more navigating to product page).
- First item name shown on order card.
- "Clear All" behind 3-dot menu (was dangerous prominent button).
- RefreshIndicator + proper Icon empty states.
- Order detail now shows shipping address, payment method, item list, itemized pricing.
- Item thumbnails tappable → navigates to product page with live image fallback.
- **Files**: `profile_sub_screens.dart`, `order_detail_screen.dart`

### Theme Toggle Fix
- **Bug**: `Get.changeTheme()` / `Get.changeThemeMode()` disrupted route stack — back button went to home instead of Profile.
- **Fix**: `GetMaterialApp` wrapped in `Obx` watching `ThemeController.isDarkMode`. Theme controller just flips the value — no `Get.changeTheme*` calls.
- **Files**: `main.dart`, `theme_controller.dart`

### Dialog Dismiss Fix
- **Bug**: `Get.back()` in dialogs clashed with `Get.snackbar()` (FCM notifications) — review dialog wouldn't close.
- **Fix**: All user-facing dialogs use `Navigator.of(context).pop()`. FCM service skips snackbar when dialog is open.
- **Files**: `product_detail_screen.dart`, `profile_sub_screens.dart`, `profile_screen.dart`, `fcm_service.dart`

### Dark Mode Fixes
- Product detail dividers now adapt: `isDark ? Colors.white12 : Color(0xFFE0E0E0)`.
- Review filter chip adapts: dark mode shows white text on 35% amber bg.
- Wishlist screen empty state + item count adapt to dark mode.
- **Files**: `product_detail_screen.dart`, `all_reviews_screen.dart`, `wishlist_screen.dart`

### UI Polish
- Orders tab content uses `key: ValueKey(_activeTab)` for smooth transitions.
- Shop screen Sort & Filter chip has `InkWell` ripple feedback.
- Review list uses `AnimatedSwitcher` for filter/sort transitions.
- **Files**: `profile_sub_screens.dart`, `shop_screen.dart`, `product_detail_screen.dart`

---

## Session Summary — June 29, 2026 (Final Polish)

### Critical Bug Fixes
- Wishlist deadlock, promo discount selectedSubtotal, stock decrement on order, cart variant-aware keys, removeSelectedItems cleanup

### UI Polish
- Search box borders on 7+ pages, category chip borders, admin filter borders, sortChip/FilterChip borders
- Cart pull-to-refresh
- Product images order: main before detail

### Add/Edit Product Redesign
- Tabs: pill-shaped TabBar in AppBar.bottom
- Spacing: 10→16px fields, 20→24px sections
- Image drag-and-drop: reorder + cross-list move, scroll-aware positioning, 100px unified size

### Cleanup
- 5 compile warnings removed, deprecated .opacity→.a, child arg ordering
- 0 errors, 0 warnings in flutter analyze
