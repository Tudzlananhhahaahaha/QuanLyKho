-------------------------------------
-- 1. TẠO CƠ SỞ DỮ LIỆU
-------------------------------------
CREATE DATABASE QuanLyKho;
GO
USE QuanLyKho;
GO


-------------------------------------
-- 2. TẠO CÁC BẢNG
-------------------------------------

-- Bảng Khách hàng
CREATE TABLE KhachHang (
    MaKhach INT IDENTITY PRIMARY KEY,
    TenKhach NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(200),
    DienThoai NVARCHAR(20)
);

-- Bảng Mặt hàng
CREATE TABLE MatHang (
    MaHang INT IDENTITY PRIMARY KEY,
    TenHang NVARCHAR(100) NOT NULL,
    NoiSanXuat NVARCHAR(100)
);

-- Bảng Phiếu nhập
CREATE TABLE PhieuNhap (
    SoPhieuNhap INT IDENTITY PRIMARY KEY,
    NgayNhap DATE NOT NULL,
    NhaCungCap NVARCHAR(100)
);

-- Bảng Chi tiết phiếu nhập
CREATE TABLE ChiTietNhap (
    MaCTN INT IDENTITY PRIMARY KEY,
    SoPhieuNhap INT NOT NULL,
    MaHang INT NOT NULL,
    SoLuongNhap INT NOT NULL,
    DonGiaNhap DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (SoPhieuNhap) REFERENCES PhieuNhap(SoPhieuNhap),
    FOREIGN KEY (MaHang) REFERENCES MatHang(MaHang)
);

-- Bảng Phiếu xuất
CREATE TABLE PhieuXuat (
    SoPhieuXuat INT IDENTITY PRIMARY KEY,
    NgayXuat DATE NOT NULL,
    MaKhach INT NOT NULL,
    FOREIGN KEY (MaKhach) REFERENCES KhachHang(MaKhach)
);

-- Bảng Chi tiết phiếu xuất
CREATE TABLE ChiTietXuat (
    MaCTX INT IDENTITY PRIMARY KEY,
    SoPhieuXuat INT NOT NULL,
    MaHang INT NOT NULL,
    SoLuongXuat INT NOT NULL,
    DonGiaXuat DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (SoPhieuXuat) REFERENCES PhieuXuat(SoPhieuXuat),
    FOREIGN KEY (MaHang) REFERENCES MatHang(MaHang)
);


-------------------------------------
-- 3. VIEW – DANH SÁCH TỒN KHO
-------------------------------------
GO
CREATE VIEW v_TonKho AS
SELECT 
    MH.MaHang,
    MH.TenHang,
    ISNULL(SUM(CTN.SoLuongNhap), 0) AS TongNhap,
    ISNULL((SELECT SUM(CTX.SoLuongXuat) 
            FROM ChiTietXuat CTX 
            WHERE CTX.MaHang = MH.MaHang), 0) AS TongXuat,
    ISNULL(SUM(CTN.SoLuongNhap), 0) -
    ISNULL((SELECT SUM(CTX.SoLuongXuat) 
            FROM ChiTietXuat CTX 
            WHERE CTX.MaHang = MH.MaHang), 0) AS TonKho
FROM MatHang MH
LEFT JOIN ChiTietNhap CTN ON MH.MaHang = CTN.MaHang
GROUP BY MH.MaHang, MH.TenHang;


-------------------------------------
-- 4. TRIGGER – KIỂM TRA TỒN KHO KHI XUẤT
-------------------------------------
GO
CREATE TRIGGER trg_KiemTraTonKho
ON ChiTietXuat
FOR INSERT
AS
BEGIN
    DECLARE @MaHang INT, @SoLuongXuat INT;

    SELECT @MaHang = MaHang, @SoLuongXuat = SoLuongXuat 
    FROM INSERTED;

    DECLARE @TonKho INT;
    SELECT @TonKho = TonKho 
    FROM v_TonKho 
    WHERE MaHang = @MaHang;

    IF @SoLuongXuat > @TonKho
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'Số lượng xuất vượt quá số lượng tồn kho!', 16, 1);
    END
END;


-------------------------------------
-- 5. FUNCTION – DOANH THU THEO THÁNG/NĂM
-------------------------------------
GO
CREATE FUNCTION fn_DoanhThuTheoThang (@thang INT, @nam INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        MH.MaHang,
        MH.TenHang,
        SUM(CTX.SoLuongXuat * CTX.DonGiaXuat) AS DoanhThu
    FROM PhieuXuat PX
    JOIN ChiTietXuat CTX ON PX.SoPhieuXuat = CTX.SoPhieuXuat
    JOIN MatHang MH ON MH.MaHang = CTX.MaHang
    WHERE MONTH(PX.NgayXuat) = @thang AND YEAR(PX.NgayXuat) = @nam
    GROUP BY MH.MaHang, MH.TenHang
);


-------------------------------------
-- 6. PROCEDURE – TÌM KIẾM MẶT HÀNG
-------------------------------------
GO
CREATE PROCEDURE sp_TimKiemMatHang
    @TuKhoa NVARCHAR(100) = NULL,
    @NgayNhap DATE = NULL,
    @NoiSX NVARCHAR(100) = NULL
AS
BEGIN
    SELECT DISTINCT MH.MaHang, MH.TenHang, MH.NoiSanXuat, PN.NgayNhap
    FROM MatHang MH
    LEFT JOIN ChiTietNhap CTN ON MH.MaHang = CTN.MaHang
    LEFT JOIN PhieuNhap PN ON CTN.SoPhieuNhap = PN.SoPhieuNhap
    WHERE 
        (@TuKhoa IS NULL OR MH.TenHang LIKE '%' + @TuKhoa + '%')
        AND (@NgayNhap IS NULL OR PN.NgayNhap = @NgayNhap)
        AND (@NoiSX IS NULL OR MH.NoiSanXuat LIKE '%' + @NoiSX + '%');
END;


-------------------------------------
-- 7. TRUY VẤN THEO YÊU CẦU ĐỀ BÀI
-------------------------------------

-- (1) Danh sách tồn kho
SELECT * FROM v_TonKho;

-- (2) Mặt hàng tồn kho > 100
SELECT * FROM v_TonKho WHERE TonKho > 100;

-- (3) Mặt hàng xuất theo ngày/tháng/năm
SELECT MH.TenHang, PX.NgayXuat, CTX.SoLuongXuat
FROM PhieuXuat PX
JOIN ChiTietXuat CTX ON PX.SoPhieuXuat = CTX.SoPhieuXuat
JOIN MatHang MH ON MH.MaHang = CTX.MaHang
WHERE PX.NgayXuat = '2025-01-10';

-- (4) Doanh thu từng mặt hàng theo tháng/năm
SELECT * FROM fn_DoanhThuTheoThang(1, 2025);

-- (5) Mặt hàng nhập nhiều nhất
SELECT TOP 1 MaHang, SUM(SoLuongNhap) AS TongNhap
FROM ChiTietNhap
GROUP BY MaHang
ORDER BY TongNhap DESC;

-- (6) Mặt hàng xuất nhiều nhất
SELECT TOP 1 MaHang, SUM(SoLuongXuat) AS TongXuat
FROM ChiTietXuat
GROUP BY MaHang
ORDER BY TongXuat DESC;

-- (7) Mặt hàng không bán được trong tháng X
SELECT MH.MaHang, MH.TenHang
FROM MatHang MH
WHERE MH.MaHang NOT IN (
    SELECT CTX.MaHang
    FROM PhieuXuat PX
    JOIN ChiTietXuat CTX ON PX.SoPhieuXuat = CTX.SoPhieuXuat
    WHERE MONTH(PX.NgayXuat) = 1 AND YEAR(PX.NgayXuat) = 2025
);
