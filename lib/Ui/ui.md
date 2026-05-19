## UI Architecture

Tang `Ui` chua man hinh, widget, routing va cach hien thi du lieu.

## Dinh huong giao dien theo kieu Sapo

Giao dien can theo phong cach ban hang/quan tri quen thuoc, de FE co the lam dang web app nghiep vu ngay tu dau:

- Sidebar ben trai co nhom menu ro rang.
- Top bar co ten cua hang, company, user, notification, va nut logout.
- Noi dung chinh co page header, filter bar, table/card list, va action buttons.
- Man hinh chi tiet dung drawer, modal, hoac tab de khong lam vo trang.
- Desktop la uu tien chinh; mobile chi can ho tro xem nhanh va tac vu co ban.

### Muc tieu

- Tach flow hien thi khoi data layer.
- Giu cac man hinh ngan, de doc, de test.
- Dung lai widget cho cac component lap lai.
- Lam giao dien co cau truc giong mot he thong Sapo-style: nhanh, ro vai tro, nhieu bang du lieu, it chuyen trang con.

### Bo cuc chung nen co

Moi man hinh nghiep vu nen theo khung sau:

- `AppShell`: sidebar + topbar + content.
- `PageHeader`: tieu de, mo ta ngan, nut them moi/xuat file.
- `FilterBar`: search, dropdown loc, date range, status filter.
- `SummaryCards`: KPI cho dashboard, report, inventory, order.
- `DataTable` hoac `GridCardList`: danh sach chinh.
- `ActionArea`: edit, detail, delete, change status, print, upload image.
- `EmptyState` va `ErrorState`: khong co du lieu hoac loi.

### Menu de xuat cho FE

- Dashboard.
- Ban hang.
- Don hang.
- San pham.
- Ton kho.
- Khuyen mai.
- Phieu nhap.
- Danh gia.
- Khach hang va nhan vien.
- Cua hang / company / nha cung cap / don vi / danh muc.

### Trang thai bat buoc

- Loading khi fetch danh sach hoac save form.
- Empty khi trang thai khong co du lieu.
- Error khi loi 4xx/5xx.
- Confirm dialog truoc xoa, doi status, cap nhat gia tri nhay cam.
- Permission denied state khi role khong co quyen nhin nut hoac hanh dong.

### Cac nguyen tac UI

- Man hinh chi goi provider, khong goi API truc tiep.
- Tat ca trang co loading state va empty state ro rang.
- Form can validate truoc khi goi request.
- Cac list man hinh nen ho tro tim kiem, phan trang, va filter neu backend co.
- Voi cac man hinh quan tri, nut them moi/doi trang thai/xem chi tiet nen dat cung vi tri giua cac trang.
- Voi man hinh customer, noi dung phai don gian hon, toi da 1-2 hanh dong chinh tren 1 card.

### Nhom man hinh chinh

- Auth: login, signup.
- Home/customer: product list, product detail, cart, order, rating.
- Manage: product management, order management, purchase order, promotion, inventory.
- Master data: company, store, provider, category, unit, user.

### Dieu can luu y khi render

- `ApiResponse.message` co the dung de toast success/error.
- `Page<T>` can render theo `content`, `totalPages`, `number`, `size`.
- Co nhung response chat luong display-only, vi du `discountType` o response la string de hien thi, khong nen set nguoc lai sang request truc tiep.
- FE khong nen dung truc tiep entity name hay database column name; chi dung JSON response da duoc mo ta trong `response.md`.
- Cac badge trang thai nen co mau thong nhat toan app: active = xanh, warning = vang, danger = do, draft/pending = xam.
