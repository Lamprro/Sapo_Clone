## Data Layer Overview

Lop `Data` la tang lam viec truc tiep voi backend. Moi request tu Flutter se di qua `services`, duoc goi boi `repositories`, sau do state duoc dua len `providers` de UI su dung.

### Muc tieu

- Tach ro logic API khoi UI.
- Dong bo ten field request/response voi backend Spring Boot.
- Giu mot noi duy nhat quan ly base url, auth header va xu ly loi.

### Nguyen tac phoi hop voi backend

- Tat ca API nghiep vu deu wrap trong `ApiResponse<T>` voi 3 field: `status`, `message`, `data`.
- API da bao ve phai gui `Authorization: Bearer <token>`.
- Backend lay `userId`, `companyId`, `storeId`, `role` tu JWT, khong yeu cau FE tu truyen nhung field nay neu backend da suy ra duoc.
- Login can `companyId`; signup can `repeatPassword`; cac API dat hang, cart, rating, inventory, product images, purchase order deu phai di kem token.

### Nhom tinh nang chinh

- Auth: login, signup.
- Master data: company, store, category, unit, provider.
- Product: product, product image, inventory, report.
- Cart and order: cart, order, payment, status, report.
- Customer interaction: rating.
- Procurement: purchase order.
- Promotion: promotion cho order va product.

### Cach doc tai lieu nay

- `services.md` mo ta chi tiet endpoint, method, request body, path/query params va auth.
- `models.md` mo ta cac model Dart can map tu response backend.
- `repositories.md` mo ta interface truy cap du lieu cho tung feature.
- `providers.md` mo ta state va cac ham Flutter dung de trigger fetch/update.

### Thu tu uu tien khi code FE

- Neu can biet backend tra ve gi, doc `reponse.md` truoc.
- Neu can biet model Dart phai map ra sao, doc `models.md` tiep theo.
- Neu can biet man hinh nao dung API nao, doc `screens.md` va `services.md`.
