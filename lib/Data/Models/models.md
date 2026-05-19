## Models

Thu muc nay chua cac Dart model map 1-1 hoac gan 1-1 voi response backend. Day la tang du lieu cho FE, khong phai noi xu ly logic nghiep vu. Neu model khong dung voi JSON backend, UI se sai ngay tu buoc render dau tien.

### Nguyen tac bat buoc

- Giu ten field trung voi JSON backend, chi doi ten trong Dart neu co helper `fromJson`/`toJson` ro rang.
- Khong dung chung 1 model cho hai man hinh co quyen khac nhau neu backend tra ve khac nhau, dac biet la `customer` va `manage`.
- Khong cho UI tu tinh lai nhung truong backend da tra ve san nhu `totalPrice`, `subtotal`, `totalAmount` neu response da co.
- Cac field `status`, `paymentStatus`, `discountType`, `scope`, `roleName` phai duoc map qua helper display thay vi hien raw number.
- Cac field datetime nen parse ve `DateTime` o model neu app can sort/filter/format theo ngay gio.
- Neu backend tra ve `Page<T>` thi phai co model wrapper pagination rieng, khong duoc ep ve `List<T>` thuong.

### Cac lop model can co

#### 1. Auth

- `LoginResponse`: chua `token` va `user`.
- `UserResponse`: dung cho profile, menu role, thong tin company/store, diem tich luy.

Luu y:

- Sau login, FE can luu `token` va `user` ngay de set permission/menu.
- `companyId`, `storeId`, `roleName` la du lieu dieu huong UI, khong phai du lieu de FE tu y ghi them vao request neu backend khong yeu cau.

#### 2. Product

- `ProductResponse`: model chinh cho list/detail san pham.
- `ProductInfoDetailResponse`: view chi tiet san pham cho customer.
- `ProductInfoDetailResponseM`: view chi tiet san pham cho manage.
- `ProductInventoryResponse`: ton kho san pham theo cua hang.
- `ProductReportProjection`: row tong hop cho table/summary report.
- `ProductReportDetailResponse`: tong hop bao cao 1 san pham.
- `ProductOrderHistoryResponse`: lich su don hang cua san pham.

Khuyen nghi render:

- Customer view chi hien gia ban, hinh, mo ta, danh muc, don vi, rating.
- Manage view hien them gia von, gia goc, barcode, categoryIds, ton kho va nut cap nhat.
- `categoryIds` va `categoryNames` nen de dung cho both edit form va table display.

#### 3. Cart

- `CartResponse`: thong tin gio hang hien tai.
- `CartItemResponse`: tung dong san pham trong gio.

Khuyen nghi render:

- `totalAmount` la so tong cuoi cung cua gio hang.
- `totalPrice` la tong cua 1 item = `sellPrice * quantity`.
- FE khong nen tu tinh lai tong neu backend da tra ve, chi dung de fallback khi can tinh preview.

#### 4. Order

- `OrderResponse`: dung cho chi tiet don.
- `OrderListResponse`: dung cho table danh sach don.
- `OrderItemResponse`: tung dong san pham trong don.
- `OrderInfoResponseM`: view don cho manager/admin.
- `OrderInfoResponseC`: view don cho customer.
- `RevenueOverTimeReportResponse`: bao cao doanh thu theo khoang thoi gian.
- `SalesStatisticsResponseResponse`: bao cao doanh so/ton kho/chi phi.

Khuyen nghi render:

- `OrderListResponse` chi de render danh sach, khong nen lay thay `OrderResponse`.
- `paymentMethod`, `paymentStatus`, `status` can map thanh badge/label de dong nhat toan app.
- `earnPoint` va `redeemPoint` phai duoc hien thanh khung tong ket, khong nhung trong danh sach item.
- `storeId` va `storeName` la bat buoc neu muon render don tach theo cua hang.

#### 5. Promotion

- `PromotionResponse`: dung cho chi tiet va form edit.
- `PromotionListResponse`: dung cho table danh sach.

Khuyen nghi render:

- `scope = 0` la khuyen mai cho don hang.
- `scope = 1` la khuyen mai cho san pham.
- `status` phai duoc hien thanh badge active/inactive/expired.

#### 6. Purchase order

- `PurchaseOrderResponse`: thong tin phieu nhap.
- `PurchaseOrderDetailResponse`: tung dong chi tiet phieu nhap.

Khuyen nghi render:

- Danh sach phieu nhap chi can `id`, `status`, `totalAmount`, `providerId`, `storeId`, `createdAt`.
- Man hinh detail moi can nested detail items.

#### 7. Master data

- `CompanyResponse`
- `StoreResponse`
- `ProviderResponse`
- `CategoryResponse`
- `UnitResponse`

Khuyen nghi render:

- Cac danh muc nay thuong dung cho select, filter, and table.
- `ProviderResponse` va `StoreResponse` nen co `status`/`createdAt` de FE co the loc va render badge.
- `StoreResponse` nen co them `latitude` va `longitude` de FE co the hien map hoac kiem tra dia diem neu can.

#### 8. Rating va inventory

- `RatingResponse`
- `InventoryResponse`
- `InventoryByStoreResponse`

Khuyen nghi render:

- `RatingResponse.rating` nen render bang sao.
- `InventoryResponse.quantity` va `InventoryByStoreResponse.quantity` phai canh bao khi thap.

#### 9. Media

- `ProductImageResponse`
- `ProductImageListResponse`
- `CloudResponse`

Khuyen nghi render:

- `ProductImageListResponse.mainImage` la anh chinh.
- `images` la danh sach anh phu.
- `CloudResponse` chi dung luc upload, khong phai model hien thi thuong xuyen.

### Model pagination can tach rieng

Khi backend tra ve `Page<T>`, FE nen tao 1 model chung nhu:

- `PageResponse<T>` voi cac field: `content`, `number`, `size`, `totalElements`, `totalPages`, `first`, `last`, `numberOfElements`.

De tranh loi, khong nen mapping pagination thanh `List<T>` thuong va mat metadata phan trang.

### Cach to chuc file trong Flutter

- Moi feature nen co 1 file model rieng.
- Model dung chung cho nhieu man hinh chi nen tach ra neu JSON khac nhau khong dang ke.
- Neu co `customer` va `manage` version, dat ten ro rang theo muc dich, khong dat ten chung chung.

### Ket luan cho FE

Model o day khong chi la class map JSON, ma la hop dong giup UI biet:

- du lieu nao la dung de hien thi,
- du lieu nao chi dung de set quyen/hieu trang thai,
- du lieu nao la tinh san tu backend,
- va man hinh nao phai dung model nao.

Lam dung theo nguyen tac nay thi FE se code duoc truoc, it gap sai khac contract, va de mo rong ve sau.

