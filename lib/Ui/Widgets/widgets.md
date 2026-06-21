## Widgets

Thu muc nay chua cac thanh phan dung lai duoc tai su dung trong nhieu screen.

### Widget nen co

- `CustomButton`: nut action chinh tren form, co loading state.
- `CustomTextField`: input co validation va suffix/prefix icon.
- `LoadingView` hoac `LoadingDialog`: hien thi khi dang fetch API.
- `EmptyState`: hien thi khi khong co du lieu.
- `ErrorState`: hien thi khi request fail.
- `ProductItemCard`: item san pham trong list.
- `CartItemTile`: item san pham trong gio hang.
- `OrderItemTile`: item trong chi tiet don.
- `RatingItemCard`: item danh gia.
- `StatusBadge`: hien thi trang thai san pham/don/khuyen mai.
- `PaginationFooter`: dieu khien trang neu man hinh co phan trang.

### Widget va data can truyen

- `ProductItemCard`: `productName`, `sellPrice`, `avgStar`, `unitName`, `status`, `imageUrl`.
- `CartItemTile`: `productName`, `sellPrice`, `quantity`, `totalPrice`.
- `OrderItemTile`: `productName`, `quantity`, `price`, `subtotal`.
- `RatingItemCard`: `rating`, `comment`, `userFullName`, `updatedAt`.
- `StatusBadge`: can map tu `status`, `paymentStatus`, `scope`, `discountType`.

### Quy tac thiet ke

- Widget khong goi API truc tiep.
- Widget chi nhan du lieu va callback tu screen/provider.
- Widget can tai su dung duoc tren mobile va tablet.