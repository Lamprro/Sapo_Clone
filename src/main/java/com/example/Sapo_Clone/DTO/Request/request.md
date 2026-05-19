## API Request Reference

Tai lieu nay la contract request chuan cho FE Flutter. Khi tao form hay mapping model, can giu dung ten field ben duoi.

## 1. Auth

### `POST /api/auth/login`

Request body:

```json
{
	"username": "admin01",
	"password": "123456",
	"companyId": 1
}
```

### `POST /api/auth/signup`

Request body:

```json
{
	"fullName": "Nguyen Van A",
	"phone": "0912345678",
	"email": "a@gmail.com",
	"username": "a01",
	"password": "123456",
	"repeatPassword": "123456",
	"companyId": 1,
	"address": "Ha Noi",
	"roleId": 4,
	"storeId": 1
}
```

## 2. User

### `POST /api/user`

```json
{
	"fullName": "Nguyen Van A",
	"phone": "0912345678",
	"email": "a@gmail.com",
	"username": "a01",
	"password": "123456",
	"companyId": 1,
	"address": "Ha Noi",
	"storeId": 1,
	"roleId": 3
}
```

### `PATCH /api/user/{id}?status=`

- Path param: `id`
- Query param: `status`

### `PUT /api/user/profile`

```json
{
	"fullName": "Nguyen Van A",
	"phone": "0912345678",
	"email": "a@gmail.com",
	"address": "Ha Noi"
}
```

### `PATCH /api/user/password`

```json
{
	"id": 1,
	"oldPassword": "123456",
	"newPassword": "1234567",
	"confirmPassword": "1234567"
}
```

## 3. Product

### `POST /api/product` and `PUT /api/product/{id}`

```json
{
	"productName": "Ao thun",
	"description": "Ao thun cotton",
	"barcode": "SP001",
	"importPrice": 50000,
	"sellPriceOriginal": 80000,
	"sellPrice": 75000,
	"unitId": 1,
	"categoryIds": [1, 2]
}
```

### `PATCH /api/product/{id}/status`

```json
{
	"status": 1
}
```

### Query params cho list/product search

- `GET /api/product?keyword=&page=&size=`
- `GET /api/product/store?page=&size=`
- `GET /api/product/report/{productId}?page=&size=`

## 4. Product image

### `POST /api/product/{productId}/images`

- `multipart/form-data`
- field file: `file`

### `PATCH /api/product/{productId}/images/{imageId}`

- No body, dung de set anh main.

## 5. Cart

### `POST /api/cart/items`

```json
{
	"productId": 1,
	"quantity": 2
}
```

### `PATCH /api/cart/items/{productId}`

```json
{
	"quantity": 3
}
```

## 6. Order

### `POST /api/order`

```json
{
	"customerId": 1,
	"employeeId": 2,
	"storeId": 1,
	"promotionId": 3,
	"paymentMethod": "CASH",
	"shippingAddress": "Ha Noi",
	"note": "Giao buoi sang",
	"earnPoint": 10,
	"redeemPoint": 0,
	"orderDetails": [
		{
			"productId": 1,
			"quantity": 2
		}
	]
}
```

### `PUT /api/order/{id}`

```json
{
	"paymentMethod": "TRANSFER",
	"shippingAddress": "Ha Noi",
	"note": "Cap nhat ghi chu",
	"items": [
		{
			"productId": 1,
			"quantity": 3
		}
	]
}
```

### `PATCH /api/order/{id}/status`

```json
{
	"status": 1
}
```

### `PATCH /api/order/{id}/payment`

```json
{
	"paymentStatus": 1
}
```

### Query params

- `GET /api/order?status=&keyword=&page=&size=`
- `GET /api/order/report?storeId=&start=&end=`

## 7. Rating

### `POST /api/rating`

```json
{
	"rating": 5,
	"comment": "San pham tot",
	"productId": 1
}
```

### `PUT /api/rating/{id}`

```json
{
	"rating": 4,
	"comment": "Da dung lai",
	"status": 1
}
```

### `PATCH /api/rating/{id}/status?status=`

- Query param: `status`

## 8. Purchase order

### `POST /api/purchase_order`

```json
{
	"status": 0,
	"note": "Nhap hang thang 4",
	"storeId": 1,
	"providerId": 2,
	"purchaseOrderDetails": [
		{
			"productId": 1,
			"quantity": 10,
			"price": 50000
		}
	]
}
```

### `PATCH /api/purchase_order/{id}?status=`

- Query param: `status`

### `GET /api/purchase_order/report?storeId=&start=&end=`

## 9. Promotion

### `POST /api/promotion/product` and `POST /api/promotion/order`

```json
{
	"promotionName": "Giam 10%",
	"description": "Khuyen mai mua hang",
	"scope": 0,
	"discountType": 1,
	"discountValue": 10,
	"maxAccount": 100000,
	"minAccount": 200000,
	"startDate": "2026-04-29T08:00:00",
	"endDate": "2026-05-10T23:59:59",
	"productIds": [1, 2]
}
```

### `PATCH /api/promotion/{promotionId}?status=`

- Query param: `status`

## 10. Company / Store / Provider / Master data

### `POST /api/company`

```json
{
	"companyName": "Sapo Clone",
	"companyAddress": "Ha Noi"
}
```

### `PUT /api/company/{id}`

```json
{
	"companyName": "Sapo Clone",
	"companyAddress": "Ho Chi Minh"
}
```

### `POST /api/store`

```json
{
	"storeName": "Chi nhanh 1",
	"storeAddress": "Da Nang"
}
```

### `PUT /api/store/{id}`

```json
{
	"storeName": "Chi nhanh 1",
	"storeAddress": "Da Nang"
}
```

### `POST /api/provider`

```json
{
	"providerName": "Nha cung cap A",
	"providerUei": "UEI001",
	"providerPhone": "0912345678",
	"providerAddress": "Ha Noi",
	"description": "Doi tac chinh"
}
```

### `PUT /api/provider/{id}`

```json
{
	"providerName": "Nha cung cap A",
	"providerPhone": "0912345678",
	"providerAddress": "Ha Noi",
	"description": "Cap nhat mo ta",
	"status": 1
}
```

### Category, Unit

- `GET /api/category?keyword=&page=&size=`
- `GET /api/unit?keyword=&page=&size=`
