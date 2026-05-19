## Services

Lop `services` la noi dat cau hinh HTTP va quy tac giao tiep voi backend.

### Cau hinh chung

- Base URL nen tap trung o 1 file.
- Dung Dio hoac HTTP client tuong duong.
- Tu dong chen header `Authorization` neu token ton tai.
- Xu ly `ApiResponse` va map loi tu HTTP status code.
- Khong cho UI goi thang API; moi man hinh phai di qua repository/service va provider.

### Quy uoc parse response

- `status == success`: doc `data` va cap nhat state.
- `status == error`: doc `message`, neu `data` la map validation thi gan theo tung field.
- Voi `Page<T>`, FE can map `content`, `totalPages`, `number`, `size`, `totalElements`.
- Response khac nhau theo role can duoc xu ly theo man hinh, khong ep chung mot model neu field khac nhau qua nhieu.

### Header can thiet

- `Content-Type: application/json` cho API JSON.
- `Authorization: Bearer <token>` cho API da bao ve.
- `multipart/form-data` cho upload anh san pham.

### Contract backend can biet

- Wrapper success: `status`, `message`, `data`.
- Loi validation tra ve map `field -> message` trong `data`.
- 401 dung cho token sai/het han/khong dang nhap.
- 403 dung cho khong du quyen.
- 404 thuong la resource khong ton tai, khong phai loi UI.
- 500 chi dung cho loi he thong.
- Neu backend tra ve list response, FE phai giu nguyen list, khong ep ve object don.

### Cach xu ly theo nhom API

- Auth: luu token va user sau login; khi logout xoa toan bo session local.
- List API: ho tro `search`, `page`, `size`, va filter theo status/date/store neu co.
- Detail API: load bo sung anh, danh gia, report, inventory sau neu man hinh can.
- Mutation API: create/update/status/delete phai refresh lai list hoac detail ngay sau khi thanh cong.
- Upload anh: dung `multipart/form-data`, hien progress neu co the.

### Danh muc endpoint chinh

#### Auth

- `POST /api/auth/login`
- `POST /api/auth/signup`

#### User

- `POST /api/user`
- `GET /api/user`
- `PATCH /api/user/{id}?status=`
- `PUT /api/user/profile`
- `PATCH /api/user/password`

#### Product

- `POST /api/product`
- `GET /api/product`
- `PUT /api/product/{id}`
- `PATCH /api/product/{id}/status`
- `GET /api/product/{id}/customer`
- `GET /api/product/{id}/manage`
- `GET /api/product/{id}/inventory/{storeId}`
- `GET /api/product/report`
- `GET /api/product/report/{productId}`
- `GET /api/product/store`

#### Product image

- `GET /api/product/{productId}/images`
- `POST /api/product/{productId}/images`
- `PATCH /api/product/{productId}/images/{imageId}`
- `DELETE /api/product/{productId}/images/{imageId}`

#### Inventory

- `GET /api/inventory`
- `GET /api/inventory/store`

#### Cart

- `POST /api/cart/items`
- `PATCH /api/cart/items/{productId}`
- `DELETE /api/cart/items/{productId}`
- `GET /api/cart`
- `DELETE /api/cart/clear`

#### Order

- `POST /api/order`
- `PUT /api/order/{id}`
- `GET /api/order/{id}`
- `GET /api/order`
- `PATCH /api/order/{id}/status`
- `PATCH /api/order/{id}/payment`
- `GET /api/order/report`
- `POST /api/order` co the tra ve `List<OrderResponse>` neu don duoc tach theo store.
- Moi order response nen duoc render rieng theo `storeId`/`storeName`.

#### Rating

- `POST /api/rating`
- `PUT /api/rating/{id}`
- `GET /api/rating/product/{productId}`
- `GET /api/rating/user`
- `PATCH /api/rating/{id}/status`
- `DELETE /api/rating/{id}`

#### Purchase order

- `POST /api/purchase_order`
- `GET /api/purchase_order`
- `PATCH /api/purchase_order/{id}?status=`
- `GET /api/purchase_order/report`

#### Promotion

- `POST /api/promotion/product`
- `POST /api/promotion/order`
- `PUT /api/promotion/{promotionId}`
- `PATCH /api/promotion/{promotionId}?status=`
- `GET /api/promotion/company/{companyId}`

#### Master data

- `GET /api/category`
- `GET /api/unit`
- `POST /api/company`
- `GET /api/company`
- `PUT /api/company/{id}`
- `POST /api/store`
- `GET /api/store`
- `GET /api/store/all`
- `PUT /api/store/{id}`
- `POST /api/provider`
- `GET /api/provider`
- `GET /api/provider/{id}`
- `PUT /api/provider/{id}`
- `PATCH /api/provider/{id}/status`

### Muc uu tien implement cho FE

1. Auth + AppShell + sidebar.
2. Product list/detail/manage + image upload.
3. Order create/list/detail/status/payment.
4. Cart va checkout.
5. Inventory, purchase order, promotion, rating.
6. Master data CRUD.

### Goi y xu ly loi

- Neu status la 400 do validation, hien field error gan form.
- Neu status la 401, dua user ve man login va clear token.
- Neu status la 403, hien thong bao khong co quyen.
- Neu status la 404, hien empty/failed state tuy nguyen nhan, khong coi la crash.
- Neu status la 500, hien toast/alert loi he thong va cho thu lai.

services/:

Ý nghĩa: Đây là "trạm viễn thông". Nơi đặt các cấu hình HTTP (Dio).

Tại sao: Nếu sau này Backend đổi từ http sang https, hoặc đổi Base URL, bạn chỉ cần vào đúng một file trong này để sửa thay vì lục lọi khắp cả dự án.