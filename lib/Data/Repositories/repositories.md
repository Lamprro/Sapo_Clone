## Repositories

Repository la tang dieu phoi giua `services` va `providers`.

### Vai tro

- Goi HTTP service va chuyen JSON thanh model.
- Giu logic retry/cache/offline neu sau nay can.
- Bao ve provider khoi chi tiet giao thuc API.

### Khoi de xuat theo feature

- `AuthRepository`: login, signup, luu token.
- `UserRepository`: create user, get list, update profile, change password, change status.
- `ProductRepository`: create/update/get detail/get list/report/get inventory/get by store.
- `ProductImageRepository`: list, upload multipart, set main, delete.
- `InventoryRepository`: get inventory by product/store, get inventory by store.
- `CartRepository`: add/update/delete/clear/get cart.
- `OrderRepository`: create/update/get list/detail/change status/change payment/report.
- `RatingRepository`: create/update/list/delete/change status.
- `PurchaseOrderRepository`: create/list/report/change status.
- `PromotionRepository`: create/update/list/change status.
- `MasterDataRepository`: company, store, provider, category, unit.

### Quy uoc thiet ke

- Tat ca method nen return `Future<Result<T>>` hoac `Future<Either<Failure, T>>` neu project co pattern nay.
- Repository khong nen parse logic nghiep vu phuc tap; chi map data va tra ve model.
- Neu API tra ve `ApiResponse` thi repository nen unwrap `data` va giu lai `message` khi can hien thi thong bao.

### Ghi chu cho FE

- Khi goi API da login, repository phai tu them auth header tu token local.
- Voi endpoint co `page`, `size`, `keyword`, `status`, `storeId`, `start`, `end`, repo nen nhan tham so ro rang thay vi dung 1 map chung de tranh nham field.
repositories/:

Ý nghĩa: Đây là "người điều phối". Nó đứng giữa API Service và Provider.

Tại sao: Giúp code sạch hơn. Provider chỉ cần ra lệnh: "Lấy cho tôi danh sách sản phẩm", còn việc lấy từ API hay lấy từ bộ nhớ đệm (Cache) trong máy là việc của Repo.