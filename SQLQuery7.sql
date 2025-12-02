USE WarehouseDB;
GO

--------------------------------------------------------------------------------
-- 1) Thêm cột WarehouseID vào ImportDetails / ExportDetails (nếu chưa có)
--------------------------------------------------------------------------------
IF COL_LENGTH('dbo.ImportDetails', 'WarehouseID') IS NULL
BEGIN
    ALTER TABLE dbo.ImportDetails
    ADD WarehouseID INT NULL;
END
GO

IF COL_LENGTH('dbo.ExportDetails', 'WarehouseID') IS NULL
BEGIN
    ALTER TABLE dbo.ExportDetails
    ADD WarehouseID INT NULL;
END
GO

-- Thêm ràng buộc FK nếu chưa có (kiểm tra tồn tại trước)
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys fk
    WHERE fk.parent_object_id = OBJECT_ID('dbo.ImportDetails')
      AND fk.referenced_object_id = OBJECT_ID('dbo.Warehouses')
)
BEGIN
    ALTER TABLE dbo.ImportDetails
    ADD CONSTRAINT FK_ImportDetails_Warehouses FOREIGN KEY (WarehouseID) REFERENCES dbo.Warehouses(WarehouseID);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys fk
    WHERE fk.parent_object_id = OBJECT_ID('dbo.ExportDetails')
      AND fk.referenced_object_id = OBJECT_ID('dbo.Warehouses')
)
BEGIN
    ALTER TABLE dbo.ExportDetails
    ADD CONSTRAINT FK_ExportDetails_Warehouses FOREIGN KEY (WarehouseID) REFERENCES dbo.Warehouses(WarehouseID);
END
GO

--------------------------------------------------------------------------------
-- 2) VIEWS
--------------------------------------------------------------------------------

-- View: thông tin sản phẩm kèm tổng tồn và giá trị tồn
IF OBJECT_ID('dbo.vw_ProductStock', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ProductStock;
GO

CREATE VIEW dbo.vw_ProductStock
AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.Unit,
    p.Price,
    ISNULL(SUM(s.Quantity), 0) AS TotalQuantity,
    ISNULL(SUM(s.Quantity), 0) * ISNULL(p.Price, 0) AS TotalValue
FROM dbo.Products p
LEFT JOIN dbo.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN dbo.Stock s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Unit, p.Price;
GO

-- View: tồn theo kho + tên sản phẩm
IF OBJECT_ID('dbo.vw_StockByWarehouse', 'V') IS NOT NULL
    DROP VIEW dbo.vw_StockByWarehouse;
GO

CREATE VIEW dbo.vw_StockByWarehouse
AS
SELECT 
    w.WarehouseID,
    w.WarehouseName,
    p.ProductID,
    p.ProductName,
    ISNULL(s.Quantity,0) AS Quantity
FROM dbo.Warehouses w
JOIN dbo.Stock s ON s.WarehouseID = w.WarehouseID
JOIN dbo.Products p ON p.ProductID = s.ProductID;
GO

-- View: chi tiết phiếu nhập đầy đủ (kèm tên kho nếu có)
IF OBJECT_ID('dbo.vw_ImportDetailsFull', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ImportDetailsFull;
GO

CREATE VIEW dbo.vw_ImportDetailsFull
AS
SELECT 
    i.ImportID,
    i.ImportDate,
    sup.SupplierName,
    id.DetailID,
    id.WarehouseID,
    w.WarehouseName,
    id.ProductID,
    p.ProductName,
    id.Quantity,
    id.Price,
    id.Quantity * id.Price AS LineTotal,
    i.TotalAmount
FROM dbo.Import i
LEFT JOIN dbo.Suppliers sup ON i.SupplierID = sup.SupplierID
LEFT JOIN dbo.ImportDetails id ON i.ImportID = id.ImportID
LEFT JOIN dbo.Products p ON id.ProductID = p.ProductID
LEFT JOIN dbo.Warehouses w ON id.WarehouseID = w.WarehouseID;
GO

--------------------------------------------------------------------------------
-- 3) TRIGGERS
--------------------------------------------------------------------------------

-- IMPORT DETAILS TRIGGER: khi thêm ImportDetails -> cập nhật Stock (cộng)
IF OBJECT_ID('dbo.trg_AfterInsert_ImportDetails', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_AfterInsert_ImportDetails;
GO

CREATE TRIGGER dbo.trg_AfterInsert_ImportDetails
ON dbo.ImportDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Nếu bảng Inserted có dòng nào có WarehouseID NULL -> raise và rollback để tránh update không xác định
        IF EXISTS (SELECT 1 FROM Inserted WHERE WarehouseID IS NULL)
        BEGIN
            RAISERROR('ImportDetails chứa WarehouseID NULL. Vui lòng cung cấp WarehouseID khi chèn phiếu nhập.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Dùng MERGE để cập nhật hoặc insert vào Stock
        MERGE INTO dbo.Stock AS target
        USING (
            SELECT ProductID, WarehouseID, SUM(Quantity) AS Quantity
            FROM Inserted
            GROUP BY ProductID, WarehouseID
        ) AS src (ProductID, WarehouseID, Quantity)
        ON target.ProductID = src.ProductID AND target.WarehouseID = src.WarehouseID
        WHEN MATCHED THEN
            UPDATE SET Quantity = target.Quantity + src.Quantity
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (ProductID, WarehouseID, Quantity)
            VALUES (src.ProductID, src.WarehouseID, src.Quantity);
    END TRY
    BEGIN CATCH
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in trg_AfterInsert_ImportDetails: %s', 16, 1, @err);
        ROLLBACK TRANSACTION;
    END CATCH
END;
GO

-- EXPORT DETAILS TRIGGER: khi thêm ExportDetails -> kiểm tra tồn, nếu đủ thì trừ; nếu thiếu thì rollback
IF OBJECT_ID('dbo.trg_AfterInsert_ExportDetails', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_AfterInsert_ExportDetails;
GO

CREATE TRIGGER dbo.trg_AfterInsert_ExportDetails
ON dbo.ExportDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Nếu có WarehouseID NULL -> báo lỗi
        IF EXISTS (SELECT 1 FROM Inserted WHERE WarehouseID IS NULL)
        BEGIN
            RAISERROR('ExportDetails chứa WarehouseID NULL. Vui lòng cung cấp WarehouseID khi chèn phiếu xuất.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 1) Kiểm tra tồn: nếu có bản ghi nào làm quantity âm -> rollback
        IF EXISTS (
            SELECT 1
            FROM (
                SELECT i.ProductID, i.WarehouseID, SUM(i.Quantity) AS NeedQty
                FROM Inserted i
                GROUP BY i.ProductID, i.WarehouseID
            ) AS need
            LEFT JOIN dbo.Stock s
                ON s.ProductID = need.ProductID AND s.WarehouseID = need.WarehouseID
            WHERE ISNULL(s.Quantity, 0) < need.NeedQty
        )
        BEGIN
            RAISERROR('Không đủ tồn để xuất một hoặc nhiều mặt hàng. Giao dịch bị hủy.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2) Nếu đủ tồn, cập nhật Stock: trừ số lượng (group by để trừ tổng)
        UPDATE s
        SET s.Quantity = s.Quantity - need.NeedQty
        FROM dbo.Stock s
        JOIN (
            SELECT ProductID, WarehouseID, SUM(Quantity) AS NeedQty
            FROM Inserted
            GROUP BY ProductID, WarehouseID
        ) AS need
        ON s.ProductID = need.ProductID AND s.WarehouseID = need.WarehouseID;
    END TRY
    BEGIN CATCH
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in trg_AfterInsert_ExportDetails: %s', 16, 1, @err);
        ROLLBACK TRANSACTION;
    END CATCH
END;
GO
