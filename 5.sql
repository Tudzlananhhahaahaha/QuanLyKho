INSERT INTO Categories (CategoryName)
VALUES (N'Điện tử'), (N'Thời trang'), (N'Thực phẩm');

INSERT INTO Suppliers (SupplierName, Phone, Address)
VALUES (N'Công ty trách nhiệm hữu hạn một thành viên', '0901234567', N'Hà Nội'),
       (N'Nhà cung cấp cổ phần đông dương', '0907654321', N'Hồ Chí Minh');

INSERT INTO Products (ProductName, CategoryID, SupplierID, Unit, Price)
VALUES (N'TiVi Samsung', 1, 1, N'Cái', 12000000),
       (N'Áo thun nam', 2, 2, N'Cái', 150000),
       (N'Mì tôm Hảo Hảo', 3, 2, N'Thùng', 90000);

INSERT INTO Warehouses (WarehouseName, Location)
VALUES (N'Kho Hà Nội', N'Long Biên'),
       (N'Kho Sài Gòn', N'Quận 9');

INSERT INTO Stock (ProductID, WarehouseID, Quantity)
VALUES (1, 1, 20), (2, 1, 50), (3, 2, 100);

-- tạo header import trước
INSERT INTO Import (SupplierID) VALUES (1);
DECLARE @id INT = SCOPE_IDENTITY();

-- insert details (bắt buộc có WarehouseID)
INSERT INTO ImportDetails (ImportID, ProductID, Quantity, Price, WarehouseID)
VALUES (@id, 1, 5, 100000, 1);
-- trigger sẽ tự động cộng 5 vào Stock(ProductID=1, WarehouseID=1)

-- tạo header export
INSERT INTO Export (CustomerName) VALUES (N'Khách lẻ');
DECLARE @eid INT = SCOPE_IDENTITY();

-- insert export details
INSERT INTO ExportDetails (ExportID, ProductID, Quantity, Price, WarehouseID)
VALUES (@eid, 1, 2, 110000, 1);
-- trigger sẽ kiểm tra tồn rồi trừ 2 nếu đủ; nếu thiếu -> rollback và lỗi
