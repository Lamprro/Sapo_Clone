## Screens

Thu muc nay chua cac man hinh lon cua app Flutter. Moi man hinh nen map voi 1 hoac nhieu API backend ro rang.

### Khung chung cho moi man hinh

Moi trang nghiep vu nen co:

- Header voi tieu de va nut hanh dong chinh.
- Thanh tim kiem/loc neu backend co ho tro.
- Danh sach dang table tren desktop va card tren mobile.
- Modal/drawer cho create/update nhanh.
- Badge status va action menu o cuoi dong.

Voi giao dien kieu Sapo, cac man hinh quan tri nen uu tien:

- Toc do thao tac nhanh.
- It chuyen trang con.
- Hien thi duoc nhieu du lieu tren 1 man hinh.
- Co bo loc theo trang thai, ngay, cua hang, nhom san pham, nguoi tao.

### 1. LoginScreen

- Muc dich: dang nhap vao he thong theo `username + password + companyId`.
- API: `POST /api/auth/login`.
- Output can dung: `token`, `user.fullName`, `user.roleName`, `user.companyId`, `user.storeId`.
- UI can co: logo, form 3 truong, remember me neu can, va switch company neu user co nhieu cong ty.

### 2. SignUpScreen

- Muc dich: tao tai khoan moi.
- API: `POST /api/auth/signup`.
- Validation can co: phone format VN, password >= 6 ky tu, `password` va `repeatPassword` phai trung nhau.
- Form nen chia theo nhom: thong tin ca nhan, thong tin tai khoan, cong ty/cua hang neu co quyen tao.

### 3. Home/ProductListScreen

- Muc dich: hien thi danh sach san pham, tim kiem, phan trang.
- API: `GET /api/product`, `GET /api/product/store`, `GET /api/category`, `GET /api/unit`.
- UI can biet: `productName`, `sellPrice`, `avgStar`, `status`, `unitName`, `categoryNames`.
- Layout de xuat: card KPI phia tren, filter bar o dau trang, table co cot `ma`, `ten`, `danh muc`, `don vi`, `gia ban`, `ton`, `trang thai`, `action`.
- Row action nen gom: xem, sua, doi trang thai, quan ly anh, xem report neu role cho phep.

### 4. ProductDetailScreen

- Muc dich: xem chi tiet san pham theo quyen customer/manage.
- API: `GET /api/product/{id}/customer` hoac `GET /api/product/{id}/manage`.
- Neu can anh va danh gia: goi them `GET /api/product/{productId}/images` va `GET /api/rating/product/{productId}`.
- Customer view chi hien gia ban, anh, mo ta, danh gia, thong tin don vi, ton kho neu cho phep.
- Manage view hien them gia von, gia goc, barcode, category ids, report, va nut cap nhat.

### 5. CartScreen

- Muc dich: quan ly san pham da them vao gio hang.
- API: `GET /api/cart`, `POST /api/cart/items`, `PATCH /api/cart/items/{productId}`, `DELETE /api/cart/items/{productId}`, `DELETE /api/cart/clear`.
- UI can tong hop: `items`, `totalAmount`, `quantity`, `totalPrice`.
- Can co sticky summary o ben phai hoac duoi man hinh: tong tien, so luong, nut thanh toan.

### 6. OrderScreen va OrderDetailScreen

- Muc dich: tao don, cap nhat don, xem danh sach/chi tiet, doi trang thai va thanh toan.
- API: `POST /api/order`, `PUT /api/order/{id}`, `GET /api/order`, `GET /api/order/{id}`, `PATCH /api/order/{id}/status`, `PATCH /api/order/{id}/payment`.
- Trang bao cao: `GET /api/order/report`.
- `POST /api/order` co the tra ve `List<OrderResponse>` neu don bi tach theo nhieu store.
- Moi order tra ve co `storeId`, `storeName`, `items`, `totalAmount`, `paymentStatus`, `createdAt` de FE render tung don rieng.
- List don nen co filter theo `status`, `paymentStatus`, `store`, `keyword`, `date`.
- Chi tiet don nen co 3 khoi ro: thong tin khach hang, danh sach san pham, tong ket thanh toan/diem/khuyen mai.

### 7. RatingScreen

- Muc dich: cho phep customer danh gia san pham va xem lich su rating.
- API: `POST /api/rating`, `PUT /api/rating/{id}`, `GET /api/rating/user`, `GET /api/rating/product/{productId}`.
- UI can co star picker, comment box, va list lich su rating cua toi.

### 8. InventoryScreen

- Muc dich: xem ton kho theo san pham, theo cua hang.
- API: `GET /api/inventory`, `GET /api/inventory/store`, `GET /api/product/{id}/inventory/{storeId}`.
- Table nen hien `san pham`, `cua hang`, `so luong`, `muc canh bao`, `hanh dong dieu chinh` neu role duoc phep.

### 9. ProductManageScreen

- Muc dich: them/sua/xoa/doi trang thai san pham, quan ly anh va bao cao san pham.
- API: `POST /api/product`, `PUT /api/product/{id}`, `PATCH /api/product/{id}/status`, `GET /api/product/report`, `GET /api/product/report/{productId}`, `GET /api/product/{productId}/images`.
- Form san pham nen co cac phan: thong tin co ban, gia ban, danh muc, don vi, anh san pham, trang thai.
- Bao cao san pham nen co chart + table lich su don hang san pham.

### 10. PurchaseOrderScreen

- Muc dich: tao phieu nhap va xem lich su nhap.
- API: `POST /api/purchase_order`, `GET /api/purchase_order`, `PATCH /api/purchase_order/{id}?status=`, `GET /api/purchase_order/report`.
- Form phieu nhap can co: nha cung cap, cua hang, ghi chu, danh sach chi tiet nhap, tong tien tam tinh.
- Khi da completed thi can dong bo ton kho ngay.

### 11. PromotionScreen

- Muc dich: tao va quan ly khuyen mai theo order/product.
- API: `POST /api/promotion/order`, `POST /api/promotion/product`, `PUT /api/promotion/{promotionId}`, `PATCH /api/promotion/{promotionId}?status=`, `GET /api/promotion/company/{companyId}`.
- List khuyen mai nen co tag `order` hoac `product`, ngay bat dau/ket thuc, trang thai va so san pham anh huong.

### 12. MasterDataScreens

- CompanyScreen: `POST/GET/PUT /api/company`.
- StoreScreen: `POST/GET/PUT /api/store`.
- ProviderScreen: `POST/GET/PUT /api/provider`, `GET /api/provider/{id}`, `PATCH /api/provider/{id}/status`.
- CategoryScreen: `GET /api/category`.
- UnitScreen: `GET /api/unit`.
- UserScreen: `POST /api/user`, `GET /api/user`, `PATCH /api/user/{id}?status=`, `PUT /api/user/profile`, `PATCH /api/user/password`.

### Menu va quyen goi y

- Admin: all menu.
- Manager: product, order, inventory, promotion, purchase order, user, master data trong company.
- Employee: ban hang, order, inventory, rating, customer list, profile.
- Customer: product, cart, order cua toi, rating cua toi, profile.