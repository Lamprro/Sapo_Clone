## API Response Reference

Moi API backend deu wrap trong `ApiResponse<T>`:

```json
{
	"status": "success",
	"message": "...",
	"data": {}
}
```

Neu loi:

```json
{
	"status": "error",
	"message": "...",
	"data": null
}
```

### Cach FE nen su dung

- `status` dung de phan loai thanh cong hay that bai.
- `message` dung cho toast/snackbar/alert.
- `data` dung cho noi dung chinh, khong nen doc tu `message` de render logic nghiep vu.
- Voi `Page<T>`, FE can render `content` la danh sach chinh va `totalElements`/`totalPages` de phan trang.
- Voi man hinh Sapo-like, moi trang danh sach nen co `search`, `filter`, `bulk action`, `row action`, `empty state`.

### Quy uoc trang thai chung

- `0` thuong la draft/inactive/pending.
- `1` thuong la active/paid/completed tuy domain.
- `2` thuong la blocked/shipping/expired tu tung nghiep vu.
- FE phai hien badge theo ngu nghia nghiep vu, khong chi hien so.

## 1. Auth response

### `LoginResponse`

```json
{
	"token": "jwt-token",
	"user": {
		"id": 1,
		"fullName": "Nguyen Van A",
		"email": "a@gmail.com",
		"username": "a01",
		"phone": "0912345678",
		"address": "Ha Noi",
		"status": 1,
		"createdAt": "2026-04-29T08:00:00",
		"updatedAt": "2026-04-29T08:00:00",
		"roleName": "ADMIN",
		"companyId": 1,
		"storeId": 1,
		"pointValue": 0
	}
}
```

### `UserResponse`

- `id`
- `fullName`
- `email`
- `username`
- `phone`
- `address`
- `status`
- `createdAt`
- `updatedAt`
- `roleName`
- `companyId`
- `storeId`
- `pointValue`

### Ghi chu cho man hinh login/profile

- Sau login, FE can luu `token` va `user` de set role/menu ngay.
- `companyId` va `storeId` phai duoc dung de boi neu backend can xu ly theo cong ty/cua hang hien tai.
- `pointValue` la du lieu display cho customer profile/loyalty badge.

## 2. Product response

### `ProductResponse`

- `id`
- `productName`
- `description`
- `barcode`
- `avgStar`
- `status`
- `importPrice`
- `sellPriceOriginal`
- `sellPrice`
- `unitId`
- `unitName`
- `categoryIds`
- `categoryNames`

### Cach hien thi cho Sapo-like product page

- Table list: `productName`, `barcode`, `unitName`, `sellPrice`, `status`, `avgStar`.
- Card/detail: anh dai dien, mo ta, gia, danh muc, ton kho, rating.
- Manage form: them `importPrice`, `sellPriceOriginal`, `categoryIds`, `unitId`.
- Customer detail: chi hien truong can mua hang, khong nen hien gia von.

### `ProductInfoDetailResponse` / `ProductInfoDetailResponseM`

- `id`
- `productName`
- `description`
- `barcode`
- `avgStar`
- `sellPrice` hoac them `importPrice`, `sellPriceOriginal` voi ban manage
- `companyName`
- `unitName`
- `status`
- `ProductImageResponses`
- `categories`
- `ratings`
- `companyName` de FE biet san pham thuoc company nao khi can hien multi-tenant.

### `ProductReportProjection`

- `productId`
- `productName`
- `totalSellQuantity`
- `totalRevenue`
- `totalProfit`
- `evaluationScore`

### `ProductReportDetailResponse`

- `productId`
- `productName`
- `totalSellQuantity`
- `totalRevenue`
- `totalProfit`
- `evaluationScore`
- `orderHistory` la `Page<ProductOrderHistoryResponse>`

### `ProductOrderHistoryResponse`

- `orderId`
- `customerName`
- `quantity`
- `price`
- `subtotal`
- `createdAt`

### `ProductInventoryResponse`

- `productId`
- `storeId`
- `quantity`


## 3. Cart response

### `CartResponse`

- `cartId`
- `items`
- `totalAmount`

### `CartItemResponse`

- `productId`
- `productName`
- `sellPrice`
- `quantity`
- `totalPrice`

### Cach hien thi cart

- Mo rang tren desktop: danh sach item + sticky summary.
- Tren mobile: card tung san pham + subtotal + quantity stepper.
- `totalAmount` la tong hien tai cua gio hang, dung de show o footer checkout.

## 4. Order response

### `OrderResponse`

- `id`
- `storeId`
- `storeName`
- `status`
- `totalAmount`
- `paymentMethod`
- `paymentStatus`
- `createdAt`
- `shippingAddress`
- `note`
- `items`
- `promotionId`

### Ghi chu cho FE khi tao don

- API tao don co the tra ve nhieu `OrderResponse` neu don bi tach theo store.
- Moi `OrderResponse` tuong ung voi 1 store khac nhau.
- FE phai render tung don rieng, khong gop lai thanh 1 order duy nhat.

### `OrderListResponse`

- `id`
- `storeId`
- `storeName`
- `status`
- `totalAmount`
- `customerName`
- `createdAt`
- `paymentMethod`
- `paymentStatus`

### `OrderItemResponse`

- `productId`
- `productName`
- `quantity`
- `price`
- `subtotal`

### `OrderInfoResponseM`

- `id`
- `shippingAddress`
- `totalAmount`
- `status`
- `redeemPoint`
- `earnPoint`
- `createdAt`
- `updatedAt`
- `paymentMethod`
- `note`
- `customerId`
- `employeeId`
- `promotionId`
- `storeId`

### `OrderInfoResponseC`

- `id`
- `storeId`
- `orderDate`
- `totalAmount`
- `status`
- `shippingAddress`
- `paymentMethod`
- `customerId`
- `earnPoint`
- `promotionId`

### Bang trang thai order

- `0`: pending.
- `1`: confirmed.
- `2`: shipping.
- `3`: completed.
- `4`: cancelled.

### Bang payment status

- `0`: unpaid.
- `1`: paid.
- `2`: failed.
- `3`: refunded.

### Bao cao order

- `RevenueOverTimeReportResponse`
- `SalesStatisticsResponseResponse`

## 5. Rating response

### `RatingResponse`

- `id`
- `rating`
- `comment`
- `userId`
- `userFullName`
- `updatedAt`
- `productId`

### `RatingResponse` cho UI

- Customer xem list rating cua minh.
- Product detail xem rating list theo san pham.
- Rating badge nen map sao 1-5 thanh icon + text mo ta ngan.

## 6. Purchase order response

### `PurchaseOrderResponse`

- `id`
- `totalAmount`
- `status`
- `note`
- `userId`
- `storeId`
- `providerId`
- `createdAt`
- `updatedAt`

### `PurchaseOrderDetailResponse`

- `id`
- `quantity`
- `price`
- `subtotal`
- `purchaseOrderId`
- `ProductResponse`

### `PurchaseReportResponse`

- `totalExpenditure`
- `totalOrders`
- `orders`

## 7. Promotion response

### `PromotionResponse`

- `id`
- `scope`
- `promotionName`
- `discountValue`
- `discountType`
- `maxAccount`
- `minAccount`
- `description`
- `startDate`
- `endDate`
- `status`
- `productIds`

### `PromotionListResponse`

- Giong `PromotionResponse` nhung khong co `productIds`.
- Dung cho list, filter, va table mode.

### Status va scope can nho

- `scope = 0`: order promotion.
- `scope = 1`: product promotion.
- `status = 1`: active.
- `status = 0`: inactive.
- `status = 2`: expired/closed neu backend cap nhat theo scheduler.

## 8. Master data response

### `CompanyResponse`

- `id`
- `companyName`
- `companyAddress`
- `createdAt`

### `StoreResponse`

- `id`
- `storeName`
- `companyId`
- `storeAddress`
- `latitude`
- `longitude`
- `createdAt`

### Ghi chu ve cua hang va distance

- `latitude` va `longitude` la du lieu bat buoc de backend co the tim store gan nhat.
- Khi create/update store, backend se co gang geocode tu `storeAddress` neu FE khong truyen `latitude`/`longitude`.
- FE co the hien map, checkbox "gan toi nhat", hoac filter theo store nhung khong can tu tinh distance.

### `ProviderResponse`

- `id`
- `providerUei`
- `providerName`
- `providerPhone`
- `providerAddress`
- `status`
- `description`
- `createdAt`
- `updatedAt`

### `CategoryResponse`

- `categoryId`
- `categoryName`
- `description`

### `UnitResponse`

- `id`
- `unitName`
- `description`

### `InventoryResponse`

- `id`
- `productId`
- `quantity`
- `storeId`

### `InventoryByStoreResponse`

- `productId`
- `productName`
- `quantity`

## 9. Media response

### `ProductImageResponse`

- `id`
- `imageUrl`

### `ProductImageListResponse`

- `mainImage`
- `images`

### `CloudResponse`

- `imageUrl`
- `publicId`

## 10. Error response

- Validation error: `data` la map field -> message.
- 401: dang nhap sai, het han token, hoac chua co token.
- 403: khong co quyen.
- 404: resource khong ton tai.
- 500: loi he thong.

### Luu y cho FE

- Khong dung `message` de suy luan business state.
- Validation error phai hien ngay duoi field form.
- 404 co the hien empty state hoac not found state tuy nguyen nhan.
- Voi man hinh Sapo-like, nen map status sang badge ngay trong model/helper de table render dong nhat.
