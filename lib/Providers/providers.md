## Providers

Provider la noi nam state cua tung nghiep vu va dieu phoi UI.

### Nhiem vu

- Giu data hien tai cua man hinh.
- Quan ly trang thai loading, success, error.
- Goi repository khi can fetch hoac cap nhat.
- Notify UI khi data thay doi.
- Luu filter state, page state, selected store/company, va tab active cua tung man hinh.

### Cach to chuc state theo kieu Sapo

- Trang list can co state cho search, filter, sort, pagination, selected rows.
- Trang form can co state cho draft, validation, submit loading, submit error.
- Trang detail can co state cho tabs, expand section, hoac nested data nhu images, ratings, history.
- Sau khi mutation thanh cong, provider nen patch state hoac refetch data de UI dong bo ngay.

### Provider de xuat theo tinh nang

- `AuthProvider`: login, signup, logout, current user.
- `UserProvider`: profile, password, danh sach user, status.
- `ProductProvider`: list, detail, create, update, status, report, store product.
- `ProductImageProvider`: gallery, upload, set main, delete.
- `InventoryProvider`: ton kho theo san pham/cua hang.
- `CartProvider`: them/sua/xoa/xoa het gio hang, tinh tong tien.
- `OrderProvider`: tao/sua/chi tiet/danh sach/doi trang thai/thanh toan/bao cao.
- `RatingProvider`: danh sach rating, tao/sua/xoa, filter theo san pham.
- `PurchaseOrderProvider`: tao/list/report/status.
- `PromotionProvider`: list tao/sua/status.
- `MasterDataProvider`: company, store, provider, category, unit.

### Provider nen phan theo man hinh

- DashboardProvider: KPI va summary.
- SidebarProvider: menu, role, active route.
- ProductFormProvider: form create/update product.
- OrderFormProvider: draft order, cart sync, payment summary.
- PurchaseOrderFormProvider: draft nhap hang, details, total.

### State nen co

- `isLoading`
- `errorMessage`
- `successMessage`
- `items` hoac `data` chinh
- `pagination` neu API co `Page<T>`
- `selectedId` hoac `selectedIds` cho bulk action.
- `filters` cho cac dieu kien tim kiem theo role/chi nhanh/trang thai.

### Quy tac su dung

- Provider khong nen xu ly JSON raw.
- Provider khong nen biet chi tiet Dio interceptors hay header.
- Khi nhan 401, provider nen phat su kien logout hoac yeu cau dang nhap lai.
- Khi doi du lieu nhu status, provider can reload data cu the de UI dong bo voi backend.
- Provider khong nen tu doan nghia status; phai map qua bang status o `response.md`.