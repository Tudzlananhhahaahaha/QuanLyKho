-- ========================================
-- DỮ LIỆU MẪU
-- ========================================

-- KHO
INSERT INTO Kho VALUES
('K001', N'Kho Trung Tâm', N'Hà Nội'),
('K002', N'Kho Miền Nam', N'TP. Hồ Chí Minh');

-- NHÀ CUNG CẤP
INSERT INTO NhaCungCap VALUES
('N001', N'Công ty ABC', N'Hà Nội', '0988123456'),
('N002', N'Công ty XYZ', N'Đà Nẵng', '0977988888');

-- MẶT HÀNG
INSERT INTO MatHang VALUES
('H001', N'Bánh Oreo', N'Hộp', 50, 15000, 'K001'),
('H002', N'Sữa Vinamilk', N'Thùng', 30, 350000, 'K001'),
('H003', N'Nước ngọt Coca', N'Chai', 100, 10000, 'K002'),
('H004', N'Mì Hảo Hảo', N'Thùng', 20, 120000, 'K002');

-- PHIẾU NHẬP
INSERT INTO PhieuNhap VALUES
('PN001', '2025-11-01', 'N001'),
('PN002', '2025-11-05', 'N002');

-- CHI TIẾT PHIẾU NHẬP
INSERT INTO ChiTietPhieuNhap VALUES
('PN001', 'H001', 100, 14000),
('PN001', 'H002', 50, 330000),
('PN002', 'H003', 200, 9500);

-- PHIẾU XUẤT
INSERT INTO PhieuXuat VALUES
('PX001', '2025-11-10', N'Nguyễn Văn A'),
('PX002', '2025-11-11', N'Trần Thị B');

-- CHI TIẾT PHIẾU XUẤT
INSERT INTO ChiTietPhieuXuat VALUES
('PX001', 'H001', 30, 15000),
('PX001', 'H002', 10, 350000),
('PX002', 'H003', 50, 10000);
