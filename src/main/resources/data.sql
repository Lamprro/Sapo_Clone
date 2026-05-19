-- =========================================================================================
-- 1. THÊM DỮ LIỆU CÁC BẢNG DANH MỤC ĐỘC LẬP
-- =========================================================================================
INSERT INTO roles(roles_name) VALUES ('ADMIN'), ('MANAGER'), ('EMPLOYEE'), ('CUSTOMER');

INSERT INTO company (company_name, company_address, created_at, updated_at) VALUES
(N'Sapo Tech', N'266 Đội Cấn, Hà Nội', GETDATE(), GETDATE()),
(N'FPT Shop', N'Cầu Giấy, Hà Nội', GETDATE(), GETDATE()),
(N'Thế Giới Di Động', N'Quận 1, TP.HCM', GETDATE(), GETDATE()),
(N'CellphoneS', N'Thái Hà, Hà Nội', GETDATE(), GETDATE()),
(N'Hoàng Hà Mobile', N'Lê Duẩn, Hà Nội', GETDATE(), GETDATE());

INSERT INTO category (category_name, description) VALUES
(N'Điện thoại thông minh', N'Smartphone các hãng'),
(N'Máy tính xách tay', N'Laptop văn phòng, gaming'),
(N'Máy tính bảng', N'iPad, Galaxy Tab'),
(N'Đồng hồ thông minh', N'Apple Watch, Garmin'),
(N'Tai nghe', N'Tai nghe Bluetooth, True Wireless'),
(N'Cáp sạc', N'Cáp Type-C, Lightning'),
(N'Củ sạc', N'Sạc nhanh 20W, 65W'),
(N'Ốp lưng', N'Ốp lưng chống sốc, silicon'),
(N'Màn hình máy tính', N'Màn hình đồ họa, gaming'),
(N'Bàn phím & Chuột', N'Bàn phím cơ, chuột không dây');

INSERT INTO unit (unit_name) VALUES
(N'Cái'), (N'Chiếc'), (N'Hộp'), (N'Thùng'), (N'Lốc'),
(N'Gói'), (N'Bịch'), (N'Bộ'), (N'Cặp'), (N'Cuộn');

INSERT INTO providers (provider_name, provider_phone, provider_address, provider_uei, status) VALUES
(N'Apple Vietnam', '0901234561', N'Quận 1, TP.HCM' , '1234', '1'),
(N'Samsung Electronics VN', '0901234562', N'KCN Yên Phong, Bắc Ninh', '1234', '1'),
(N'Sony Vietnam', '0901234563', N'Quận 3, TP.HCM', '1234', '1'),
(N'Xiaomi Distribution', '0901234564', N'Thanh Xuân, Hà Nội', '1234', '1'),
(N'Asus Global', '0901234565', N'Quận 10, TP.HCM', '1234', '1'),
(N'Dell Technologies', '0901234566', N'Quận Cầu Giấy, Hà Nội', '1234', '1'),
(N'Logitech VN', '0901234567', N'Quận 7, TP.HCM', '1234', '1'),
(N'LG Electronics', '0901234568', N'Hải Phòng', '1234', '1'),
(N'Oppo Mobile', '0901234569', N'Quận 1, TP.HCM', '1234', '1'),
(N'Anker Accessories', '0901234560', N'Quận Đống Đa, Hà Nội', '1234', '1');

-- =========================================================================================
-- 2. THÊM CỬA HÀNG, ĐIỂM THƯỞNG VÀ TÀI KHOẢN NGƯỜI DÙNG (USERS)
-- Mật khẩu chung: 123456 ($2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i)
-- =========================================================================================

INSERT INTO store (store_name, company_id, created_at, updated_at, latitude, longitude, store_address) VALUES
(N'Sapo Store Cầu Giấy', 1, GETDATE(), GETDATE(), 21.037814, 105.781685, N'11 Duy Tân, Dịch Vọng Hậu, Cầu Giấy, Hà Nội'),
(N'Sapo Store Đống Đa', 1, GETDATE(), GETDATE(), 21.018155, 105.823612, N'2 Thái Hà, Trung Liệt, Đống Đa, Hà Nội'),
(N'Sapo Store Hà Đông', 1, GETDATE(), GETDATE(), 20.976071, 105.787130, N'10 Trần Phú, Mộ Lao, Hà Đông, Hà Nội'),
(N'Sapo Store Quận 1', 1, GETDATE(), GETDATE(), 10.776889, 106.700806, N'123 Lê Lợi, Bến Thành, Quận 1, Hồ Chí Minh'),
(N'Sapo Store Tân Bình', 1, GETDATE(), GETDATE(), 10.801550, 106.655829, N'456 Cộng Hòa, Phường 13, Tân Bình, Hồ Chí Minh'),
(N'FPT Shop Cầu Diễn', 2, GETDATE(), GETDATE(), 21.037814, 105.781685, N'Cầu Diễn, Từ Liêm, Hà Nội'),
(N'TGDD Thái Hà', 3, GETDATE(), GETDATE(), 21.018155, 105.823612, N'Thái Hà, Đống Đa, Hà Nội'),
(N'CellphoneS Nguyễn Trãi', 4, GETDATE(), GETDATE(), 20.995818, 105.807833, N'Nguyễn Trãi, Thanh Xuân, Hà Nội'),
(N'Hoàng Hà Lê Duẩn', 5, GETDATE(), GETDATE(), 21.025067, 105.839885, N'Lê Duẩn, Đống Đa, Hà Nội'),
(N'FPT Shop Trần Duy Hưng', 2, GETDATE(), GETDATE(), 21.012543, 105.795861, N'Trần Duy Hưng, Cầu Giấy, Hà Nội');

-- NHÂN VIÊN VÀ QUẢN LÝ (Có ID từ 1 đến 5)
INSERT INTO users (user_full_name, user_email, username, password, user_phone, user_address, user_status, created_at, updated_at, roles_id, company_id, store_id) VALUES
(N'Nguyễn Văn Admin', 'admin@sapo.vn', 'admin_sapo', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0988111111', N'Hà Nội', 1, GETDATE(), GETDATE(), 1, 1, 1),
(N'Trần Quản Lý', 'manager@sapo.vn', 'manager_sapo', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0988111112', N'Hà Nội', 1, GETDATE(), GETDATE(), 2, 1, 1),
(N'Lê Nhân Viên Một', 'nv1@sapo.vn', 'nhanvien1', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0988111113', N'Hà Nội', 1, GETDATE(), GETDATE(), 3, 1, 1),
(N'Phạm Nhân Viên Hai', 'nv2@sapo.vn', 'nhanvien2', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0988111114', N'Hà Nội', 1, GETDATE(), GETDATE(), 3, 1, 2),
(N'Vũ Thu Ngân', 'thungan@sapo.vn', 'thungan1', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0988111115', N'Hà Nội', 1, GETDATE(), GETDATE(), 4, 1, 1);

-- KHÁCH HÀNG (Có ID từ 6 đến 15)
INSERT INTO users (user_full_name, user_email, username, password, user_phone, user_address, user_status, created_at, updated_at, roles_id, company_id) VALUES
(N'Khách Hàng A', 'khacha@gmail.com', 'khachhang_a', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222111', N'Cầu Giấy, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng B', 'khachb@gmail.com', 'khachhang_b', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222112', N'Đống Đa, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng C', 'khachc@gmail.com', 'khachhang_c', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222113', N'Hà Đông, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng D', 'khachd@gmail.com', 'khachhang_d', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222114', N'Ba Đình, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng E', 'khache@gmail.com', 'khachhang_e', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222115', N'Thanh Xuân, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng F', 'khachf@gmail.com', 'khachhang_f', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222116', N'Tây Hồ, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng G', 'khachg@gmail.com', 'khachhang_g', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222117', N'Hoàng Mai, HN', 0, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng H', 'khachh@gmail.com', 'khachhang_h', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222118', N'Hai Bà Trưng, HN', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng I', 'khachi@gmail.com', 'khachhang_i', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222119', N'Quận 1, TP.HCM', 1, GETDATE(), GETDATE(), 4, 1),
(N'Khách Hàng K', 'khachk@gmail.com', 'khachhang_k', '$2a$12$b3RP.4eBVcbumIvKmm4CR.vdkIu2YoEd6tYPsig6FUqYUg3Awtn/i', '0333222120', N'Tân Bình, TP.HCM', 1, GETDATE(), GETDATE(), 4, 1);

INSERT INTO point (point,user_id) VALUES (0,6), (50,7), (100,8), (200,9), (500,10), (10,11), (20,12), (30,13), (0,14), (1000,15);


-- GIỎ HÀNG
INSERT INTO cart (user_id, created_at, updated_at) VALUES
(6, GETDATE(), GETDATE()), (7, GETDATE(), GETDATE()), (8, GETDATE(), GETDATE()), (9, GETDATE(), GETDATE()), (10, GETDATE(), GETDATE()),
(11, GETDATE(), GETDATE()), (12, GETDATE(), GETDATE()), (13, GETDATE(), GETDATE()), (14, GETDATE(), GETDATE()), (15, GETDATE(), GETDATE());

-- =========================================================================================
-- 3. THÊM SẢN PHẨM, DANH MỤC VÀ TỒN KHO
-- =========================================================================================

INSERT INTO product (product_name, description, barcode, avgstar, import_price, sell_price_original, sell_price, status, company_id, unit_id, created_at, updated_at) VALUES
(N'iPhone 15 Pro Max', N'Titan', 'SP001', 4.9, 25000000, 30000000, 28990000, 1, 1, 2, GETDATE(), GETDATE()),
(N'Samsung S24 Ultra', N'AI', 'SP002', 4.8, 23000000, 28000000, 26500000, 1, 1, 2, GETDATE(), GETDATE()),
(N'MacBook Pro M3', N'M3', 'SP003', 5.0, 35000000, 42000000, 39990000, 1, 1, 2, GETDATE(), GETDATE()),
(N'iPad Pro 11 inch', N'M2', 'SP004', 4.7, 18000000, 22000000, 20500000, 1, 1, 2, GETDATE(), GETDATE()),
(N'Apple Watch Series 9', N'Smart', 'SP005', 4.6, 8000000, 11000000, 9500000, 1, 1, 2, GETDATE(), GETDATE()),
(N'AirPods Pro 2', N'ANC', 'SP006', 4.8, 4500000, 6500000, 5800000, 1, 1, 8, GETDATE(), GETDATE()),
(N'Chuột Logitech', N'MX3', 'SP007', 4.9, 1800000, 2500000, 2200000, 1, 1, 2, GETDATE(), GETDATE()),
(N'Bàn phím Keychron', N'K8', 'SP008', 4.5, 1500000, 2000000, 1750000, 1, 1, 2, GETDATE(), GETDATE()),
(N'Củ sạc Anker 20W', N'Sạc', 'SP009', 4.8, 200000, 400000, 350000, 1, 1, 1, GETDATE(), GETDATE()),
(N'Cáp sạc Baseus', N'Dù', 'SP010', 4.4, 80000, 150000, 120000, 1, 1, 1, GETDATE(), GETDATE());

-- THÊM ẢNH CHO SẢN PHẨM 1 (iPhone 15 Pro Max)
INSERT INTO product_image (image_url, public_id, status, product_id) VALUES
('https://res.cloudinary.com/dh8xlfsvq/image/upload/v1767538464/qlsmujnlmlgiiv7cgkrp.jpg', 'sample1', 2, 1),
('https://res.cloudinary.com/dh8xlfsvq/image/upload/v1777710965/main-sample.png', 'sample2', 1, 1),
('https://res.cloudinary.com/dh8xlfsvq/image/upload/v1767543319/products/51/twmx4n92bicgj55zinhq.jpg', 'sample3', 1, 1),
('https://res.cloudinary.com/dh8xlfsvq/image/upload/v1767585625/products/52/mfqvrzx1n75c6gotpyzs.png', 'sample4', 1, 1),
('https://res.cloudinary.com/dh8xlfsvq/image/upload/v1767538521/vn-11134207-7r98o-lvr1pyupuh96ce_tn_o0pipu.webp', 'sample5', 1, 1);


INSERT INTO product_category (product_id, category_id) VALUES
(1, 1), (2, 1), (3, 2), (4, 3), (5, 4), (6, 5), (7, 10), (8, 10), (9, 7), (10, 6);

INSERT INTO inventory (product_id, store_id, quantity, version) VALUES
(1, 1, 50 ,0), (2, 1, 30,0), (3, 1, 15,0), (4, 1, 20,0), (5, 1, 40,0),
(6, 1, 100,0), (7, 1, 50,0), (8, 1, 50,0), (9, 1, 200,0), (10, 1, 300,0),
(1, 2, 10,0), (2, 2, 5,0), (3, 2, 2,0), (4, 2, 8,0), (5, 2, 15,0);

-- CHI TIẾT GIỎ HÀNG (CART_ITEM)
INSERT INTO cart_item (cart_id, product_id, quantity, created_at, updated_at) VALUES
(1, 1, 1, GETDATE(), GETDATE()),
(1, 6, 2, GETDATE(), GETDATE()),
(2, 2, 1, GETDATE(), GETDATE()),
(3, 3, 1, GETDATE(), GETDATE()),
(3, 7, 1, GETDATE(), GETDATE()),
(4, 4, 1, GETDATE(), GETDATE()),
(5, 5, 1, GETDATE(), GETDATE()),
(6, 9, 2, GETDATE(), GETDATE()),
(6, 10, 2, GETDATE(), GETDATE()),
(7, 8, 1, GETDATE(), GETDATE());

-- =========================================================================================
-- 4. KHUYẾN MÃI, ĐƠN BÁN (ORDERS) VÀ ĐƠN NHẬP (PURCHASE ORDERS)
-- =========================================================================================

INSERT INTO promotions (promotion_name, scope, discount_type, discount_value, min_account, max_account, status, created_at, started_at, ended_at, company_id) VALUES
(N'Giảm 10%', 0, 1, 10.0, 1000000, 500000, 1, GETDATE(), GETDATE(), DATEADD(month, 1, GETDATE()), 1),
(N'Giảm 100K', 0, 0, 100000.0, 500000, 100000, 1, GETDATE(), GETDATE(), DATEADD(month, 2, GETDATE()), 1),
(N'Sale Phụ kiện', 1, 1, 20.0, 0, 200000, 1, GETDATE(), GETDATE(), DATEADD(day, 3, GETDATE()), 1),
(N'Sale hết hạn', 0, 1, 15.0, 0, 300000, 0, DATEADD(month, -2, GETDATE()), DATEADD(month, -2, GETDATE()), DATEADD(month, -1, GETDATE()), 1),
(N'Giảm 500K', 0, 0, 500000.0, 10000000, 500000, 1, GETDATE(), GETDATE(), DATEADD(month, 1, GETDATE()), 1);

INSERT INTO orders (shipping_address, total_amount, status, redeem_point, earn_point, created_at, updated_at, payment_method, payment_status, note, customer_id, employee_id, promotion_id, store_id) VALUES
(N'HN', 28990000, '3', 0, 28990, DATEADD(day, -5, GETDATE()), DATEADD(day, -4, GETDATE()), '1', '0', N'Giao giờ hành chính', 6, 3, NULL, 1),
(N'HN', 120000, '2', 0, 120, GETDATE(), GETDATE(), '0', '0', N'Gọi trước', 6, NULL, NULL, 1),
(N'HN', 26500000, '1', 0, 26500, DATEADD(day, -1, GETDATE()), GETDATE(), '0', '0', N'', 7, 4, NULL, 2),
(N'HN', 39490000, '4', 0, 39490, DATEADD(day, -2, GETDATE()), GETDATE(), '1', '0', N'Cẩn thận', 8, 3, 5, 1),
(N'HN', 5800000, '0', 0, 0, DATEADD(day, -10, GETDATE()), DATEADD(day, -9, GETDATE()), '0', '0', N'Bom', 9, NULL, NULL, 1);

INSERT INTO order_details (quantity, price, subtotal, order_id, product_id,import_price) VALUES
(1, 28990000, 28990000, 1, 1,28990000),
(1, 120000, 120000, 2, 10,28990000),
(1, 26500000, 26500000, 3, 2,28990000),
(1, 39990000, 39490000, 4, 3,28990000),
(1, 5800000, 5800000, 5, 6,28990000);

INSERT INTO purchase_orders (created_at, updated_at, status, total_amount, note, user_id, store_id, provider_id) VALUES
(DATEADD(month, -1, GETDATE()), DATEADD(month, -1, GETDATE()), 1, 250000000, N'Nhập iPhone', 2, 1, 1),
(DATEADD(day, -15, GETDATE()), DATEADD(day, -15, GETDATE()), 1, 115000000, N'Nhập S24', 2, 1, 2),
(DATEADD(day, -5, GETDATE()), DATEADD(day, -5, GETDATE()), 0, 35000000, N'Chờ hàng về', 2, 1, 1),
(GETDATE(), GETDATE(), 0, 9000000, N'Phụ kiện', 2, 1, 7),
(DATEADD(day, -20, GETDATE()), DATEADD(day, -20, GETDATE()), 2, 10000000, N'NCC hết hàng', 2, 2, 10);

INSERT INTO purchase_order_details (quantity, price, subtotal, purchase_order_id, product_id) VALUES
(10, 25000000, 250000000, 1, 1),
(5, 23000000, 115000000, 2, 2),
(1, 35000000, 35000000, 3, 3),
(5, 180000, 9000000, 4, 7),
(100, 80000, 8000000, 5, 10);

-- =========================================================================================
-- 5. THÊM ĐÁNH GIÁ (RATINGS)
-- =========================================================================================

INSERT INTO rating (rating, user_id, comment, product_id,status) VALUES
(5, 6, N'Sản phẩm rất tốt, đáng tiền!', 1,1),
(4, 7, N'Hài lòng với sản phẩm, giao hàng nhanh.', 1,1),
(5, 8, N'Chất lượng tuyệt vời, sẽ ủng hộ tiếp.', 1,1),
(3, 9, N'Sản phẩm tạm được, có vài lỗi nhỏ.', 4,1),
(4, 10, N'Rất ưng ý, đúng như mô tả.', 5,1);