-- Bảng Sản phẩm
CREATE TABLE SanPham (
    MaSP INT IDENTITY PRIMARY KEY,
    TenSP NVARCHAR(200) NOT NULL UNIQUE,
    DonVi NVARCHAR(50) DEFAULT 'Cái',
    GiaNhap DECIMAL(18,2),
    GiaBan DECIMAL(18,2)
);

-- Bảng Kho
CREATE TABLE Kho (
    MaKho INT IDENTITY PRIMARY KEY,
    TenKho NVARCHAR(100) NOT NULL
);

-- Bảng Tồn kho
CREATE TABLE TonKho (
    MaSP INT REFERENCES SanPham(MaSP),
    MaKho INT REFERENCES Kho(MaKho),
    SoLuong INT DEFAULT 0,
    PRIMARY KEY (MaSP, MaKho)
);

-- Bảng Nhập/Xuất
CREATE TABLE PhieuNhap (
    MaPhieu INT IDENTITY PRIMARY KEY,
    MaSP INT REFERENCES SanPham(MaSP),
    MaKho INT REFERENCES Kho(MaKho),
    SoLuong INT,
    NgayNhap DATETIME DEFAULT GETDATE()
);

CREATE TABLE PhieuXuat (
    MaPhieu INT IDENTITY PRIMARY KEY,
    MaSP INT REFERENCES SanPham(MaSP),
    MaKho INT REFERENCES Kho(MaKho),
    SoLuong INT,
    NgayXuat DATETIME DEFAULT GETDATE()
);
GO