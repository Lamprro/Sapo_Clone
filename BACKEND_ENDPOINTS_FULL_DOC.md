# 📚 SAPO CLONE BACKEND - ENDPOINT TÀI LIỆU ĐẦY ĐỦ

**Cập nhật:** Tháng 5, 2026  
**Tổng Endpoints:** 56 endpoints  
**Tổng Controllers:** 15 controllers

---

## 📋 MỤC LỤC

1. [Authentication Controller](#1-authentication-controller)
2. [Product Controller](#2-product-controller)
3. [Order Controller](#3-order-controller)
4. [Cart Controller](#4-cart-controller)
5. [Rating Controller](#5-rating-controller)
6. [Promotion Controller](#6-promotion-controller)
7. [Company Controller](#7-company-controller)
8. [Store Controller](#8-store-controller)
9. [User Controller](#9-user-controller)
10. [Inventory Controller](#10-inventory-controller)
11. [Purchase Order Controller](#11-purchase-order-controller)
12. [Category Controller](#12-category-controller)
13. [Unit Controller](#13-unit-controller)
14. [Provider Controller](#14-provider-controller)
15. [Product Image Controller](#15-product-image-controller)

---

## 1️⃣ AUTHENTICATION CONTROLLER

**Base URL:** `/api/auth/`

### 1.1 Login
- **API:** `POST /api/auth/login`
- **Mô Tả:** Đăng nhập và nhận JWT token
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (LoginRequest):**
  ```
  {
    "username": "string (required)",
    "password": "string (required)",
    "companyId": "integer (required)"
  }
  ```
- **Response (LoginResponse):**
  ```
  {
    "token": "string (JWT token)",
    "user": {
      "id": "integer",
      "fullName": "string",
      "email": "string",
      "username": "string",
      "phone": "string",
      "address": "string",
      "status": "integer (0=active, 1=inactive)",
      "createdAt": "LocalDateTime",
      "updatedAt": "LocalDateTime",
      "roleName": "string",
      "companyId": "integer",
      "storeId": "integer",
      "pointValue": "integer"
    }
  }
  ```

### 1.2 Sign Up (Register)
- **API:** `POST /api/auth/signup`
- **Mô Tả:** Đăng ký tài khoản customer mới
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (SignUpRequest):**
  ```
  {
    "fullName": "string (required)",
    "phone": "string (required, format: 0[3578]xxxxxxxx)",
    "email": "string (required, valid email)",
    "username": "string (required)",
    "password": "string (required)",
    "repeatPassword": "string (required)",
    "companyId": "integer (required)",
    "address": "string (required)",
    "roleId": "integer (optional)",
    "storeId": "integer (optional)"
  }
  ```
- **Response (UserResponse):**
  ```
  {
    "id": "integer",
    "fullName": "string",
    "email": "string",
    "username": "string",
    "phone": "string",
    "address": "string",
    "status": "integer",
    "createdAt": "LocalDateTime",
    "updatedAt": "LocalDateTime",
    "roleName": "string",
    "companyId": "integer",
    "storeId": "integer",
    "pointValue": "integer"
  }
  ```

---

## 2️⃣ PRODUCT CONTROLLER

**Base URL:** `/api/product/`

### 2.1 Create Product
- **API:** `POST /api/product`
- **Mô Tả:** Tạo sản phẩm mới
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (ProductCreateDTO):**
  ```
  {
    "productName": "string (required)",
    "description": "string (optional)",
    "barcode": "string (required)",
    "importPrice": "double (required, >= 0)",
    "sellPriceOriginal": "double (required, > 0)",
    "sellPrice": "double (required, > 0)",
    "unitId": "long (required)",
    "categoryIds": "List<Long> (required, min 1)"
  }
  ```
- **Response (ProductResponse):**
  ```
  {
    "id": "integer",
    "productName": "string",
    "description": "string",
    "barcode": "string",
    "avgStar": "double",
    "status": "integer (0=inactive, 1=active)",
    "importPrice": "double",
    "sellPriceOriginal": "double",
    "sellPrice": "double",
    "unitId": "long",
    "unitName": "string",
    "categoryIds": "List<Long>",
    "categoryNames": "List<String>"
  }
  ```

### 2.2 List Products (Paginated, Searchable)
- **API:** `GET /api/product`
- **Mô Tả:** Lấy danh sách sản phẩm có phân trang và tìm kiếm
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (optional) - Từ khóa tìm kiếm
  page: integer (default=0) - Trang (0-indexed)
  size: integer (default=20) - Số items trên trang
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<ProductResponse> - Trang chứa danh sách ProductResponse
  {
    "content": [ProductResponse[]],
    "totalElements": "long",
    "totalPages": "integer",
    "currentPage": "integer",
    "pageSize": "integer"
  }
  ```

### 2.3 Get Product Detail for Customer
- **API:** `GET /api/product/{id}/customer`
- **Mô Tả:** Lấy chi tiết sản phẩm cho khách hàng (ẩn giá import, giá gốc)
- **Path Variables:**
  ```
  id: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (ProductResponse):** (Chỉ hiển thị: id, name, description, barcode, avgStar, status, sellPrice, unitName, categoryNames)

### 2.4 Get Product Detail for Manage
- **API:** `GET /api/product/{id}/manage`
- **Mô Tả:** Lấy chi tiết sản phẩm cho nhân viên/quản lý (bao gồm giá import)
- **Path Variables:**
  ```
  id: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (ProductResponse):** (Bao gồm tất cả fields)

### 2.5 Update Product
- **API:** `PUT /api/product/{id}`
- **Mô Tả:** Cập nhật thông tin sản phẩm
- **Path Variables:**
  ```
  id: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body (ProductUpdateDTO):**
  ```
  {
    "productName": "string (required)",
    "description": "string (optional)",
    "barcode": "string (required)",
    "importPrice": "double (required, >= 0)",
    "sellPriceOriginal": "double (required, > 0)",
    "sellPrice": "double (required, > 0)",
    "unitId": "long (required)",
    "categoryIds": "List<Long> (required, min 1)"
  }
  ```
- **Response (ProductResponse):**

### 2.6 Change Product Status
- **API:** `PATCH /api/product/{id}/status`
- **Mô Tả:** Thay đổi trạng thái sản phẩm (active/inactive)
- **Path Variables:**
  ```
  id: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body (ChangeProductStatusDTO):**
  ```
  {
    "status": "integer (required, 0=inactive, 1=active)"
  }
  ```
- **Response (ProductResponse):**

### 2.7 Get Product Inventory by Store
- **API:** `GET /api/product/{id}/inventory/{storeId}`
- **Mô Tả:** Lấy tồn kho của sản phẩm trong một cửa hàng
- **Path Variables:**
  ```
  id: integer - ID sản phẩm
  storeId: integer - ID cửa hàng
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (ProductInventoryResponse):**
  ```
  {
    "productId": "integer",
    "storeId": "integer",
    "quantity": "integer"
  }
  ```

### 2.8 Get Aggregated Product Report
- **API:** `GET /api/product/report`
- **Mô Tả:** Lấy báo cáo sản phẩm tổng hợp (tổng bán, doanh thu, lợi nhuận, đánh giá)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:**
  ```
  List<ProductReportProjection> - Danh sách báo cáo
  {
    "productId": "integer",
    "productName": "string",
    "totalSellQuantity": "integer",
    "totalRevenue": "double",
    "totalProfit": "double",
    "evaluationScore": "double"
  }[]
  ```

### 2.9 Get Detailed Product Report
- **API:** `GET /api/product/report/{productId}`
- **Mô Tả:** Lấy báo cáo chi tiết cho một sản phẩm (phân trang)
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:**
  ```
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response (ProductReportDetailResponse):**
  ```
  {
    "productId": "integer",
    "productName": "string",
    "details": [
      {
        "date": "LocalDateTime",
        "quantity": "integer",
        "revenue": "double",
        "profit": "double"
      }
    ],
    "pagination": {...}
  }
  ```

### 2.10 Get Products from User's Store
- **API:** `GET /api/product/store`
- **Mô Tả:** Lấy tất cả sản phẩm từ cửa hàng của user (được xác định từ JWT)
- **Path Variables:** Không có
- **Request Params:**
  ```
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<ProductResponse>
  ```

---

## 3️⃣ ORDER CONTROLLER

**Base URL:** `/api/order/`

### 3.1 Create Order
- **API:** `POST /api/order`
- **Mô Tả:** Tạo đơn hàng mới từ giỏ hàng
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (OrderCreateDTO):**
  ```
  {
    "customerId": "integer (required)",
    "employeeId": "integer (optional)",
    "storeId": "integer (optional)",
    "promotionId": "integer (optional)",
    "paymentMethod": "string (required)",
    "shippingAddress": "string (optional)",
    "note": "string (optional)",
    "earnPoint": "integer (default=0)",
    "redeemPoint": "integer (default=0)",
    "orderDetails": [
      {
        "productId": "integer (required)",
        "quantity": "integer (required, >= 1)",
        "storeId": "integer (optional)"
      }
    ]
  }
  ```
- **Response:**
  ```
  List<OrderResponse> - Danh sách đơn hàng vừa tạo
  ```

### 3.2 Get Order by ID
- **API:** `GET /api/order/{id}`
- **Mô Tả:** Lấy chi tiết đơn hàng
- **Path Variables:**
  ```
  id: integer - ID đơn hàng
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (OrderResponse):**
  ```
  {
    "id": "integer",
    "customerId": "integer",
    "storeId": "integer",
    "storeName": "string",
    "status": "integer (0=pending, 1=confirmed, 2=shipping, 3=completed, 4=cancelled)",
    "totalAmount": "double",
    "paymentMethod": "string",
    "paymentStatus": "integer (0=unpaid, 1=paid, 2=failed, 3=refunded)",
    "createdAt": "LocalDateTime",
    "shippingAddress": "string",
    "note": "string",
    "items": [
      {
        "productId": "integer",
        "quantity": "integer",
        "price": "double",
        "subtotal": "double"
      }
    ],
    "promotionId": "integer"
  }
  ```

### 3.3 List Orders (Paginated, Filterable)
- **API:** `GET /api/order`
- **Mô Tả:** Lấy danh sách đơn hàng có lọc theo trạng thái, tìm kiếm
- **Path Variables:** Không có
- **Request Params:**
  ```
  status: integer (optional) - Trạng thái đơn hàng
  keyword: string (optional) - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<OrderListResponse>
  {
    "id": "integer",
    "storeId": "integer",
    "storeName": "string",
    "status": "integer",
    "totalAmount": "double",
    "customerName": "string",
    "createdAt": "LocalDateTime",
    "paymentMethod": "string",
    "paymentStatus": "integer"
  }[]
  ```

### 3.4 Update Order (PENDING only)
- **API:** `PUT /api/order/{id}`
- **Mô Tả:** Cập nhật đơn hàng (chỉ khi status = PENDING)
- **Path Variables:**
  ```
  id: integer - ID đơn hàng
  ```
- **Request Params:** Không có
- **Request Body (OrderUpdateDTO):**
  ```
  {
    "paymentMethod": "string (required)",
    "shippingAddress": "string (optional)",
    "note": "string (optional)",
    "items": [
      {
        "productId": "integer (required)",
        "quantity": "integer (required, >= 1)",
        "storeId": "integer (optional)"
      }
    ]
  }
  ```
- **Response (OrderResponse):**

### 3.5 Change Order Status
- **API:** `PATCH /api/order/{id}/status`
- **Mô Tả:** Thay đổi trạng thái đơn hàng (0→1→2→3 hoặc 4)
- **Path Variables:**
  ```
  id: integer - ID đơn hàng
  ```
- **Request Params:** Không có
- **Request Body (OrderStatusDTO):**
  ```
  {
    "status": "integer (required, 0-4)"
  }
  ```
- **Response (OrderResponse):**

### 3.6 Change Payment Status
- **API:** `PATCH /api/order/{id}/payment`
- **Mô Tả:** Thay đổi trạng thái thanh toán
- **Path Variables:**
  ```
  id: integer - ID đơn hàng
  ```
- **Request Params:** Không có
- **Request Body (OrderPaymentDTO):**
  ```
  {
    "paymentStatus": "integer (required, 0=unpaid, 1=paid, 2=failed, 3=refunded)"
  }
  ```
- **Response (OrderResponse):**

### 3.7 Get Financial Report
- **API:** `GET /api/order/report`
- **Mô Tả:** Lấy báo cáo tài chính (doanh thu theo cửa hàng và khoảng thời gian)
- **Path Variables:** Không có
- **Request Params:**
  ```
  storeId: integer (default=-1, -1 = tất cả cửa hàng)
  start: LocalDateTime (optional) - Ngày bắt đầu
  end: LocalDateTime (optional) - Ngày kết thúc
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Map<String, Object>
  {
    "totalRevenue": "double",
    "totalOrders": "integer",
    "byStore": {
      "storeId": {
        "storeName": "string",
        "revenue": "double",
        "orderCount": "integer"
      }
    },
    "byStatus": {
      "0": {"count": "integer", "revenue": "double"},
      ...
    }
  }
  ```

---

## 4️⃣ CART CONTROLLER

**Base URL:** `/api/cart/`

### 4.1 Get Cart
- **API:** `GET /api/cart`
- **Mô Tả:** Lấy giỏ hàng của user hiện tại
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (CartResponse):**
  ```
  {
    "cartId": "integer",
    "items": [
      {
        "productId": "integer",
        "productName": "string",
        "sellPrice": "double",
        "quantity": "integer",
        "totalPrice": "double"
      }
    ],
    "totalAmount": "double"
  }
  ```

### 4.2 Add Item to Cart
- **API:** `POST /api/cart/items`
- **Mô Tả:** Thêm sản phẩm vào giỏ hàng (hoặc tăng số lượng nếu đã có)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (AddToCartDTO):**
  ```
  {
    "productId": "integer (required)",
    "quantity": "integer (required, > 0)"
  }
  ```
- **Response (CartResponse):**

### 4.3 Update Cart Item Quantity
- **API:** `PATCH /api/cart/items/{productId}`
- **Mô Tả:** Cập nhật số lượng sản phẩm trong giỏ hàng
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body (UpdateCartItemDTO):**
  ```
  {
    "quantity": "integer (required, >= 0)"
  }
  ```
- **Response (CartResponse):**

### 4.4 Remove Item from Cart
- **API:** `DELETE /api/cart/items/{productId}`
- **Mô Tả:** Xóa sản phẩm khỏi giỏ hàng
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (CartResponse):**

### 4.5 Clear Cart
- **API:** `DELETE /api/cart/clear`
- **Mô Tả:** Xóa tất cả sản phẩm khỏi giỏ hàng
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:** Success message only

---

## 5️⃣ RATING CONTROLLER

**Base URL:** `/api/rating/`

### 5.1 Create Rating
- **API:** `POST /api/rating`
- **Mô Tả:** Tạo đánh giá sản phẩm
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (RatingCreateDTO):**
  ```
  {
    "rating": "integer (required, 1-5)",
    "comment": "string (required)",
    "productId": "integer (required)"
  }
  ```
- **Response (RatingResponse):**
  ```
  {
    "id": "integer",
    "rating": "integer",
    "comment": "string",
    "userId": "integer",
    "userFullName": "string",
    "updatedAt": "LocalDateTime",
    "productId": "integer"
  }
  ```

### 5.2 Update Rating
- **API:** `PUT /api/rating/{id}`
- **Mô Tả:** Cập nhật đánh giá
- **Path Variables:**
  ```
  id: integer - ID đánh giá
  ```
- **Request Params:** Không có
- **Request Body (RatingUpdateDTO):**
  ```
  {
    "rating": "integer (optional, 1-5)",
    "comment": "string (optional)",
    "status": "integer (optional)"
  }
  ```
- **Response (RatingResponse):**

### 5.3 Get Ratings by Product
- **API:** `GET /api/rating/product/{productId}`
- **Mô Tả:** Lấy danh sách đánh giá của sản phẩm (phân trang)
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:**
  ```
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<RatingResponse>
  ```

### 5.4 Get Current User's Ratings
- **API:** `GET /api/rating/user`
- **Mô Tả:** Lấy tất cả đánh giá của user hiện tại
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:**
  ```
  List<RatingResponse>
  ```

### 5.5 Change Rating Status (Approve/Reject)
- **API:** `PATCH /api/rating/{id}/status`
- **Mô Tả:** Thay đổi trạng thái đánh giá (duyệt/từ chối)
- **Path Variables:**
  ```
  id: integer - ID đánh giá
  ```
- **Request Params:**
  ```
  status: integer (required) - 0=pending, 1=approved, 2=rejected
  ```
- **Request Body:** Không có
- **Response (RatingResponse):**

### 5.6 Delete Rating
- **API:** `DELETE /api/rating/{id}`
- **Mô Tả:** Xóa đánh giá
- **Path Variables:**
  ```
  id: integer - ID đánh giá
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:** Success message only

---

## 6️⃣ PROMOTION CONTROLLER

**Base URL:** `/api/promotion/`

### 6.1 Create Product Promotion
- **API:** `POST /api/promotion/product`
- **Mô Tả:** Tạo khuyến mãi theo sản phẩm
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (PromotionCreateDTO):**
  ```
  {
    "promotionName": "string (required)",
    "description": "string (required)",
    "scope": "integer (required, 0=product, 1=order)",
    "discountType": "integer (required, 0=percent, 1=fixed)",
    "discountValue": "double (required)",
    "maxAccount": "double (required)",
    "minAccount": "double (required)",
    "startDate": "LocalDateTime (required)",
    "endDate": "LocalDateTime (required)",
    "productIds": "List<Integer> (optional)"
  }
  ```
- **Response (PromotionResponse):**
  ```
  {
    "id": "integer",
    "scope": "integer",
    "promotionName": "string",
    "discountValue": "double",
    "discountType": "string",
    "maxAccount": "double",
    "minAccount": "double",
    "description": "string",
    "startDate": "LocalDateTime",
    "endDate": "LocalDateTime",
    "status": "integer",
    "productIds": "List<Integer>"
  }
  ```

### 6.2 Create Order Promotion
- **API:** `POST /api/promotion/order`
- **Mô Tả:** Tạo khuyến mãi theo đơn hàng (min order value)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (PromotionCreateDTO):** (Giống 6.1)
- **Response (PromotionResponse):**

### 6.3 Update Promotion
- **API:** `PUT /api/promotion/{promotionId}`
- **Mô Tả:** Cập nhật khuyến mãi
- **Path Variables:**
  ```
  promotionId: integer - ID khuyến mãi
  ```
- **Request Params:** Không có
- **Request Body (PromotionUpdateDTO):**
  ```
  {
    "promotionName": "string (optional)",
    "description": "string (optional)",
    "scope": "integer (optional)",
    "discountType": "integer (optional)",
    "discountValue": "double (optional)",
    "maxAccount": "double (optional)",
    "minAccount": "double (optional)",
    "startDate": "LocalDateTime (optional)",
    "endDate": "LocalDateTime (optional)",
    "status": "integer (optional)",
    "productIds": "List<Integer> (optional)"
  }
  ```
- **Response (PromotionResponse):**

### 6.4 Change Promotion Status
- **API:** `PATCH /api/promotion/{promotionId}`
- **Mô Tả:** Thay đổi trạng thái khuyến mãi
- **Path Variables:**
  ```
  promotionId: integer - ID khuyến mãi
  ```
- **Request Params:**
  ```
  status: integer (required) - 0=inactive, 1=active
  ```
- **Request Body:** Không có
- **Response (PromotionResponse):**

### 6.5 Get Promotions by Company
- **API:** `GET /api/promotion/company/{companyId}`
- **Mô Tả:** Lấy danh sách khuyến mãi của công ty (phân trang, tìm kiếm)
- **Path Variables:**
  ```
  companyId: integer - ID công ty
  ```
- **Request Params:**
  ```
  keyword: string (optional) - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<PromotionListResponse>
  {
    "id": "integer",
    "scope": "integer",
    "promotionName": "string",
    "discountValue": "double",
    "discountType": "string",
    "maxAccount": "double",
    "minAccount": "double",
    "description": "string",
    "startDate": "LocalDateTime",
    "endDate": "LocalDateTime",
    "status": "integer"
  }[]
  ```

---

## 7️⃣ COMPANY CONTROLLER

**Base URL:** `/api/company/`

### 7.1 Create Company
- **API:** `POST /api/company`
- **Mô Tả:** Tạo công ty mới
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (CompanyDTO):**
  ```
  {
    "companyName": "string (required)",
    "companyAddress": "string (optional)"
  }
  ```
- **Response (CompanyResponse):**
  ```
  {
    "id": "integer",
    "companyName": "string",
    "companyAddress": "string",
    "createdAt": "LocalDateTime"
  }
  ```

### 7.2 Get List of Companies
- **API:** `GET /api/company`
- **Mô Tả:** Lấy danh sách công ty (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (default="") - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<CompanyResponse>
  ```

### 7.3 Update Company
- **API:** `PUT /api/company/{id}`
- **Mô Tả:** Cập nhật thông tin công ty
- **Path Variables:**
  ```
  id: integer - ID công ty
  ```
- **Request Params:** Không có
- **Request Body (CompanyDTO):**
  ```
  {
    "companyName": "string (required)",
    "companyAddress": "string (optional)"
  }
  ```
- **Response (CompanyResponse):**

---

## 8️⃣ STORE CONTROLLER

**Base URL:** `/api/store/`

### 8.1 Create Store
- **API:** `POST /api/store`
- **Mô Tả:** Tạo cửa hàng mới
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (StoreDTO):**
  ```
  {
    "storeName": "string (required)",
    "storeAddress": "string (required)",
    "latitude": "double (optional)",
    "longitude": "double (optional)"
  }
  ```
- **Response (StoreResponse):**
  ```
  {
    "id": "integer",
    "storeName": "string",
    "companyId": "integer",
    "storeAddress": "string",
    "latitude": "double",
    "longitude": "double",
    "createdAt": "LocalDateTime"
  }
  ```

### 8.2 Get List of Stores
- **API:** `GET /api/store`
- **Mô Tả:** Lấy danh sách cửa hàng (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (default="") - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<StoreResponse>
  ```

### 8.3 Update Store
- **API:** `PUT /api/store/{id}`
- **Mô Tả:** Cập nhật thông tin cửa hàng
- **Path Variables:**
  ```
  id: integer - ID cửa hàng
  ```
- **Request Params:** Không có
- **Request Body (StoreDTO):**
  ```
  {
    "storeName": "string (required)",
    "storeAddress": "string (required)",
    "latitude": "double (optional)",
    "longitude": "double (optional)"
  }
  ```
- **Response (StoreResponse):**

### 8.4 Get All Stores (For Customer)
- **API:** `GET /api/store/all`
- **Mô Tả:** Lấy tất cả cửa hàng (không phân trang, dùng cho khách hàng xem)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:**
  ```
  List<StoreResponse>
  ```

### 8.5 Get Stores Selling Product
- **API:** `GET /api/store/product/{productId}`
- **Mô Tả:** Lấy danh sách cửa hàng bán sản phẩm kèm tồn kho (phân trang)
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:**
  ```
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<StoreWithInventoryResponse>
  {
    "id": "integer",
    "storeName": "string",
    "companyId": "integer",
    "storeAddress": "string",
    "latitude": "double",
    "longitude": "double",
    "createdAt": "LocalDateTime",
    "quantity": "integer (tồn kho sản phẩm)"
  }[]
  ```

---

## 9️⃣ USER CONTROLLER

**Base URL:** `/api/user/`

### 9.1 Create User
- **API:** `POST /api/user`
- **Mô Tả:** Tạo người dùng mới (staff, manager, admin)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (UserCreateDTO):**
  ```
  {
    "fullName": "string (required)",
    "phone": "string (required, format: 0[3578]xxxxxxxx)",
    "email": "string (required, valid email)",
    "username": "string (required)",
    "password": "string (required)",
    "companyId": "integer (required)",
    "address": "string (required)",
    "storeId": "integer (optional)",
    "roleId": "integer (optional)"
  }
  ```
- **Response (UserResponse):** (Giống login response user)

### 9.2 Get List of Users
- **API:** `GET /api/user`
- **Mô Tả:** Lấy danh sách người dùng (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (default="") - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=10)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<UserResponse>
  ```

### 9.3 Update User Status
- **API:** `PATCH /api/user/{id}`
- **Mô Tả:** Cập nhật trạng thái người dùng (active/inactive)
- **Path Variables:**
  ```
  id: integer - ID người dùng
  ```
- **Request Params:**
  ```
  status: integer (required, 0=active, 1=inactive)
  ```
- **Request Body:** Không có
- **Response (UserResponse):**

### 9.4 Update Current User Profile
- **API:** `PUT /api/user/profile`
- **Mô Tả:** Cập nhật hồ sơ của user hiện tại
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (UpdateUserDTO):**
  ```
  {
    "fullName": "string (required)",
    "phone": "string (required, format: 0[3578]xxxxxxxx)",
    "email": "string (required, valid email)",
    "address": "string (optional)"
  }
  ```
- **Response (UserResponse):**

### 9.5 Change User Password
- **API:** `PATCH /api/user/password`
- **Mô Tả:** Đổi mật khẩu của user hiện tại
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (ChangePasswordRequest):**
  ```
  {
    "id": "integer",
    "oldPassword": "string (required)",
    "newPassword": "string (required, min 6 chars)",
    "confirmPassword": "string (required)"
  }
  ```
- **Response:** Success message only

---

## 🔟 INVENTORY CONTROLLER

**Base URL:** `/api/inventory/`

### 10.1 Get Inventory by Product and Store
- **API:** `GET /api/inventory`
- **Mô Tả:** Lấy tồn kho của sản phẩm trong cửa hàng
- **Path Variables:** Không có
- **Request Params:**
  ```
  productId: integer (required) - ID sản phẩm
  storeId: integer (optional) - ID cửa hàng
  ```
- **Request Body:** Không có
- **Response (ProductInventoryResponse):**
  ```
  {
    "productId": "integer",
    "storeId": "integer",
    "quantity": "integer"
  }
  ```

### 10.2 Get Inventory by Store
- **API:** `GET /api/inventory/store`
- **Mô Tả:** Lấy danh sách tồn kho trong một cửa hàng (phân trang)
- **Path Variables:** Không có
- **Request Params:**
  ```
  storeId: integer (optional) - ID cửa hàng
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<InventoryByStoreResponse>
  {
    "productId": "integer",
    "productName": "string",
    "quantity": "integer"
  }[]
  ```

---

## 1️⃣1️⃣ PURCHASE ORDER CONTROLLER

**Base URL:** `/api/purchase_order/`

### 11.1 Create Purchase Order
- **API:** `POST /api/purchase_order`
- **Mô Tả:** Tạo đơn đặt hàng từ nhà cung cấp
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (PurchaseOrderCreateDTO):**
  ```
  {
    "status": "integer (0=DRAFT, 1=COMPLETED, 4=CANCELLED)",
    "note": "string (optional)",
    "storeId": "integer (optional)",
    "providerId": "integer (required)",
    "purchaseOrderDetails": [
      {
        "productId": "integer (required)",
        "quantity": "integer (required, >= 1)",
        "price": "double (required, >= 0)"
      }
    ]
  }
  ```
- **Response (PurchaseOrderResponse):**
  ```
  {
    "id": "integer",
    "totalAmount": "double",
    "status": "integer",
    "note": "string",
    "userId": "integer",
    "storeId": "integer",
    "providerId": "integer",
    "createdAt": "LocalDateTime",
    "updatedAt": "LocalDateTime"
  }
  ```

### 11.2 Get List of Purchase Orders
- **API:** `GET /api/purchase_order`
- **Mô Tả:** Lấy danh sách đơn đặt hàng (phân trang, lọc, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  searching: string (optional) - Từ khóa tìm kiếm
  status: integer (optional) - Trạng thái
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<PurchaseOrderResponse>
  ```

### 11.3 Update Purchase Order Status
- **API:** `PATCH /api/purchase_order/{id}`
- **Mô Tả:** Cập nhật trạng thái đơn đặt hàng
- **Path Variables:**
  ```
  id: integer - ID đơn đặt hàng
  ```
- **Request Params:**
  ```
  status: integer (required)
  ```
- **Request Body:** Không có
- **Response (PurchaseOrderResponse):**

### 11.4 Get Purchase Report
- **API:** `GET /api/purchase_order/report`
- **Mô Tả:** Lấy báo cáo chi tiêu mua hàng (theo cửa hàng và khoảng thời gian)
- **Path Variables:** Không có
- **Request Params:**
  ```
  storeId: integer (default=-1, -1 = tất cả cửa hàng)
  start: LocalDateTime (optional) - Ngày bắt đầu
  end: LocalDateTime (optional) - Ngày kết thúc
  ```
- **Request Body:** Không có
- **Response (PurchaseReportResponse):**
  ```
  {
    "totalSpending": "double",
    "totalOrders": "integer",
    "byStore": {
      "storeId": {
        "storeName": "string",
        "spending": "double",
        "orderCount": "integer"
      }
    },
    "byProvider": {...}
  }
  ```

---

## 1️⃣2️⃣ CATEGORY CONTROLLER

**Base URL:** `/api/category/`

### 12.1 Get List of Categories
- **API:** `GET /api/category`
- **Mô Tả:** Lấy danh sách danh mục sản phẩm (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (default="") - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<CategoryResponse>
  {
    "categoryId": "integer",
    "categoryName": "string",
    "description": "string"
  }[]
  ```

---

## 1️⃣3️⃣ UNIT CONTROLLER

**Base URL:** `/api/unit/`

### 13.1 Get List of Units
- **API:** `GET /api/unit`
- **Mô Tả:** Lấy danh sách đơn vị tính (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  keyword: string (default="") - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<UnitResponse>
  {
    "id": "integer",
    "unitName": "string",
    "description": "string"
  }[]
  ```

---

## 1️⃣4️⃣ PROVIDER CONTROLLER

**Base URL:** `/api/provider/`

### 14.1 Create Provider
- **API:** `POST /api/provider`
- **Mô Tả:** Tạo nhà cung cấp (global)
- **Path Variables:** Không có
- **Request Params:** Không có
- **Request Body (ProviderCreateDTO):**
  ```
  {
    "providerName": "string (required)",
    "providerUei": "string (required)",
    "providerPhone": "string (required)",
    "providerAddress": "string (required)",
    "description": "string (optional)"
  }
  ```
- **Response (ProviderResponse):**
  ```
  {
    "id": "integer",
    "providerUei": "string",
    "providerName": "string",
    "providerPhone": "string",
    "providerAddress": "string",
    "status": "integer",
    "description": "string",
    "createdAt": "LocalDateTime",
    "updatedAt": "LocalDateTime"
  }
  ```

### 14.2 Get List of Providers
- **API:** `GET /api/provider`
- **Mô Tả:** Lấy danh sách nhà cung cấp (phân trang, tìm kiếm)
- **Path Variables:** Không có
- **Request Params:**
  ```
  searching: string (optional) - Từ khóa tìm kiếm
  page: integer (default=0)
  size: integer (default=20)
  ```
- **Request Body:** Không có
- **Response:**
  ```
  Page<ProviderResponse>
  ```

### 14.3 Get Provider by ID
- **API:** `GET /api/provider/{id}`
- **Mô Tả:** Lấy chi tiết nhà cung cấp
- **Path Variables:**
  ```
  id: integer - ID nhà cung cấp
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (ProviderResponse):**

### 14.4 Update Provider
- **API:** `PUT /api/provider/{id}`
- **Mô Tả:** Cập nhật thông tin nhà cung cấp
- **Path Variables:**
  ```
  id: integer - ID nhà cung cấp
  ```
- **Request Params:** Không có
- **Request Body (ProviderUpdateDTO):**
  ```
  {
    "providerName": "string (optional)",
    "providerPhone": "string (optional)",
    "providerAddress": "string (optional)",
    "description": "string (optional)",
    "status": "integer (optional)"
  }
  ```
- **Response (ProviderResponse):**

### 14.5 Change Provider Status
- **API:** `PATCH /api/provider/{id}/status`
- **Mô Tả:** Thay đổi trạng thái nhà cung cấp
- **Path Variables:**
  ```
  id: integer - ID nhà cung cấp
  ```
- **Request Params:**
  ```
  status: integer (required, 0=inactive, 1=active)
  ```
- **Request Body:** Không có
- **Response (ProviderResponse):**

---

## 1️⃣5️⃣ PRODUCT IMAGE CONTROLLER

**Base URL:** `/api/product/{productId}/images/`

### 15.1 Get Product Images
- **API:** `GET /api/product/{productId}/images`
- **Mô Tả:** Lấy tất cả ảnh của sản phẩm
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response (ProductImageListResponse):**
  ```
  {
    "mainImage": {
      "id": "integer",
      "imageUrl": "string"
    },
    "images": [
      {
        "id": "integer",
        "imageUrl": "string"
      }
    ]
  }
  ```

### 15.2 Upload Product Image
- **API:** `POST /api/product/{productId}/images`
- **Mô Tả:** Upload ảnh cho sản phẩm (multipart/form-data)
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  ```
- **Request Params:** Không có
- **Request Body:** multipart/form-data
  ```
  file: File (required) - File ảnh
  ```
- **Response (ProductImageResponse):**
  ```
  {
    "id": "integer",
    "imageUrl": "string"
  }
  ```

### 15.3 Set Main Image
- **API:** `PATCH /api/product/{productId}/images/{imageId}`
- **Mô Tả:** Đặt ảnh làm ảnh chính (hiển thị)
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  imageId: integer - ID ảnh
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:** Success message only

### 15.4 Delete Product Image
- **API:** `DELETE /api/product/{productId}/images/{imageId}`
- **Mô Tả:** Xóa ảnh của sản phẩm
- **Path Variables:**
  ```
  productId: integer - ID sản phẩm
  imageId: integer - ID ảnh
  ```
- **Request Params:** Không có
- **Request Body:** Không có
- **Response:** Success message only

---

## 📊 TÓM TẮT THỐNG KÊ

| Controller | POST | GET | PUT | PATCH | DELETE | Tổng |
|----------|------|-----|-----|-------|--------|------|
| Authentication | 2 | 0 | 0 | 0 | 0 | 2 |
| Product | 1 | 4 | 1 | 1 | 0 | 7 |
| Order | 1 | 3 | 1 | 2 | 0 | 7 |
| Cart | 1 | 1 | 1 | 0 | 2 | 5 |
| Rating | 1 | 2 | 1 | 1 | 1 | 6 |
| Promotion | 2 | 1 | 1 | 1 | 0 | 5 |
| Company | 1 | 1 | 1 | 0 | 0 | 3 |
| Store | 1 | 3 | 1 | 0 | 0 | 5 |
| User | 1 | 1 | 1 | 2 | 0 | 5 |
| Inventory | 0 | 2 | 0 | 0 | 0 | 2 |
| Purchase Order | 1 | 2 | 0 | 1 | 0 | 4 |
| Category | 0 | 1 | 0 | 0 | 0 | 1 |
| Unit | 0 | 1 | 0 | 0 | 0 | 1 |
| Provider | 1 | 2 | 1 | 1 | 0 | 5 |
| Product Image | 0 | 1 | 0 | 1 | 1 | 3 |
| **TOTAL** | **13** | **24** | **9** | **10** | **4** | **60** |

---

## 🔐 Ghi Chú Bảo Mật

- **JWT Bearer Token:** Tất cả API (trừ `/api/auth/login` và `/api/auth/signup`) yêu cầu header:
  ```
  Authorization: Bearer <JWT_TOKEN>
  ```

- **Authentication Header Format:**
  ```
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  ```

- **Token Expiry:** Kiểm tra expires_at trong JWT token

- **Role-Based Access Control:** Hệ thống có role (ADMIN, MANAGER, STAFF, CUSTOMER) nhưng hiện tại permitAll cho testing

---

## 🔄 Pagination Response Format

Tất cả API pagination trả về:
```json
{
  "content": [...items...],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20,
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "totalElements": 150,
  "totalPages": 8,
  "last": false,
  "size": 20,
  "number": 0,
  "sort": {...},
  "numberOfElements": 20,
  "first": true,
  "empty": false
}
```

---

## 📌 Common HTTP Status Codes

- **200 OK** - Request thành công
- **201 Created** - Resource được tạo thành công
- **400 Bad Request** - Dữ liệu không hợp lệ
- **401 Unauthorized** - Token không hợp lệ hoặc hết hạn
- **403 Forbidden** - Không có quyền truy cập
- **404 Not Found** - Resource không tồn tại
- **500 Internal Server Error** - Lỗi server

---

## 📝 Response Wrapper Format

Tất cả response được bao bọc trong `ApiResponse<T>`:
```json
{
  "status": "success" | "error",
  "message": "string (mô tả)",
  "data": T | null,
  "timestamp": "LocalDateTime"
}
```

---

**Tài liệu này được cập nhật lần cuối:** May 2, 2026
