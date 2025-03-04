WITH StockIn AS (
    SELECT 
        FORMAT(p.[UpdatedDate], 'yyyy-MM') AS Month,
        I.ItemID,
        I.ItemCode,
        IC.[Description], 
        SUM(WS.Quantity) AS Total_Added
    FROM AwtadSonicData.dbo.WarehouseStock AS WS
    left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WS.[PackID] = p.[PackID]
	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
    JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
    WHERE p.[UpdatedDate] IS NOT NULL
    GROUP BY FORMAT(p.[UpdatedDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
), 
StockOut AS (
        SELECT 
        FORMAT(T.[TransactionDate], 'yyyy-MM') AS Month,
        I.ItemID,
        I.ItemCode,
        IC.[Description], 
        SUM(WSH.QuantityChange) AS Total_Sold
    FROM AwtadSonicData.dbo.WarehouseStockHistoryArc AS WSH
    left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WSH.[PackID] = p.[PackID]
	left JOIN  [AwtadSonicData].[dbo].[Transaction]  AS T ON WSH.[TransactionID] = T.[TransactionID]
	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
    JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
    WHERE WSH.QuantityChange < 0  
    GROUP BY FORMAT(T.[TransactionDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
)
SELECT 
    COALESCE(SI.Month, SO.Month) AS Month,
    COALESCE(SI.ItemID, SO.ItemID) AS ItemID,
    COALESCE(SI.ItemCode, SO.ItemCode) AS ItemCode,
    COALESCE(SI.[Description], SO.[Description]) AS Product_Name,
    COALESCE(SI.Total_Added, 0) AS Total_Added,
    COALESCE(SO.Total_Sold, 0) AS Total_Sold
FROM StockIn SI
FULL OUTER JOIN StockOut SO 
ON SI.Month = SO.Month AND SI.ItemID = SO.ItemID
ORDER BY Month DESC;

-----------------------------------------------------------------------------------------------------------------
WITH Payments AS (
    SELECT 
        CP.CustomerID,
        C.CustomerCode,
        SUM(CP.AppliedAmount) AS Total_Payment
    FROM AwtadSonicData.dbo.CustomerPayment AS CP
    JOIN AwtadSonicData.dbo.Customer AS C ON CP.CustomerID = C.CustomerID
    WHERE CP.PaymentDate IS NOT NULL
    GROUP BY CP.CustomerID, C.CustomerCode
), 
Orders AS (
    SELECT 
        SO.CustomerID,
        C.CustomerCode,
        COUNT(SO.OrderID) AS Total_Orders,
        SUM(SO.GrossTotal) AS Total_Order_Amount
    FROM AwtadSonicData.dbo.SalesOrder AS SO
    JOIN AwtadSonicData.dbo.Customer AS C ON SO.CustomerID = C.CustomerID
    WHERE SO.OrderDate IS NOT NULL
    GROUP BY SO.CustomerID, C.CustomerCode
)
SELECT 
    COALESCE(P.CustomerID, O.CustomerID) AS CustomerID,
    COALESCE(P.CustomerCode, O.CustomerCode) AS CustomerCode,
    COALESCE(O.Total_Orders, 0) AS Total_Orders,
    COALESCE(O.Total_Order_Amount, 0) AS Total_Order_Amount,
    COALESCE(P.Total_Payment, 0) AS Total_Payment
FROM Payments P
FULL OUTER JOIN Orders O ON P.CustomerID = O.CustomerID
ORDER BY Total_Payment Desc;
--------------------------------------------------------------------------------
SELECT 
    SO.OrderID,
    SO.OrderDate,
	SO.[CustomerID],
    SO.[DesiredDeliveryDate],
	OSL.Description AS OrderSatus,
    SO.[GrossTotal],
	SO.[GPSLatitude],
    SO.[GPSlongitude],
	SO.[CreatedBy],
    SO.[CreatedDate],
    SO.[UpdatedBy],
    SO.[UpdatedDate],
    E.EmployeeID,
    E.EmployeeCode
FROM 
   [AwtadSonicData].[dbo].[SalesOrder] AS SO
JOIN 
    [AwtadSonicData].[dbo].[Employee] AS E
ON 
    SO.EmployeeID = E.EmployeeID
JOIN 
    [AwtadSonicData].[dbo].[OrderStatusLanguage] AS OSL
ON 
    SO.OrderStatusID = OSL.OrderStatusID and OSL.LanguageID = 2
WHERE 
    SO.OrderID IS NOT NULL
ORDER BY 
    SO.OrderDate DESC;


-----------------------------------------------------------
SELECT 
    SD.OrderID,
    SD.PackID,
    SD.Quantity AS PackQuantity,
    SD.Price AS PackPrice,
	P.Quantity AS ItemQuantityForOnePack,
	IL.Description AS ProductName,
    C.CustomerID,
    C.CustomerCode
FROM 
   [AwtadSonicData].[dbo].[SalesOrderDetail] AS SD
JOIN 
    [AwtadSonicData].[dbo].[Customer] AS C
ON 
    SD.[CustomerID] = C.CustomerID
JOIN 
    [AwtadSonicData].[dbo].[Pack] AS P
ON 
    SD.[PackID] = p.[PackID]
JOIN 
    [AwtadSonicData].[dbo].[ItemLanguage] AS IL
ON 
    P.ItemID = IL.ItemID and IL.[LanguageID]= 2
WHERE 
    SD.OrderID IS NOT NULL
ORDER BY 
    SD.OrderID DESC;


-----------------------------------------------------------
WITH StockIn AS (
    SELECT 
        p.[UpdatedDate] AS Date,
        I.ItemID,
        I.ItemCode,
        IC.[Description], 
        SUM(WS.Quantity) AS Total_Added
    FROM AwtadSonicData.dbo.WarehouseStock AS WS
    left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WS.[PackID] = p.[PackID]
	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
    JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
    WHERE p.[UpdatedDate] IS NOT NULL
    GROUP BY FORMAT(p.[UpdatedDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
), 
StockOut AS (
        SELECT 
        T.[TransactionDate] AS Date,
        I.ItemID,
        I.ItemCode,
        IC.[Description], 
        SUM(WSH.QuantityChange) AS Total_Sold
    FROM AwtadSonicData.dbo.WarehouseStockHistoryArc AS WSH
    left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WSH.[PackID] = p.[PackID]
	left JOIN  [AwtadSonicData].[dbo].[Transaction]  AS T ON WSH.[TransactionID] = T.[TransactionID]
	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
    JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
    WHERE WSH.QuantityChange < 0  
    GROUP BY FORMAT(T.[TransactionDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
)
SELECT 
    COALESCE(SI.Date, SO.Date) AS Date,
    COALESCE(SI.ItemID, SO.ItemID) AS ItemID,
    COALESCE(SI.ItemCode, SO.ItemCode) AS ItemCode,
    COALESCE(SI.[Description], SO.[Description]) AS Product_Name,
    COALESCE(SI.Total_Added, 0) AS Total_Added,
    COALESCE(SO.Total_Sold, 0) AS Total_Sold
FROM StockIn SI
FULL OUTER JOIN StockOut SO 
ON SI.Date = SO.Date AND SI.ItemID = SO.ItemID
ORDER BY Month DESC;

-------------------------------------------------------------
SELECT 
    FORMAT(SO.OrderDate, 'yyyy-MM') AS OrderMonth,
    COUNT(CASE WHEN SO.OrderStatusID = 1 THEN SO.OrderID END) AS Received_Orders,      -- الطلبات المستلمة customer
    COUNT(CASE WHEN SO.OrderStatusID = 2 THEN SO.OrderID END) AS Approved_Orders,      -- الطلبات الموافق عليها  cus
    COUNT(CASE WHEN SO.OrderStatusID = 3 THEN SO.OrderID END) AS Shipped_Orders,       -- الطلبات التي خرجت من المخزن
    COUNT(CASE WHEN SO.OrderStatusID = 4 THEN SO.OrderID END) AS Delivered_Orders,     -- الطلبات المسلّمة
    COUNT(CASE WHEN SO.OrderStatusID = 5 THEN SO.OrderID END) AS Returned_Orders       -- الطلبات المرتجعة
FROM AwtadSonicData.dbo.SalesOrder AS SO
WHERE SO.OrderDate IS NOT NULL
GROUP BY FORMAT(SO.OrderDate, 'yyyy-MM')
ORDER BY OrderMonth DESC;
-----------------------------
 --   SELECT 
 --       FORMAT(p.[UpdatedDate], 'yyyy-MM') AS Month,
 --       I.ItemID,
 --       I.ItemCode,
 --       IC.[Description], 
 --       SUM(WS.Quantity) AS Total_Added
 --   FROM AwtadSonicData.dbo.WarehouseStock AS WS
 --   left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WS.[PackID] = p.[PackID]
	--JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
 --   JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
 --   WHERE p.[UpdatedDate] IS NOT NULL
 --   GROUP BY FORMAT(p.[UpdatedDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]

-----------------------------------------------------------------------------------------------
 --   SELECT 
 --       FORMAT(T.[TransactionDate], 'yyyy-MM') AS Month,
 --       I.ItemID,
 --       I.ItemCode,
 --       IC.[Description], 
 --       SUM(WSH.QuantityChange) AS Total_Sold
 --   FROM AwtadSonicData.dbo.WarehouseStockHistoryArc AS WSH
 --   left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WSH.[PackID] = p.[PackID]
	--left JOIN  [AwtadSonicData].[dbo].[Transaction]  AS T ON WSH.[TransactionID] = T.[TransactionID]
	--JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
 --   JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
 --   WHERE WSH.QuantityChange < 0  
 --   GROUP BY FORMAT(T.[TransactionDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]

-- WITH StockIn AS (
--    SELECT 
--        FORMAT(p.[UpdatedDate], 'yyyy-MM') AS Month,
--        I.ItemID,
--        I.ItemCode,
--        IC.[Description] AS ProductName, 
--        SUM(WS.Quantity) AS Total_Added
--    FROM AwtadSonicData.dbo.WarehouseStock AS WS
--    left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WS.[PackID] = p.[PackID]
--	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
--    JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
--    WHERE p.[UpdatedDate] IS NOT NULL
--    GROUP BY FORMAT(p.[UpdatedDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
--), 
--StockOut AS (
--    SELECT 
--        FORMAT(SO.OrderDate, 'yyyy-MM') AS Month,
--        SO.OrderID,
--        SO.OrderDate,
--        E.EmployeeID,
--        E.EmployeeCode,
--        ETL.Description AS OrderTakerName,
--        I.ItemID,
--        I.ItemCode,
--        IC.[Description] AS ProductName, 
--        SUM(SO.GrossTotal) AS Total_Sales_Amount
--    FROM AwtadSonicData.dbo.SalesOrder AS SO
--    JOIN AwtadSonicData.dbo.Employee AS E ON SO.EmployeeID = E.EmployeeID
--    LEFT JOIN AwtadSonicData.dbo.EmployeeTypeLanguage AS ETL ON E.EmployeeTypeID = ETL.EmployeeTypeID
--    JOIN AwtadSonicData.dbo.Item AS I ON SO.OrderID = I.ItemID
--	JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
--    WHERE SO.OrderDate IS NOT NULL
--    GROUP BY FORMAT(SO.OrderDate, 'yyyy-MM'), SO.OrderID, SO.OrderDate, E.EmployeeID, E.EmployeeCode, ETL.Description, I.ItemID, I.ItemCode, IC.[Description]
--), 
--Payments AS (
--    SELECT 
--        FORMAT(CP.PaymentDate, 'yyyy-MM') AS Month,
--        C.CustomerID,
--        C.CustomerCode,
--        SUM(CP.AppliedAmount) AS Total_Collected
--    FROM AwtadSonicData.dbo.CustomerPayment AS CP
--    JOIN AwtadSonicData.dbo.Customer AS C ON CP.CustomerID = C.CustomerID
--    WHERE CP.PaymentDate IS NOT NULL
--    GROUP BY FORMAT(CP.PaymentDate, 'yyyy-MM'), C.CustomerID, C.CustomerCode
--)
--SELECT 
--    COALESCE(SI.Month, SO.Month, P.Month) AS Month,
--    COALESCE(SO.OrderID, 0) AS OrderID,
--    COALESCE(SO.OrderDate, NULL) AS OrderDate,
--    COALESCE(SO.EmployeeID, 0) AS EmployeeID,
--    COALESCE(SO.EmployeeCode, 'N/A') AS EmployeeCode,
--    COALESCE(SO.OrderTakerName, 'Unknown') AS OrderTakerName,
--    COALESCE(SI.ItemID, SO.ItemID) AS ItemID,
--    COALESCE(SI.ItemCode, SO.ItemCode) AS ItemCode,
--    COALESCE(SI.ProductName, SO.ProductName) AS ProductName,
--    COALESCE(SI.Total_Added, 0) AS Total_Added,
--    COALESCE(SO.Total_Sales_Amount, 0) AS Total_Sales_Amount,
--    COALESCE(P.Total_Collected, 0) AS Total_Collected
--FROM StockIn SI
--FULL OUTER JOIN StockOut SO ON SI.Month = SO.Month AND SI.ItemID = SO.ItemID
--FULL OUTER JOIN Payments P ON SI.Month = P.Month
--ORDER BY Month DESC;
