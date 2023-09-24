-- no 1

INSERT INTO MsInventory
SELECT InventoryID, InventoryName, InventoryPrice, Quantity, InventoryExpirationDate
FROM OPENROWSET(BULK 'C:\DBTakeHomeCase\Var 2\data.json', SINGLE_CLOB) AS json -- cd ke directory
CROSS APPLY OPENJSON(json.bulkColumn)
WITH(
	InventoryID CHAR(5),
	InventoryName VARCHAR(100),
	InventoryPrice INT,
	Quantity INT,
	InventoryExpirationDate DATE
)

SELECT * FROM MsInventory

-- no 2

SELECT InventoryName, CAST(Quantity AS VARCHAR(255)) + ' pcs' AS Quantity,
	InventoryExpirationDate, DATEDIFF(day, CURRENT_TIMESTAMP, InventoryExpirationDate) AS [Time Left]
FROM MsInventory
WHERE Quantity > 500 AND  DATEDIFF(day, CURRENT_TIMESTAMP, InventoryExpirationDate) > 1500
ORDER BY [Time Left] DESC


-- no 3
ALTER TABLE MsCustomer
ADD [Customer Age] INT

GO
UPDATE MsCustomer
SET [Customer Age] = DATEDIFF(YEAR, CustomerDOB, GETDATE())
GO

SELECT * FROM MsCustomer


-- no 7
SELECT TOP 10 CityName, BranchAddress, AVG(total_sum) AS [Average Income], COUNT(CityName) AS [Number Of Transactions]
FROM (
	SELECT SalesID, SUM(Quantity * ProductPrice) AS [total_sum]
	FROM TrSalesDetail td
	JOIN MsProduct mp ON td.ProductID = mp.ProductID
	GROUP BY SalesID
) x
JOIN TrSalesHeader th ON x.SalesID = th.SalesID
JOIN MsBranch mb ON mb.BranchID = th.BranchID
JOIN MsCity mc ON mc.CityID = mb.CityID
GROUP BY CityName, BranchAddress
ORDER BY [Number Of Transactions] DESC


-- no 10

SELECT TOP 5 th.SalesID, SalesDate, CustomerName, ProductName, [total_sum] AS AverageSaleAmount, ProductPrice * Quantity AS [TotalSaleAmount]
FROM (
	SELECT CustomerID, AVG(Quantity * ProductPrice) AS [total_sum]
	FROM TrSalesDetail td
	JOIN MsProduct mp ON td.ProductID = mp.ProductID
	JOIN TrSalesHeader th ON th.SalesID = td.SalesID
	GROUP BY CustomerID
)x
JOIN TrSalesHeader th ON th.CustomerID = x.CustomerID
JOIN TrSalesDetail td ON td.SalesID = th.SalesID
JOIN MsProduct mp ON mp.ProductID = td.ProductID
JOIN MsCustomer mc ON mc.CustomerID = th.CustomerID
WHERE ProductPrice * Quantity > [total_sum]
ORDER BY SalesDate DESC

-- no 13


-- no 20
CREATE LOGIN administrator WITH PASSWORD='admin123'
CREATE USER ADMIN FOR LOGIN administrator
ALTER USER ADMIN WITH NAME = T122