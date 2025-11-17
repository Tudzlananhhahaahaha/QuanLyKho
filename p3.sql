-- ========================================
--  TẠO CƠ SỞ DỮ LIỆU
-- ========================================
CREATE DATABASE QuanLyKhoHang;
GO

USE QuanLyKhoHang;
GO

-- =======================================
-- Bảng Khách hàng
-- =======================================
CREATE TABLE KhachHang (
    MaKhach INT IDENTITY PRIMARY KEY,
    TenKhach NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(200),
    DienThoai NVARCHAR(20)
);
GO


-- ========================================    
--  BẢNG KHO
-- ========================================
CREATE TABLE Kho (
    MaKho CHAR(5) PRIMARY KEY,
    TenKho NVARCHAR(100),
    DiaChi NVARCHAR(200)
);
GO

-- ========================================
--  BẢNG NHÀ CUNG CẤP
-- ========================================
CREATE TABLE NhaCungCap (
    MaNCC CHAR(5) PRIMARY KEY,
    TenNCC NVARCHAR(100),
    DiaChi NVARCHAR(200),
    SoDienThoai VARCHAR(15)
);
GO

-- ========================================
--  BẢNG MẶT HÀNG
-- ========================================
CREATE TABLE MatHang (
    MaHang CHAR(5) PRIMARY KEY,
    TenHang NVARCHAR(100),
    DonVi NVARCHAR(50),
    SoLuongTon INT,
    DonGia DECIMAL(18,2),
    MaKho CHAR(5),
    FOREIGN KEY (MaKho) REFERENCES Kho(MaKho)
);
GO

-- ========================================
--  BẢNG PHIẾU NHẬP
-- ========================================
CREATE TABLE PhieuNhap (
    MaPN CHAR(5) PRIMARY KEY,
    NgayNhap DATE,
    MaNCC CHAR(5),
    FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC)
);
GO

-- ========================================
--  BẢNG CHI TIẾT PHIẾU NHẬP
-- ========================================
CREATE TABLE ChiTietPhieuNhap (
    MaPN CHAR(5),
    MaHang CHAR(5),
    SoLuongNhap INT,
    DonGiaNhap DECIMAL(18,2),
    PRIMARY KEY (MaPN, MaHang),
    FOREIGN KEY (MaPN) REFERENCES PhieuNhap(MaPN),
    FOREIGN KEY (MaHang) REFERENCES MatHang(MaHang)
);
GO

-- ========================================
--  BẢNG PHIẾU XUẤT
-- ========================================
CREATE TABLE PhieuXuat (
    MaPX CHAR(5) PRIMARY KEY,
    NgayXuat DATE,
    NguoiNhan NVARCHAR(100)
);
GO

-- ========================================
--  BẢNG CHI TIẾT PHIẾU XUẤT
-- ========================================
CREATE TABLE ChiTietPhieuXuat (
    MaPX CHAR(5),
    MaHang CHAR(5),
    SoLuongXuat INT,
    DonGiaXuat DECIMAL(18,2),
    PRIMARY KEY (MaPX, MaHang),
    FOREIGN KEY (MaPX) REFERENCES PhieuXuat(MaPX),
    FOREIGN KEY (MaHang) REFERENCES MatHang(MaHang)
);
GO
