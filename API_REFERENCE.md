# Tiny Chicken — API Reference for Postman

> **Important**: This is a Firebase SDK-based Flutter app. It does NOT have a custom REST server.
> What you can test with Postman is the Firebase Firestore REST API and Firebase Cloud Functions HTTP endpoints.

---

## 🔑 Authentication for Postman

Firebase REST API requires authentication. Choose one method:

### Option A: API Key (read-only public access — not recommended for writes)
Add to query params: `?key=AIzaSyCWa0ISo1jIbS7ozxwqMbdTH4jh6Cb2T-M`

### Option B: OAuth 2.0 (full access)
1. Get an access token from Firebase CLI: `firebase auth:print-access-token`
   Or: `gcloud auth application-default print-access-token`
2. Set header: `Authorization: Bearer <token>`

---

## 📦 Base URL

```
https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents
```

---

## 📋 Collections

### Products
| Method | Path | Description |
|--------|------|-------------|
| GET | `/products` | List all products |
| GET | `/products/{productId}` | Get single product |
| POST | `/products` | Create product |
| PATCH | `/products/{productId}` | Update product |
| DELETE | `/products/{productId}` | Delete product |

### Shops
| Method | Path | Description |
|--------|------|-------------|
| GET | `/shops` | List all shops |
| GET | `/shops/{shopId}` | Get single shop |
| POST | `/shops` | Create shop |
| PATCH | `/shops/{shopId}` | Update shop |
| DELETE | `/shops/{shopId}` | Delete shop |

### Categories
| Method | Path | Description |
|--------|------|-------------|
| GET | `/categories` | List all categories |
| POST | `/categories` | Create category |
| PATCH | `/categories/{categoryId}` | Update category |
| DELETE | `/categories/{categoryId}` | Delete category |

### Users
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users` | List all users |
| GET | `/users/{userId}` | Get user profile |
| PATCH | `/users/{userId}` | Update user profile |

### User Cart
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/cart` | Get user's cart items |
| POST | `/users/{userId}/cart` | Add to cart |
| PATCH | `/users/{userId}/cart/{itemId}` | Update cart item |
| DELETE | `/users/{userId}/cart/{itemId}` | Remove from cart |

### User Wishlist
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/wishlist` | Get wishlist |
| POST | `/users/{userId}/wishlist` | Add to wishlist |
| DELETE | `/users/{userId}/wishlist/{itemId}` | Remove from wishlist |

### User Orders
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/orders` | Get user orders |
| GET | `/users/{userId}/orders/{orderId}` | Get single order |
| POST | `/users/{userId}/orders` | Create order |
| PATCH | `/users/{userId}/orders/{orderId}` | Update order status |

### All Orders (admin — cross-user)
| Method | Path | Description |
|--------|------|-------------|
| GET | (use collection group query) | List all orders across users |

### User Addresses
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/addresses` | Get saved addresses |
| POST | `/users/{userId}/addresses` | Add address |
| DELETE | `/users/{userId}/addresses/{addressId}` | Remove address |

### Settings
| Method | Path | Description |
|--------|------|-------------|
| GET | `/settings/admins` | Get admin emails |
| PATCH | `/settings/admins` | Update admin list |
| GET | `/settings/shipping` | Get shipping fee |
| PATCH | `/settings/shipping` | Update shipping fee |

### Promo Codes
| Method | Path | Description |
|--------|------|-------------|
| GET | `/promo_codes` | List all promo codes |
| POST | `/promo_codes` | Create promo code |
| PATCH | `/promo_codes/{codeId}` | Update promo code |
| DELETE | `/promo_codes/{codeId}` | Delete promo code |

### Notifications
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/notifications` | Get user notifications |
| POST | `/users/{userId}/notifications` | Send/inject notification |

### Recently Viewed
| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/{userId}/recently_viewed` | Get recently viewed |
| POST | `/users/{userId}/recently_viewed` | Add to recently viewed |

---

## 📬 Postman Examples

### 1. List all products (GET)
```
GET https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents/products
Authorization: Bearer <token>
```

### 2. Create a product (POST)
```
POST https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents/products
Authorization: Bearer <token>
Content-Type: application/json

{
  "fields": {
    "name": {"stringValue": "Test Product"},
    "price": {"doubleValue": 19.99},
    "originalPrice": {"doubleValue": 19.99},
    "description": {"stringValue": "A test product from Postman"},
    "category": {"stringValue": "Clothing"},
    "images": {"arrayValue": {"values": [
      {"stringValue": "https://picsum.photos/400/400"}
    ]}},
    "stock": {"integerValue": "50"},
    "isFeatured": {"booleanValue": false},
    "isFlashSale": {"booleanValue": false},
    "discountPercent": {"doubleValue": 0},
    "rating": {"doubleValue": 0},
    "reviewCount": {"integerValue": "0"},
    "soldCount": {"integerValue": "0"},
    "sellerId": {"stringValue": "admin"},
    "sellerName": {"stringValue": "Tiny Chicken Official"},
    "sellerAvatar": {"stringValue": "🏪"},
    "sizes": {"arrayValue": {"values": [
      {"stringValue": "S"}, {"stringValue": "M"}, {"stringValue": "L"}, {"stringValue": "XL"}
    ]}},
    "colors": {"arrayValue": {"values": []}},
    "materials": {"arrayValue": {"values": []}},
    "freeShipping": {"booleanValue": false},
    "showSoldCount": {"booleanValue": true},
    "showRating": {"booleanValue": true},
    "showReviewCount": {"booleanValue": true},
    "createdAt": {"timestampValue": "2026-06-29T00:00:00Z"}
  }
}
```

### 3. Update a product (PATCH)
```
PATCH https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents/products/{productId}
Authorization: Bearer <token>
Content-Type: application/json

{
  "fields": {
    "price": {"doubleValue": 24.99},
    "discountPercent": {"doubleValue": 15}
  }
}
```

### 4. Delete a product (DELETE)
```
DELETE https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents/products/{productId}
Authorization: Bearer <token>
```

### 5. Get user orders (GET)
```
GET https://firestore.googleapis.com/v1/projects/tiny-chicken/databases/(default)/documents/users/{userId}/orders
Authorization: Bearer <token>
```

---

## 🔧 Getting an Access Token for Postman

```bash
# Method 1: Firebase CLI
firebase login
firebase auth:print-access-token

# Method 2: gcloud
gcloud auth application-default login
gcloud auth application-default print-access-token

# Method 3: Use a service account (best for automation)
# 1. Go to Firebase Console → Project Settings → Service Accounts
# 2. Generate a new private key (JSON)
# 3. Use the key with a JWT-to-token exchange or a Postman pre-request script
```

---

## ⚠️ Limitations

| What | Works in Postman? |
|------|-------------------|
| Firestore CRUD (products, shops, categories) | ✅ Yes |
| Firestore user subcollections (cart, wishlist) | ✅ Yes |
| Firebase Auth (login, register) | ❌ No — uses Firebase Auth SDK, not REST |
| Firebase Storage (image uploads) | ❌ No — uses Firebase Storage SDK |
| FCM Push Notifications | ❌ No — server-side via Cloud Functions |
| Cloud Functions triggers | ❌ No — triggers, not HTTP endpoints |
