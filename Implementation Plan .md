# Sapo Clone Flutter App — Implementation Plan v3 (Updated)

> [!IMPORTANT]
> **v3 Changes**: Fixed role-based access for Product Detail (Customer ONLY), detailed product images carousel, store list display with inventory, order multi-store splitting logic, search debouncing, cart checkboxes, order expansion/collapse, rating workflow with Confirm Receipt. Based on actual backend API audit with exact endpoints and response shapes.

      {
        "id": 1,
        "productImageUrl": "...",
        "isMainImage": true
      },
      {
        "id": 2,
        "productImageUrl": "...",
        "isMainImage": false
      }
     - Backend geocodes `shippingAddress` using Goong API → gets `(lat, lng)`
     - For each product in `orderDetails`:
       - If item has `storeId`: use it
       - Else: Query `findNearestStoreWithStock(productId, quantity, lat, lng, companyId)` → get nearest store
     - Group all items by `storeId`
  3. Backend creates ONE Order per store, returns `List<OrderResponse>`
  4. **FE must handle**: Multiple orders in single response, calculate total across all orders, display each order with its `storeId` and `storeName`

### Product Images
- **Response**: `ProductImageListResponse` with:
  ```json
  {
    "mainImage": { "id": 1, "imageUrl": "...", "isMain": true },
    "images": [
      { "id": 1, "imageUrl": "...", "isMain": true },
      { "id": 2, "imageUrl": "...", "isMain": false },
      { "id": 3, "imageUrl": "...", "isMain": false }
    ]
  }
  ```
- **FE Must**: Display as horizontal carousel/slider, users can swipe left/right
- **Endpoint**: `GET /api/product/{productId}/images`

### Store List with Inventory
- **Endpoint**: `GET /api/store/product/{productId}?page=0&size=10`
- **Response**: `Page<StoreWithInventoryResponse>` with:
  ```json
  {
    "content": [
      {
        "id": 1,
        "storeName": "Store A",
        "storeAddress": "...",
        "latitude": 10.123,
        "longitude": 105.456,
        "inventoryQuantity": 5  // current inventory at this store
      },
      ...
    ],
    "totalPages": 1,
    "number": 0,
    "size": 10,
    "totalElements": 2
  }
  ```
- **FE Must**: Show list below product detail, each store has quantity badge

### Ratings with Product Detail
- **Endpoint**: `GET /api/rating/product/{productId}?page=0&size=10` (lazy load)
- **Response**: `Page<RatingResponse>` with:
  ```json
  {
    "content": [
      {
        "id": 1,
        "rating": 5,
        "comment": "Great product!",
        "userId": 10,
        "userFullName": "John Doe",
        "updatedAt": "2026-04-28T10:30:00",
        "productId": 5
      }
    ]
  }
  ```
- **FE Must**: Load on product detail view init, show top 5 ratings

### Rating Creation (Post-Delivery)
- **Prerequisites**:
  - Order status must be 3 (DELIVERED/COMPLETED)
  - User must have purchased that product (checked by BE)
  - User can rate multiple times but not more than quantity purchased
- **Endpoint**: `POST /api/rating` with:
  ```json
  {
    "productId": 5,
    "rating": 4,
    "comment": "Good quality"
  }
  ```
- **Response**: `RatingResponse` (same as above)
- **FE Workflow**:
  1. Order detail expanded + status=3 → show "Confirm Receipt" button
  2. User clicks "Confirm Receipt" → calls `PATCH /api/order/{orderId}/status` with `status=3`
  3. Order expansion now shows list of products with "Rate" button per product
  4. User clicks "Rate" → open rating dialog
  5. User submits rating → calls `POST /api/rating`
  6. Show success toast, update ratings list below (or refresh on next open)

### Order Status & Payment Status
- **Status Values**:
  - 0: PENDING (customer just ordered, awaiting employee confirmation)
  - 1: CONFIRMED (employee confirmed order)
  - 2: SHIPPING (order in delivery)
  - 3: COMPLETED/DELIVERED (delivered to customer)
  - 4: CANCELLED (cancelled by customer or staff)
- **Payment Status Values**:
  - 0: UNPAID
  - 1: PAID
  - 2: FAILED
  - 3: REFUNDED

---

## 2. Role Hierarchy & Permission Matrix (FIXED)

### Account Creation Hierarchy
```
ADMIN → can create MANAGER (needs companyId + storeId)
MANAGER → can create EMPLOYEE (auto-inherits manager's storeId + companyId)
EMPLOYEE → can create CUSTOMER (auto-inherits storeId + companyId)
Public Signup → always CUSTOMER (default roleId, no roleId/storeId picker)
```

### Permission Matrix

| Feature | CUSTOMER | EMPLOYEE | MANAGER | ADMIN |
|---------|----------|----------|---------|-------|
| Browse products (by companyId) | ✅ | ✅ | ✅ | ❌ |
| View product detail (customer view) | ✅ | ❌ | ❌ | ❌ |
| View product detail (manage view) | ❌ | ✅ | ✅ | ❌ |
| Create product | ❌ | ❌ | ✅ | ❌ |
| Update product info | ❌ | ❌ | ✅ | ❌ |
| Change product status | ❌ | ❌ | ✅ | ❌ |
| Upload product image | ❌ | ❌ | ✅ | ❌ |
| Barcode scanner | ✅ | ✅ | ✅ | ❌ |
| **Cart (add/update/remove/clear)** | **✅** | **❌** | **❌** | **❌** |
| Create order (online, from cart) | ✅ | ❌ | ❌ | ❌ |
| Create order (direct/POS sale) | ❌ | ✅ | ✅ | ❌ |
| Update order (PENDING only) | ❌ | ✅ | ✅ | ❌ |
| View order list | ✅ (own) | ✅ | ✅ | ❌ |
| View order detail | ✅ (own) | ✅ | ✅ | ❌ |
| Change order status | ✅ (COMPLETED/CANCELLED only) | ✅ | ✅ | ❌ |
| View financial report | ❌ | ❌ | ✅ | ❌ |
| Create PurchaseOrder (nhập hàng) | ❌ | ✅ | ✅ | ❌ |
| View PurchaseOrder list | ❌ | ✅ | ✅ | ❌ |
| View PurchaseOrder report | ❌ | ❌ | ✅ | ❌ |
| Create/update promotions | ❌ | ❌ | ✅ | ❌ |
| Manage inventory | ❌ | ✅ (view) | ✅ | ❌ |
| Rating (create/update/delete) | ✅ | ❌ | ❌ | ❌ |
| View ratings | ✅ | ✅ | ✅ | ❌ |
| Update profile | ✅ | ✅ | ✅ | ✅ |
| Change password | ✅ | ✅ | ✅ | ✅ |
| Create user account | ❌ | ✅ (CUSTOMER) | ✅ (EMPLOYEE) | ✅ (MANAGER) |
| Manage users | ❌ | ❌ | ✅ | ✅ |
| Create/manage stores | ❌ | ❌ | ❌ | ✅ |
| Create/manage companies | ❌ | ❌ | ❌ | ✅ |

## 2. Role Hierarchy & Permission Matrix (FIXED)

### Account Creation Hierarchy
```
ADMIN → can create MANAGER (needs companyId + storeId)
MANAGER → can create EMPLOYEE (auto-inherits manager's storeId + companyId)
EMPLOYEE → can create CUSTOMER (auto-inherits storeId + companyId)
Public Signup → always CUSTOMER (default roleId, no roleId/storeId picker)
```

### Permission Matrix (CORRECTED)

| Feature | CUSTOMER | EMPLOYEE | MANAGER | ADMIN |
|---------|----------|----------|---------|-------|
| Browse products (by companyId) | ✅ | ❌ (use manage view) | ❌ (use manage view) | ❌ |
| **View product detail (customer view)** | **✅** | **❌** | **❌** | **❌** |
| **View product detail (manage view)** | **❌** | **✅** | **✅** | **❌** |
| Create product | ❌ | ❌ | ✅ | ❌ |
| Update product info | ❌ | ❌ | ✅ | ❌ |
| Change product status | ❌ | ❌ | ✅ | ❌ |
| Upload product image | ❌ | ❌ | ✅ | ❌ |
| Barcode scanner | ✅ | ✅ | ✅ | ❌ |
| **Cart (add/update/remove/clear)** | **✅** | **❌** | **❌** | **❌** |
| Create order (online, from cart) | ✅ | ❌ | ❌ | ❌ |
| Create order (direct/POS sale) | ❌ | ✅ | ✅ | ❌ |
| Update order (PENDING only) | ❌ | ✅ | ✅ | ❌ |
| View order list | ✅ (own) | ✅ | ✅ | ❌ |
| View order detail | ✅ (own) | ✅ | ✅ | ❌ |
| Change order status | ✅ (COMPLETED/CANCELLED only) | ✅ | ✅ | ❌ |
| View financial report | ❌ | ❌ | ✅ | ❌ |
| Create PurchaseOrder (nhập hàng) | ❌ | ✅ | ✅ | ❌ |
| View PurchaseOrder list | ❌ | ✅ | ✅ | ❌ |
| View PurchaseOrder report | ❌ | ❌ | ✅ | ❌ |
| Create/update promotions | ❌ | ❌ | ✅ | ❌ |
| Manage inventory | ❌ | ✅ (view) | ✅ | ❌ |
| Rating (create/update/delete) | ✅ | ❌ | ❌ | ❌ |
| View ratings | ✅ | ✅ | ✅ | ❌ |
| Update profile | ✅ | ✅ | ✅ | ✅ |
| Change password | ✅ | ✅ | ✅ | ✅ |
| Create user account | ❌ | ✅ (CUSTOMER) | ✅ (EMPLOYEE) | ✅ (MANAGER) |
| Manage users | ❌ | ❌ | ✅ | ✅ |
| Create/manage stores | ❌ | ❌ | ❌ | ✅ |
| Create/manage companies | ❌ | ❌ | ❌ | ✅ |

### Key Fixes from v2
1. **Product Detail**: CUSTOMER sees customer view only. EMPLOYEE/MANAGER see manage view (different endpoint). No mixed access.
2. **Product Browsing**: CUSTOMER uses `/api/product/store` (by company). EMPLOYEE/MANAGER use `/api/product` (full management view).
3. **Product Images**: Now part of product detail response, displayed as carousel.
4. **Store List**: New feature below product detail showing inventory per store.
5. **Ratings**: Lazy-loaded in product detail, integrated into order detail (post-delivery).
6. **Order Splitting**: Single API call returns List<OrderResponse>, FE must handle multiple orders.
7. **Search Debouncing**: 1-2s delay before API call (not per keystroke).
8. **Cart Checkboxes**: Select items before checkout, especially important for split orders.

---

## 3. UI Flows Per Role

### CUSTOMER Flow (E-commerce style, like Shopee)
```
Login/Signup → Product Grid (by companyId)
                ├── Search bar (keyword search)
                ├── Barcode scanner button
                ├── Cart icon with badge
                ├── User menu (profile, password, orders, ratings)
                │
                ├── Product Detail → Add to Cart → Cart Screen → Checkout → Order Created
                │                                                            └── Payment confirmation
                ├── My Orders → Order Detail → Confirm Receipt / Cancel
                └── My Ratings → Rate products from completed orders
```

### EMPLOYEE Flow (POS/Management lite)
```
Login → Dashboard (Sidebar navigation)
         ├── Products (browse, barcode scan — NO create/edit)
         ├── Orders (list, create direct POS sale, update status)
         ├── Purchase Orders (create nhập hàng, view list)
         ├── Inventory (view stock)
         ├── Create Customer Account
         └── Profile / Password
```

### MANAGER Flow (Full management)
```
Login → Dashboard (Sidebar + reports)
         ├── Products (full CRUD, images, barcode)
         ├── Orders (full management + financial reports)
         ├── Purchase Orders (full + reports)
         ├── Inventory (full view)
         ├── Promotions (create product/order promotions)
         ├── Ratings (moderate)
         ├── Users (manage employees + customers)
         ├── Reports (revenue, sales statistics)
         └── Profile / Password
```

### ADMIN Flow (System administration only)
```
Login → Admin Panel
         ├── Companies (CRUD)
         ├── Stores (CRUD)
         ├── Users (create MANAGER accounts with storeId+companyId)
         └── Profile / Password
```

### CUSTOMER Flow (E-commerce style, like Shopee)
```
Login/Signup → Product Grid (by companyId)
                ├── Search bar (keyword search, 1-2s debounce)
                ├── Barcode scanner button
                ├── Cart icon with badge
                ├── User menu (profile, password, orders, ratings)
                │
                ├── Product Detail (CUSTOMER view ONLY)
                │   ├── Image carousel (left/right swipe)
                │   ├── Price, rating stars, description
                │   ├── Store list (with inventory quantity per store)
                │   ├── "Add to Cart" button → success toast
                │   └── "Buy Now" button → checkout immediately
                │
                ├── Cart Screen (with checkboxes)
                │   ├── Checkbox per item (Select All option)
                │   ├── Selected items total
                │   └── Checkout button → POST /api/order → get List<OrderResponse>
                │
                ├── My Orders (with expansion)
                │   ├── Order list (status filter)
                │   ├── Each order shows storeId, storeName, total, status
                │   └── Click to expand → shows items, address, "Confirm Receipt" button (if status=3)
                │       └── If expanded + status=3: Rate button per product
                │
                └── My Ratings (history of ratings user has made)
```

### EMPLOYEE Flow (POS/Management lite)
```
Login → Dashboard (Sidebar navigation)
         ├── Products (browse manage view, barcode scan — NO create/edit)
         ├── Orders (list, create direct POS sale, update status)
         ├── Purchase Orders (create nhập hàng, view list)
         ├── Inventory (view stock)
         ├── Create Customer Account
         └── Profile / Password
```

### MANAGER Flow (Full management)
```
Login → Dashboard (Sidebar + reports)
         ├── Products (full CRUD, images, barcode)
         ├── Orders (full management + financial reports)
         ├── Purchase Orders (full + reports)
         ├── Inventory (full view)
         ├── Promotions (create product/order promotions)
         ├── Ratings (moderate)
         ├── Users (manage employees + customers)
         ├── Reports (revenue, sales statistics)
         └── Profile / Password
```

### ADMIN Flow (System administration only)
```
Login → Admin Panel
         ├── Companies (CRUD)
         ├── Stores (CRUD)
         ├── Users (create MANAGER accounts with storeId+companyId)
         └── Profile / Password
```

---

## 4. Detailed Screen Specifications with API Contracts

### Screen: Product Detail (CUSTOMER)
**File**: `Ui/Screens/customer/product_detail_screen.dart`

**Data Flow**:
1. User taps product card from grid → pass `ProductResponse` to this screen
2. On init: fetch images + ratings lazily
3. Display: images carousel, price, rating stars, description, store list, buttons

**API Calls**:
```
1. GET /api/product/{id}/customer
   Response: ProductResponse
   
2. GET /api/product/{id}/images
   Response: ProductImageListResponse {
     mainImage: ProductImageResponse,
     images: List<ProductImageResponse>
   }
   
3. GET /api/rating/product/{id}?page=0&size=5
   Response: Page<RatingResponse> {
     content: List<RatingResponse>,
     totalPages, totalElements
   }
   
4. GET /api/store/product/{id}?page=0&size=10
   Response: Page<StoreWithInventoryResponse> {
     id, storeName, storeAddress, latitude, longitude, quantity
   }
```

**UI Layout**:
```
[Image Carousel - swipe left/right for multiple images]
[Star Rating] [Price]
[Description]
[Divider]

[Store Availability - horizontal scroll or list]
  Store Name | Address | Qty: 5
  Store Name | Address | Qty: 10
  ...

[Recent Ratings - lazy load]
  ⭐⭐⭐⭐⭐ John Doe - "Great product"
  ⭐⭐⭐⭐  Jane Doe - "Good quality"
  ...

[Bottom Bar]
[Add to Cart Button] [Buy Now Button]
```

**Key Implementation Details**:
- Image carousel: use `PageView` with manual dot indicators
- Store list: `ListView.builder` with quantity badge
- Ratings: initially load page 0 size 5, implement "Load More" if needed
- Buttons:
  - "Add to Cart": POST /api/cart/items with productId, quantity=1 → show success toast
  - "Buy Now": Create order from this product → checkout screen → multi-order handling

---

### Screen: Product Detail (MANAGE - for EMPLOYEE/MANAGER)
**File**: `Ui/Screens/staff/product_detail_screen.dart`

**Data Flow**:
1. User taps product card → pass `ProductResponse` to this screen
2. On init: fetch full product details for management
3. Display: all product fields, images, inventory per store, create/edit buttons

**API Calls**:
```
1. GET /api/product/{id}/manage
   Response: ProductResponse (with all fields)
   
2. GET /api/product/{id}/images
   Response: ProductImageListResponse
   
3. GET /api/product/{id}/inventory/{storeId}
   Response: ProductInventoryResponse
```

**Key Differences from Customer View**:
- Edit/Delete buttons (MANAGER only)
- Image upload/manage buttons (MANAGER only)
- Inventory table by store
- No "Add to Cart" / "Buy Now" buttons
- No customer ratings section

---

### Screen: Search with Debouncing
**File**: `Ui/Screens/customer/customer_home_screen.dart`

**Implementation**:
```dart
// Use debounce timer
Timer? _searchTimer;

void _onSearchChanged(String query) {
  _searchTimer?.cancel();
  _searchTimer = Timer(const Duration(milliseconds: 1500), () {
    // Call API after 1.5s of no input
    context.read<ProductProvider>().searchProducts(query);
  });
}

// In TextField:
TextField(
  onChanged: _onSearchChanged,
  decoration: InputDecoration(
    hintText: 'Search products...',
    prefixIcon: Icon(Icons.search),
  ),
)
```

**API Endpoint**:
```
GET /api/product?keyword={query}&page=0&size=20
Response: Page<ProductResponse>
```

---

### Screen: Cart with Checkboxes
**File**: `Ui/Screens/customer/cart_screen.dart`

**Data Structure**:
```dart
class CartItemWithSelection {
  final CartItemResponse item;
  bool isSelected;
}

// In CartProvider:
List<CartItemWithSelection> itemsWithSelection = [];
bool get allSelected => itemsWithSelection.every((e) => e.isSelected);
bool get hasSelected => itemsWithSelection.any((e) => e.isSelected);
double get selectedTotal => itemsWithSelection
    .where((e) => e.isSelected)
    .fold(0, (sum, e) => sum + (e.item.subtotal ?? 0));
```

**UI Layout**:
```
[Select All Checkbox]

[For each item:]
  [Checkbox] [Product Image] [Name] [Price] [Qty +/-] [Remove]

[Summary]
  Selected: 3 items
  Total: 500,000 VND
  
[Checkout Button] - only enabled if hasSelected
```

**Checkout Flow** (after Checkout button click):
1. Collect selected items into `OrderCreateDTO`
2. POST /api/order → get `List<OrderResponse>`
3. If 1 order: show single order confirmation
4. If N orders: show "Order(s) created" with expandable list of orders
5. Each order shows: storeId, storeName, items, total
6. Option to proceed to payment per order or all at once

---

### Screen: My Orders (Customer)
**File**: `Ui/Screens/customer/my_orders_screen.dart`

**Data Flow**:
1. On init: fetch orders with status filter (PENDING, CONFIRMED, SHIPPING, COMPLETED, CANCELLED)
2. Display as list with status chips
3. Each order can be expanded to show full details

**API Calls**:
```
GET /api/order?status={status}&page=0&size=20&keyword=
Response: Page<OrderListResponse> {
  id, storeId, storeName, status, totalAmount, paymentMethod,
  paymentStatus, createdAt, customerName
}
```

**Expansion Behavior**:
```
[Order Card - Collapsed]
┌─────────────────────────────────┐
│ Order #123 (storeId: 5)         │
│ Store Name: "Store A"           │ ← NEW: Show store name
│ Status: [SHIPPING]              │
│ Total: 500,000 VND              │
│ 2026-04-28 10:30                │
│ [Expand Arrow ▼]                │
└─────────────────────────────────┘

[Order Card - Expanded]
┌─────────────────────────────────┐
│ Order #123 (storeId: 5)         │
│ Store Name: "Store A"           │
│ Status: [SHIPPING]              │
│ [Collapse Arrow ▲]              │
├─────────────────────────────────┤
│ Items:                          │
│  • Product A × 2 = 300,000      │
│  • Product B × 1 = 200,000      │
│ Subtotal: 500,000               │
│ Discount: -50,000               │
│ Final: 450,000                  │
│ Shipping: 123 Main St           │
│ Note: Leave at door            │
│                                 │
│ [If status=SHIPPING]           │
│ [Confirm Receipt Button]        │
│                                 │
│ [If status=COMPLETED]          │
│ [Rate Products Section]        │
│   Product A [⭐⭐⭐⭐⭐] [Comment] [Submit]
│   Product B [⭐⭐⭐⭐]  [Comment] [Submit]
└─────────────────────────────────┘
```

**Key Implementation Details**:
- Use `ExpansionTile` or `GestureDetector` + `AnimatedContainer` for expand/collapse
- On expand: fetch full `OrderResponse` via `GET /api/order/{id}`
- "Confirm Receipt" button (status=SHIPPING): calls `PATCH /api/order/{id}/status` with status=3
- After confirming: show rating widgets for products in that order

---

### Rating Widget (in Order Detail)
**File**: `Ui/Widgets/rating_input_widget.dart`

**Structure**:
```dart
class RatingInputWidget extends StatefulWidget {
  final int productId;
  final String productName;
  final Function(RatingCreateDTO) onSubmit;
  final Function()? onCancel;
  
  // Rating stars: 1-5
  // Comment textarea
  // Submit button
}
```

**API Call**:
```
POST /api/rating
Body: RatingCreateDTO {
  productId, rating (1-5), comment
}
Response: RatingResponse
```

**UI Pattern**:
```
[Product Name: "Product A"]
[Star Rating Selector: ⭐⭐⭐⭐⭐]
[Comment TextArea:]
  "Type your review..."

[Cancel] [Submit Rating]
```

---

## 5. Current Project Status (v3)

| File | Status | Notes |
|------|--------|-------|
| `pubspec.yaml` | ✅ Fixed | dio, provider, json_annotation |
| `main.dart` | ✅ Done | Routes to customer/staff/admin shells by role |
| `data/result.dart` | ✅ OK | |
| `models/api_response.dart` | ✅ OK | |
| `models/page_response.dart` | ✅ OK | |
| `models/auth.dart` | ✅ OK | Matches backend UserResponse |
| `models/product.dart` | ✅ OK | Matches backend ProductResponse |
| `models/company.dart` | ✅ OK | |
| `services/api_service.dart` | ✅ OK | |
| `services/auth_service.dart` | ✅ Done | Public signup only sends customer-safe fields |
| `services/company_service.dart` | ✅ OK | |
| `Providers/auth_provider.dart` | ✅ Done | Signup/login flow aligned with backend contract |
| `Providers/product_provider.dart` | ✅ Done | Detail loading, debounce search, rating helpers |
| `Ui/Screens/login_screen.dart` | ✅ OK | Company picker done |
| `Ui/Screens/signup_screen.dart` | ✅ Done | Public signup uses company picker and customer defaults |
| `Ui/Screens/home_screen.dart` | ✅ Removed | Replaced by role shells and root navigator |
| `Ui/Widgets/*` | ✅ OK | 6 widgets ready |

---

## 4. Implementation Phases

### Phase 0: Fix Foundation ✅ DONE
- [x] Fix pubspec.yaml
- [x] Fix models (auth, product)
- [x] Create api_response, page_response
- [x] Create company model + service

### Phase 1: Auth + Role-Based Routing (REVISED)

| # | Task | File | Description |
|---|------|------|-------------|
| 1.1 | Fix signup screen | `Ui/Screens/signup_screen.dart` | Remove roleId/storeId. Use company picker like login. Public signup = CUSTOMER only. |
| 1.2 | Fix auth_service | `services/auth_service.dart` | Public signup sends default roleId (from BE), no storeId. Add separate `createUser()` for internal use. |
| 1.3 | Fix auth_provider | `Providers/auth_provider.dart` | Simplify public signup params. |
| 1.4 | Rewrite main.dart | `main.dart` | Route based on roleName: CUSTOMER→CustomerShell, EMPLOYEE→EmployeeShell, MANAGER→ManagerShell, ADMIN→AdminShell |
| 1.5 | Customer shell | `Ui/Screens/customer/customer_shell.dart` | Shopee-style bottom nav: Home, Cart, Orders, Profile |
| 1.6 | Staff shell | `Ui/Screens/staff/staff_shell.dart` | Sidebar nav for EMPLOYEE + MANAGER (show/hide by role) |
| 1.7 | Admin shell | `Ui/Screens/admin/admin_shell.dart` | Sidebar: Companies, Stores, Users, Profile |
| 1.8 | Profile screen | `Ui/Screens/common/profile_screen.dart` | Update profile (PUT /api/user/profile). All roles. |
| 1.9 | Change password | `Ui/Screens/common/change_password_screen.dart` | PATCH /api/user/password. All roles. |
| 1.10 | User service | `services/user_service.dart` | createUser, updateProfile, changePassword, getList, updateStatus |

### Phase 2: Customer — Product Browsing + Cart

| # | Task | File | Description |
|---|------|------|-------------|
| 2.1 | Product service | `services/product_service.dart` | getList (by company), getProductForCustomer, barcode lookup |
| 2.2 | Product provider | `Providers/product_provider.dart` | Full impl: list, search, pagination, barcode |
| 2.3 | Customer home | `Ui/Screens/customer/customer_home_screen.dart` | Product grid, search bar, barcode scanner button, category filter |
| 2.4 | Product detail (customer) | `Ui/Screens/customer/product_detail_screen.dart` | Images, price, rating stars, add-to-cart button |
| 2.5 | Cart model | `models/cart.dart` | CartResponse, CartItemResponse |
| 2.6 | Cart service | `services/cart_service.dart` | addItem, updateQuantity, removeItem, getCart, clearCart |
| 2.7 | Cart provider | `Providers/cart_provider.dart` | Cart state, item count badge, total |
| 2.8 | Cart screen | `Ui/Screens/customer/cart_screen.dart` | Item list, qty control, remove, total summary, checkout button |
| 2.9 | Barcode scanner | `Ui/Screens/common/barcode_scanner_screen.dart` | Camera access, scan barcode, find product by barcode |
| 2.10 | Product card widget | `Ui/Widgets/product_item_card.dart` | Grid card: image, name, price, rating |
| 2.11 | Cart item widget | `Ui/Widgets/cart_item_tile.dart` | Product info, qty +/-, remove, subtotal |

> [!NOTE]
> Barcode scanner requires `mobile_scanner` package in pubspec.yaml + camera permission.

### Phase 3: Customer — Order Flow

| # | Task | File | Description |
|---|------|------|-------------|
| 3.1 | Order model | `models/order.dart` | OrderResponse, OrderListResponse, OrderItemResponse |
| 3.2 | Order service | `services/order_service.dart` | createOrder, getList, getOrder, changeStatus, changePayment |
| 3.3 | Order provider | `Providers/order_provider.dart` | Order list, filters, create from cart |
| 3.4 | Checkout screen | `Ui/Screens/customer/checkout_screen.dart` | Cart summary → shipping address → payment method → confirm → POST /api/order |
| 3.5 | Order list (customer) | `Ui/Screens/customer/my_orders_screen.dart` | List of user's orders, filter by status |
| 3.6 | Order detail (customer) | `Ui/Screens/customer/order_detail_screen.dart` | Items, total, status, confirm receipt / cancel buttons |
| 3.7 | Order item widget | `Ui/Widgets/order_item_tile.dart` | Product + qty + price in order |

### Phase 4: Customer — Rating

| # | Task | File | Description |
|---|------|------|-------------|
| 4.1 | Rating model | `models/rating.dart` | RatingResponse |
| 4.2 | Rating service | `services/rating_service.dart` | create, update, getByProduct, getByUser, delete |
| 4.3 | Rating provider | `Providers/rating_provider.dart` | Rating state |
| 4.4 | Rating widget | `Ui/Widgets/rating_item_card.dart` | Star display + comment |
| 4.5 | My ratings screen | `Ui/Screens/customer/my_ratings_screen.dart` | User's rating history |

### Phase 5: Employee/Manager — Product Management + POS

| # | Task | File | Description |
|---|------|------|-------------|
| 5.1 | Product list (manage) | `Ui/Screens/staff/product_list_screen.dart` | Table view, search, filter, status badges |
| 5.2 | Product detail (manage) | `Ui/Screens/staff/product_detail_screen.dart` | Full fields, inventory, images |
| 5.3 | Product form (MANAGER only) | `Ui/Screens/staff/product_form_screen.dart` | Create/edit product |
| 5.4 | Product image service | `services/product_image_service.dart` | Upload, set main, delete |
| 5.5 | POS order screen | `Ui/Screens/staff/pos_order_screen.dart` | Direct sale: select products → create order (auto COMPLETED) |
| 5.6 | Order list (staff) | `Ui/Screens/staff/order_list_screen.dart` | All orders, filter, update status |
| 5.7 | Order detail (staff) | `Ui/Screens/staff/order_detail_screen.dart` | Full detail, change status/payment |
| 5.8 | PurchaseOrder model | `models/purchase_order.dart` | PurchaseOrderResponse |
| 5.9 | PurchaseOrder service | `services/purchase_order_service.dart` | create, getList, updateStatus, report |
| 5.10 | PurchaseOrder provider | `Providers/purchase_order_provider.dart` | PO state |
| 5.11 | PO list screen | `Ui/Screens/staff/po_list_screen.dart` | PO list, create, status |
| 5.12 | PO create screen | `Ui/Screens/staff/po_create_screen.dart` | Select products + qty → create PO |
| 5.13 | Inventory model | `models/inventory.dart` | InventoryByStoreResponse, ProductInventoryResponse |
| 5.14 | Inventory service | `services/inventory_service.dart` | getInventory, getByStore |
| 5.15 | Inventory screen | `Ui/Screens/staff/inventory_screen.dart` | Stock table by product |
| 5.16 | Create user screen (staff) | `Ui/Screens/staff/create_user_screen.dart` | MANAGER creates EMPLOYEE, EMPLOYEE creates CUSTOMER |

### Phase 6: Manager-Only Features

| # | Task | File | Description |
|---|------|------|-------------|
| 6.1 | Financial report screen | `Ui/Screens/staff/financial_report_screen.dart` | Order report: revenue, date range filter |
| 6.2 | Product report screen | `Ui/Screens/staff/product_report_screen.dart` | Product sales data |
| 6.3 | PO report screen | `Ui/Screens/staff/po_report_screen.dart` | Purchase spending |
| 6.4 | Promotion model | `models/promotion.dart` | PromotionResponse, PromotionListResponse |
| 6.5 | Promotion service | `services/promotion_service.dart` | createProduct/Order promo, update, status, list |
| 6.6 | Promotion provider | `Providers/promotion_provider.dart` | Promotion state |
| 6.7 | Promotion screen | `Ui/Screens/staff/promotion_screen.dart` | List + create/edit promotions |
| 6.8 | User management screen | `Ui/Screens/staff/user_management_screen.dart` | User list, status change |

### Phase 7: Admin Features

| # | Task | File | Description |
|---|------|------|-------------|
| 7.1 | Store model | `models/store.dart` | StoreResponse |
| 7.2 | Store service | `services/store_service.dart` | CRUD |
| 7.3 | Company screen | `Ui/Screens/admin/company_screen.dart` | Company list + create/edit |
| 7.4 | Store screen | `Ui/Screens/admin/store_screen.dart` | Store list + create/edit |
| 7.5 | Create manager screen | `Ui/Screens/admin/create_manager_screen.dart` | Create MANAGER (needs company picker + store picker) |
| 7.6 | Admin user list | `Ui/Screens/admin/admin_user_list_screen.dart` | All managers list |

### Phase 8: Polish
- Dark mode theme
- Responsive layout (tablet/desktop)
- Toast/Snackbar consistency
- Smooth page transitions
- Unit + widget tests

---

## 5. Current Project Status (v3)

| File | Status | Notes |
|------|--------|-------|
| `pubspec.yaml` | ✅ Fixed | dio, provider, json_annotation |
| `main.dart` | ✅ OK | Routes based on role |
| `data/result.dart` | ✅ OK | |
| `models/api_response.dart` | ✅ OK | |
| `models/page_response.dart` | ✅ OK | |
| `models/auth.dart` | ✅ OK | Matches backend UserResponse |
| `models/product.dart` | ✅ OK | Matches backend ProductResponse |
| `models/order.dart` | ✅ Done | Handles storeId, storeName, and List<OrderResponse> |
| `models/rating.dart` | ✅ Done | RatingResponse and DTOs |
| `services/api_service.dart` | ✅ OK | |
| `services/auth_service.dart` | ✅ OK | |
| `services/product_service.dart` | ✅ Done | Product images, product detail, ratings helpers |
| `services/order_service.dart` | ✅ Done | Handles List<OrderResponse> return |
| `services/rating_service.dart` | ✅ Done | Create, update, getByProduct, getByUser, delete |
| `Providers/product_provider.dart` | ✅ Done | Product detail helpers, search debounce, image/store/rating loaders |
| `Providers/cart_provider.dart` | ✅ Done | Item selection, selected totals, clear/select helpers |
| `Providers/order_provider.dart` | ✅ Done | Multi-order create, expand/collapse, status changes |
| `Providers/rating_provider.dart` | ✅ Done | Create/update/delete, user/product ratings, pagination |
| `Ui/Screens/customer/product_detail_screen.dart` | ✅ Done | Store list, image carousel, ratings, Buy Now button |
| `Ui/Screens/customer/cart_screen.dart` | ✅ Done | Checkboxes, multi-order checkout handling |
| `Ui/Screens/customer/my_orders_screen.dart` | ✅ Done | Expansion, store info, confirm receipt shortcut |
| `Ui/Screens/customer/order_detail_screen.dart` | ✅ Done | Confirm Receipt button, rating widgets, store info |
| `Ui/Widgets/image_carousel_widget.dart` | ✅ Done | Horizontal image gallery |
| `Ui/Widgets/store_list_widget.dart` | ✅ Done | Store inventory list |
| `Ui/Widgets/rating_input_widget.dart` | ✅ Done | Rating input dialog with edit mode |
| `Ui/Widgets/rating_display_widget.dart` | ✅ Done | Rating display card |

---

## 6. Implementation Phases (REVISED v3)

### Phase 2: Customer — Product Browsing + Cart (WITH FIXES)

| # | Task | File | Status | Description |
|---|------|------|--------|-------------|
| 2.0 | **[FIX]** Product Detail access control | `product_detail_screen.dart` | ✅ Done | Uses `/api/product/{id}/customer` for CUSTOMER role |
| 2.1 | Image carousel widget | `Ui/Widgets/image_carousel_widget.dart` | ✅ Done | Horizontal scrolling image gallery using `PageView` |
| 2.2 | Store list widget | `Ui/Widgets/store_list_widget.dart` | ✅ Done | Show stores with inventory quantity badges |
| 2.3 | Product images service | `services/product_service.dart` | ✅ Done | `getProductImages(productId)` → `GET /api/product/{id}/images` |
| 2.4 | Product detail service | `services/product_service.dart` | ✅ Done | `getProductByIdForCustomer(id)` → `GET /api/product/{id}/customer` |
| 2.5 | Store service | `services/store_service.dart` | ✅ Done | `getStoresByProduct(productId, page, size)` → `GET /api/store/product/{id}` |
| 2.6 | Ratings service | `services/rating_service.dart` | ✅ Done | `getByProduct(productId, page, size)` → `GET /api/rating/product/{id}` |
| 2.7 | Product provider | `Providers/product_provider.dart` | ✅ Done | Debounced search, product detail loaders, image/store/rating helpers |
| 2.8 | Search debouncing | `Ui/Screens/customer/customer_home_screen.dart` | ✅ Done | 1-2s debounce before API call |
| 2.9 | Product detail screen | `Ui/Screens/customer/product_detail_screen.dart` | ✅ Done | Image carousel, store list, ratings, "Buy Now" button |
| 2.10 | Cart service update | `services/cart_service.dart` | ✅ OK | Keep existing |
| 2.11 | Cart provider update | `Providers/cart_provider.dart` | ✅ Done | Selection state, selected totals, selected-item helpers |
| 2.12 | Cart screen update | `Ui/Screens/customer/cart_screen.dart` | ✅ Done | Checkboxes per item, Select All, selected total, checkout gating |
| 2.13 | Barcode scanner | `Ui/Screens/common/barcode_scanner_screen.dart` | ✅ Done | Camera access, scan barcode, return barcode string |

**Priority Issues to Fix in Phase 2**:
1. ✅ Product Detail now shows carousel
2. ✅ Product Detail now shows store list
3. ✅ Product Detail now lazy-loads ratings
4. ✅ Product Detail now has Buy Now alongside Add to Cart
5. ✅ Search now uses debounce instead of per-keystroke calls
6. ✅ Customer vs manage product detail access now uses the correct endpoint
7. ✅ Cart now supports per-item selection and checkout gating
8. ✅ Checkout now handles `List<OrderResponse>` and multi-order confirmation

---

### Phase 3: Customer — Order Flow (WITH FIXES)

| # | Task | File | Status | Description |
|---|------|------|--------|-------------|
| 3.1 | Order model update | `models/order.dart` | ✅ Done | Added `storeId`, `storeName`, and multi-order response handling |
| 3.2 | Rating model | `models/rating.dart` | ✅ Done | `RatingResponse` with all fields |
| 3.3 | Order service update | `services/order_service.dart` | ✅ Done | Handles `List<OrderResponse>` return from `createOrder()` |
| 3.4 | Order provider update | `Providers/order_provider.dart` | ✅ Done | Expanded order state, multi-order create, status changes |
| 3.5 | Checkout screen | `Ui/Screens/customer/checkout_screen.dart` | ✅ Done | Multi-order response, confirmation block, selected items only |
| 3.6 | Order list (customer) | `Ui/Screens/customer/my_orders_screen.dart` | ✅ Done | Store info display and expandable rows |
| 3.7 | Order detail screen | `Ui/Screens/customer/order_detail_screen.dart` | ✅ Done | Full details, Confirm Receipt, rating section |
| 3.8 | Order expand/collapse | `Ui/Screens/customer/my_orders_screen.dart` | ✅ Done | Custom expandable row with arrow icon |

**Priority Issues to Fix in Phase 3**:
1. ✅ Order list now shows `storeId`/`storeName`
2. ✅ Order list now expands/collapses
3. ✅ Order detail now loads full info on demand
4. ✅ Order detail now shows "Confirm Receipt" when eligible
5. ✅ POST /api/order now handled as `List<OrderResponse>`
6. ✅ Order detail now includes rating widgets per product

---

### Phase 4: Customer — Rating (WITH FIXES)

| # | Task | File | Status | Description |
|---|------|------|--------|-------------|
| 4.1 | Rating service | `services/rating_service.dart` | ✅ Done | `createRating()`, `getByProduct()`, `getByUser()` |
| 4.2 | Rating provider | `Providers/rating_provider.dart` | ✅ Done | Rating creation/update/delete and paginated product/user ratings |
| 4.3 | Rating input widget | `Ui/Widgets/rating_input_widget.dart` | ✅ Done | Star selector, comment textarea, submit button |
| 4.4 | Rating display widget | `Ui/Widgets/rating_display_widget.dart` | ✅ Done | Show single rating card with stars + comment |
| 4.5 | Rating in order detail | `Ui/Screens/customer/order_detail_screen.dart` | ✅ Done | Rating widgets shown after completion |
| 4.6 | Confirm receipt flow | `Ui/Screens/customer/order_detail_screen.dart` | ✅ Done | Confirm Receipt button triggers status update and rating section refresh |
| 4.7 | My ratings screen | `Ui/Screens/customer/my_ratings_screen.dart` | ✅ Done | User's rating history with delete support |

**Key Workflows**:
- User views order with status=SHIPPING → sees "Confirm Receipt" button
- User clicks "Confirm Receipt" → calls `PATCH /api/order/{orderId}/status` with status=3
- Success → order expands to show rating section
- Each product in order has "Rate Product" button
- User clicks rate → opens rating dialog
- User selects stars, types comment, submits
- Backend checks: user purchased product, hasn't rated more times than qty purchased
- On success: show toast, refresh ratings

---

### Phase 5 & Beyond: Staff & Admin Features
*Unchanged from v2 — focus on customer first*

---

## 7. Key Technical Decisions (UPDATED)

### Image Carousel Implementation
```dart
// Use PageView for smooth horizontal scrolling
PageView(
  children: [
    for (var img in images)
      Image.network(img.imageUrl, fit: BoxFit.cover)
  ],
  onPageChanged: (index) {
    setState(() => _currentImageIndex = index);
  },
)

// Show dot indicators below
Row(
  children: [
    for (int i = 0; i < images.length; i++)
      GestureDetector(
        onTap: () => _pageController.animateToPage(i),
        child: Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentImageIndex ? Colors.blue : Colors.grey,
          ),
        ),
      ),
  ],
)
```

### Search Debouncing
```dart
Timer? _searchDebounce;

void _onSearchChanged(String query) {
  _searchDebounce?.cancel();
  
  if (query.isEmpty) {
    // Clear results immediately
    Provider.of<ProductProvider>(context, listen: false).clearSearch();
    return;
  }
  
  // Wait 1-2 seconds, then search
  _searchDebounce = Timer(const Duration(milliseconds: 1500), () {
    Provider.of<ProductProvider>(context, listen: false).searchProducts(query);
  });
}

@override
void dispose() {
  _searchDebounce?.cancel();
  super.dispose();
}
```

### Cart Checkboxes with Multi-Order
```dart
class CartProvider extends ChangeNotifier {
  Map<int, bool> _itemSelection = {}; // productId -> isSelected
  
  void toggleItemSelection(int productId) {
    _itemSelection[productId] = !(_itemSelection[productId] ?? false);
    notifyListeners();
  }
  
  void selectAll() {
    for (var item in cart.items) {
      _itemSelection[item.productId] = true;
    }
    notifyListeners();
  }
  
  List<CartItemResponse> getSelectedItems() {
    return cart.items
        .where((item) => _itemSelection[item.productId] ?? false)
        .toList();
  }
  
  // On checkout:
  // 1. Get selected items
  // 2. POST /api/order with those items
  // 3. Receive List<OrderResponse>
  // 4. If length > 1: show multi-order confirmation screen
  // 5. Each order shows storeId, storeName, items, total
}
```

### Order Expansion with Full Details
```dart
class OrderProvider extends ChangeNotifier {
  int? _expandedOrderId; // Track which order is expanded
  Map<int, OrderResponse> _fullOrderDetails = {}; // Cache full details
  
  Future<void> expandOrder(int orderId) async {
    _expandedOrderId = orderId;
    if (!_fullOrderDetails.containsKey(orderId)) {
      // Fetch full order details on demand
      _fullOrderDetails[orderId] = await orderService.getOrder(orderId);
    }
    notifyListeners();
  }
  
  bool isExpanded(int orderId) => _expandedOrderId == orderId;
  OrderResponse? getFullOrder(int orderId) => _fullOrderDetails[orderId];
}

// In UI:
GestureDetector(
  onTap: () => provider.expandOrder(order.id),
  child: ExpansionTile(
    title: Text('Order #${order.id}'),
    subtitle: Text(order.storeName), // ← NEW: Show store name
    children: [
      // Show full order details from _fullOrderDetails[order.id]
      // Include "Confirm Receipt" button if status=3
    ],
  ),
)
```

### Rating Workflow Integration
```dart
// In order detail screen, after order expanded:
if (order.status == 3) { // COMPLETED
  Column(
    children: [
      ElevatedButton.icon(
        onPressed: _showConfirmReceiptDialog,
        icon: Icon(Icons.done),
        label: Text('Confirm Receipt'),
      ),
    ],
  )
}

// After confirming receipt:
Future<void> _confirmReceipt() async {
  await orderService.changeStatus(order.id, 3);
  // Refresh order
  order = await orderService.getOrder(order.id);
  // Show rating section:
  for (var item in order.items) {
    RatingInputWidget(
      productId: item.productId,
      productName: item.productName,
      onSubmit: (ratingDTO) async {
        await ratingService.createRating(ratingDTO);
        // Show success toast
        // Refresh ratings
      },
    );
  }
}
```

---

## 8. Backend API Quick Reference (UPDATED)

| Module | Method | Path | Used By | Notes |
|--------|--------|------|---------|-------|
| **Auth** | POST | `/api/auth/login` | All | |
| | POST | `/api/auth/signup` | Public (CUSTOMER only) | |
| **User** | POST | `/api/user` | ADMIN/MANAGER/EMPLOYEE (internal create) | |
| | GET | `/api/user?keyword=&page=&size=` | MANAGER/ADMIN | |
| | PATCH | `/api/user/{id}?status=` | MANAGER/ADMIN | |
| | PUT | `/api/user/profile` | All | |
| | PATCH | `/api/user/password` | All | |
| **Company** | GET | `/api/company?keyword=&page=&size=` | Login/Signup/ADMIN | |
| | POST | `/api/company` | ADMIN | |
| | PUT | `/api/company/{id}` | ADMIN | |
| **Store** | GET | `/api/store?keyword=&page=&size=` | ADMIN | |
| | GET | `/api/store/all` | CUSTOMER | **NEW: No auth** |
| | GET | `/api/store/product/{productId}?page=&size=` | CUSTOMER | **NEW: Store list with inventory** |
| | POST | `/api/store` | ADMIN | |
| | PUT | `/api/store/{id}` | ADMIN | |
| **Product** | GET | `/api/product?keyword=&page=&size=` | EMPLOYEE/MANAGER | |
| | GET | `/api/product/store?page=&size=` | CUSTOMER | Products by company |
| | GET | `/api/product/{id}/customer` | CUSTOMER | **USE THIS for customer detail** |
| | GET | `/api/product/{id}/manage` | EMPLOYEE/MANAGER | **USE THIS for staff detail** |
| | POST | `/api/product` | MANAGER | |
| | PUT | `/api/product/{id}` | MANAGER | |
| | PATCH | `/api/product/{id}/status` | MANAGER | |
| | GET | `/api/product/{id}/inventory/{storeId}` | EMPLOYEE/MANAGER | |
| | GET | `/api/product/report` | MANAGER | |
| | GET | `/api/product/report/{id}` | MANAGER | |
| **Product Image** | GET | `/api/product/{id}/images` | All | **Returns ProductImageListResponse** |
| | POST | `/api/product/{id}/images` | MANAGER | |
| | PATCH | `/api/product/{id}/images/{imageId}` | MANAGER | |
| | DELETE | `/api/product/{id}/images/{imageId}` | MANAGER | |
| **Cart** | POST | `/api/cart/items` | CUSTOMER | |
| | PATCH | `/api/cart/items/{productId}` | CUSTOMER | |
| | DELETE | `/api/cart/items/{productId}` | CUSTOMER | |
| | GET | `/api/cart` | CUSTOMER | |
| | DELETE | `/api/cart/clear` | CUSTOMER | |
| **Order** | POST | `/api/order` | CUSTOMER/EMPLOYEE/MANAGER | **RETURNS List<OrderResponse>** |
| | PUT | `/api/order/{id}` | EMPLOYEE/MANAGER (PENDING only) | |
| | GET | `/api/order/{id}` | All (own or staff) | |
| | GET | `/api/order?status=&keyword=&page=&size=` | All | **Returns Page<OrderListResponse>** |
| | PATCH | `/api/order/{id}/status` | CUSTOMER/EMPLOYEE/MANAGER | |
| | PATCH | `/api/order/{id}/payment` | EMPLOYEE/MANAGER | |
| | GET | `/api/order/report?storeId=&start=&end=` | MANAGER | |
| **Rating** | POST | `/api/rating` | CUSTOMER | |
| | PUT | `/api/rating/{id}` | CUSTOMER | |
| | GET | `/api/rating/product/{id}?page=&size=` | All | **Lazy load in product detail** |
| | GET | `/api/rating/user` | CUSTOMER | User's rating history |
| | PATCH | `/api/rating/{id}/status?status=` | MANAGER | |
| | DELETE | `/api/rating/{id}` | CUSTOMER | |
| **PurchaseOrder** | POST | `/api/purchase_order` | EMPLOYEE/MANAGER | |
| | GET | `/api/purchase_order?searching=&status=&page=&size=` | EMPLOYEE/MANAGER | |
| | PATCH | `/api/purchase_order/{id}?status=` | EMPLOYEE/MANAGER | |
| | GET | `/api/purchase_order/report?storeId=&start=&end=` | MANAGER | |
| **Promotion** | POST | `/api/promotion/product` | MANAGER | |
| | POST | `/api/promotion/order` | MANAGER | |
| | PUT | `/api/promotion/{id}` | MANAGER | |
| | PATCH | `/api/promotion/{id}?status=` | MANAGER | |
| | GET | `/api/promotion/company/{id}?keyword=&page=&size=` | MANAGER | |
| **Inventory** | GET | `/api/inventory?productId=&storeId=` | EMPLOYEE/MANAGER | |
| | GET | `/api/inventory/store?storeId=&page=&size=` | EMPLOYEE/MANAGER | |
| **Category** | GET | `/api/category?keyword=&page=&size=` | MANAGER | |
| **Unit** | GET | `/api/unit?keyword=&page=&size=` | MANAGER | |
| **Provider** | GET POST PUT PATCH | `/api/provider/...` | MANAGER | |

---

## 9. Estimated Timeline (v3)

| Phase | Description | Tasks | Estimated Time |
|-------|-------------|-------|----------------|
| Phase 0 | Foundation | ✅ Done | Done |
| Phase 1 | Auth + Role routing | ✅ Done | Done |
| **Phase 2** | **Customer: Products + Cart (WITH FIXES)** | **13 tasks** | **6-8 hours** |
| **Phase 3** | **Customer: Order Flow (WITH FIXES)** | **8 tasks** | **4-5 hours** |
| **Phase 4** | **Customer: Rating (WITH FIXES)** | **7 tasks** | **3-4 hours** |
| Phase 5 | Employee/Manager: Product mgmt + POS + PO | 13 tasks | 5-6 hours |
| Phase 6 | Manager: Reports + Promotions + Users | 8 tasks | 3-4 hours |
| Phase 7 | Admin: Company/Store/User mgmt | 6 tasks | 2-3 hours |
| Phase 8 | Polish | - | 2-3 hours |
| **TOTAL** | | | **~35-40 hours** |

### Priority Fixes (Do These First!)
1. **Product Detail** (2.0-2.9): Image carousel, store list, ratings, debounce search, Buy Now button
2. **Cart** (2.11-2.12): Checkboxes, multi-order handling
3. **Order List/Detail** (3.1-3.8): Store info, expansion, Confirm Receipt, rating integration

---

## 10. Post-Implementation Status

The Flutter client now matches the audited backend contract for the customer order flow.

Completed in code:
- Product detail now shows image carousel, store inventory list, lazy-loaded ratings, Add to Cart, and Buy Now.
- Search now uses a 1-2 second debounce before firing the API request.
- Cart now supports per-item selection and routes only selected items to checkout.
- Checkout now accepts selected item IDs, uses the new `List<OrderResponse>` response, and shows multi-order confirmation.
- My Orders now displays store name and supports expansion.
- Order detail now supports confirm-receipt and rating entry for completed orders.
- Rating provider and order provider were added/updated to support the new workflow.

Still worth verifying in runtime:
- Buy Now navigation path from product detail to checkout.
- Multi-store splitting display after order creation.
- Rating flow from completed orders against the backend purchase-quantity validation.

## 11. Code Examples & Snippets

### Example: ProductProvider with Search Debouncing
```dart
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<ProductResponse> products = [];
  bool isLoading = false;
  String? errorMessage;
  
  Timer? _searchDebounce;

  Future<void> searchProducts(String keyword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getList(keyword, page: 0, size: 20);
      products = response.content ?? [];
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      products = [];
      notifyListeners();
      return;
    }

    // Wait 1-2 seconds before API call
    _searchDebounce = Timer(const Duration(milliseconds: 1500), () {
      searchProducts(query);
    });
  }

  // Get product images
  Future<ProductImageListResponse?> getProductImages(int productId) async {
    try {
      return await _productService.getProductImages(productId);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get stores for product
  Future<List<StoreWithInventoryResponse>?> getStoresByProduct(int productId) async {
    try {
      final response = await _productService.getStoresByProduct(productId, page: 0, size: 10);
      return response.content;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get ratings for product
  Future<List<RatingResponse>?> getRatings(int productId) async {
    try {
      final response = await _productService.getRatings(productId, page: 0, size: 5);
      return response.content;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
```

### Example: Image Carousel Widget
```dart
class ImageCarouselWidget extends StatefulWidget {
  final List<ProductImageResponse> images;

  const ImageCarouselWidget({required this.images, super.key});

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.images[index].imageUrl,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        // Dot indicators
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.images.length; i++)
              GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentIndex ? Colors.blue : Colors.grey[300],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
```

### Example: Order Expansion with Rating
```dart
class OrderListTile extends StatefulWidget {
  final OrderListResponse order;
  final OrderProvider provider;

  const OrderListTile({
    required this.order,
    required this.provider,
    super.key,
  });

  @override
  State<OrderListTile> createState() => _OrderListTileState();
}

class _OrderListTileState extends State<OrderListTile> {
  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.provider.isExpanded(widget.order.id!);
    final fullOrder = widget.provider.getFullOrder(widget.order.id!);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header (always visible)
          GestureDetector(
            onTap: () async {
              if (isExpanded) {
                widget.provider.collapseOrder(widget.order.id!);
              } else {
                await widget.provider.expandOrder(widget.order.id!);
              }
              setState(() {});
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${widget.order.id}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Store: ${widget.order.storeName}', // NEW
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          CurrencyFormat.format(widget.order.totalAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded && fullOrder != null)
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    'Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (var item in fullOrder.items ?? [])
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${item.productName} × ${item.quantity} = ${CurrencyFormat.format(item.subtotal)}',
                      ),
                    ),
                  Divider(),
                  Text(
                    'Status: ${_getStatusText(fullOrder.status)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Delivery: ${fullOrder.shippingAddress}',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (fullOrder.note != null)
                    Text(
                      'Note: ${fullOrder.note}',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  SizedBox(height: 12),
                  // Confirm Receipt button (status=3 is DELIVERED)
                  if (fullOrder.status == 3)
                    ElevatedButton(
                      onPressed: _showConfirmReceiptDialog,
                      child: Text('Confirm Receipt'),
                    ),
                  // Rating section (after confirmed)
                  if (fullOrder.status == 3)
                    Column(
                      children: [
                        SizedBox(height: 12),
                        Text(
                          'Rate Products:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (var item in fullOrder.items ?? [])
                          RatingInputWidget(
                            productId: item.productId,
                            productName: item.productName,
                            onSubmit: (ratingDTO) => _submitRating(ratingDTO),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showConfirmReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Receipt'),
        content: Text('Have you received this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Call API
              await widget.provider.changeOrderStatus(
                widget.order.id!,
                3,
              );
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receipt confirmed!')),
                );
              }
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(RatingCreateDTO dto) async {
    // Call rating service
    // Show success toast
    // Optionally refresh ratings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating submitted!')),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'PENDING';
      case 1: return 'CONFIRMED';
      case 2: return 'SHIPPING';
      case 3: return 'DELIVERED';
      case 4: return 'CANCELLED';
      default: return 'UNKNOWN';
    }
  }
}
```

---

## 11. Checklist Before Starting Implementation

- [x] Read backend code (OrderServiceImpl, ProductServiceImpl, RatingServiceImpl)
- [x] Read backend DTOs (OrderResponse, ProductImageListResponse, RatingResponse)
- [x] Read backend controllers (OrderController, ProductController, RatingController)
- [x] Understand multi-store order splitting logic
- [x] Understand image carousel and store list requirements
- [x] Understand search debouncing requirement
- [x] Understand rating workflow (post-delivery)
- [x] Update Implementation Plan v3
- [ ] Start implementing Phase 2 fixes (product detail, search debounce, cart checkboxes)
- [ ] Test with actual backend API
- [ ] Implement Phase 3 fixes (order expansion, Confirm Receipt, rating)
- [ ] Implement Phase 4 (rating widgets and workflow)
- [ ] Polish UI/UX

---

**Last Updated**: 2026-04-30
**Status**: Ready for Implementation

---

## 7. Estimated Timeline

| Phase | Description | Estimated Time |
|-------|-------------|----------------|
| Phase 0 | Fix foundation | ✅ Done |
| Phase 1 | Auth + Role routing + Shells | 3-4 hours |
| Phase 2 | Customer: Products + Cart + Barcode | 4-5 hours |
| Phase 3 | Customer: Order flow | 3-4 hours |
| Phase 4 | Customer: Ratings | 1-2 hours |
| Phase 5 | Employee/Manager: Product mgmt + POS + PO | 5-6 hours |
| Phase 6 | Manager: Reports + Promotions + Users | 3-4 hours |
| Phase 7 | Admin: Company/Store/User mgmt | 2-3 hours |
| Phase 8 | Polish | 2-3 hours |
| **Total** | | **~25-30 hours** |
