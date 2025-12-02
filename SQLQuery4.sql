--Categories-loại hàng--
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255)
);
--Suppliers-Nhà cung cấp--
CREATE TABLE Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(150) NOT NULL,
    Phone VARCHAR(20),
    Address NVARCHAR(200)
);
--Products – sản phẩm--
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL,
    CategoryID INT,
    SupplierID INT,
    Unit NVARCHAR(50),
    Price DECIMAL(18,2),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
--Warehouses – kho--
CREATE TABLE Warehouses (
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName NVARCHAR(150) NOT NULL,
    Location NVARCHAR(200)
);
--Stock – tồn kho--
CREATE TABLE Stock (
    StockID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    Quantity INT DEFAULT 0,
    CONSTRAINT FK_Stock_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT FK_Stock_Warehouses FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID)
);
--Import (Phiếu nhập)--
CREATE TABLE Import (
    ImportID INT IDENTITY(1,1) PRIMARY KEY,
    ImportDate DATE NOT NULL DEFAULT GETDATE(),
    SupplierID INT,
    TotalAmount DECIMAL(18,2),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
--ImportDetails (Chi tiết phiếu nhập)--
CREATE TABLE ImportDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    ImportID INT,
    ProductID INT,
    Quantity INT,
    Price DECIMAL(18,2),
    FOREIGN KEY (ImportID) REFERENCES Import(ImportID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
--Export (Phiếu xuất)--
CREATE TABLE Export (
    ExportID INT IDENTITY(1,1) PRIMARY KEY,
    ExportDate DATE NOT NULL DEFAULT GETDATE(),
    CustomerName NVARCHAR(150),
    TotalAmount DECIMAL(18,2)
);
CREATE TABLE ExportDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    ExportID INT,
    ProductID INT,
    Quantity INT,
    Price DECIMAL(18,2),
    FOREIGN KEY (ExportID) REFERENCES Export(ExportID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
