# import pyodbc
#
#
#
# SERVER = 'DESKTOP-KMRFAP7'
# DATABASE = 'AwtadSonicData'
# USERNAME = 'sa'
# PASSWORD = '123'
#
# # connectionString = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
#
#
# connectionString = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=DESKTOP-KMRFAP7;DATABASE=AwtadSonicData;UID=sa;PWD=123"
# conn = pyodbc.connect(connectionString)
#
#
# # conn = pyodbc.connect(connectionString)
#
#
#
#
# SQL_QUERY ="""
#     WITH StockIn AS (
#     SELECT
#         FORMAT(p.[UpdatedDate], 'yyyy-MM') AS Month,
#         I.ItemID,
#         I.ItemCode,
#         IC.[Description],
#         SUM(WS.Quantity) AS Total_Added
#     FROM AwtadSonicData.dbo.WarehouseStock AS WS
#     left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WS.[PackID] = p.[PackID]
# 	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
#     JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
#     WHERE p.[UpdatedDate] IS NOT NULL
#     GROUP BY FORMAT(p.[UpdatedDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
# ),
# StockOut AS (
#         SELECT
#         FORMAT(T.[TransactionDate], 'yyyy-MM') AS Month,
#         I.ItemID,
#         I.ItemCode,
#         IC.[Description],
#         SUM(WSH.QuantityChange) AS Total_Sold
#     FROM AwtadSonicData.dbo.WarehouseStockHistoryArc AS WSH
#     left JOIN [AwtadSonicData].[dbo].[Pack] AS p ON WSH.[PackID] = p.[PackID]
# 	left JOIN  [AwtadSonicData].[dbo].[Transaction]  AS T ON WSH.[TransactionID] = T.[TransactionID]
# 	JOIN AwtadSonicData.dbo.Item AS I ON p.ItemID = I.ItemID
#     JOIN AwtadSonicData.dbo.ItemCategoryLanguage AS IC ON I.ItemCategoryID = IC.ItemCategoryID
#     WHERE WSH.QuantityChange < 0
#     GROUP BY FORMAT(T.[TransactionDate], 'yyyy-MM'), I.ItemID, I.ItemCode, IC.[Description]
# )
# SELECT
#     COALESCE(SI.Month, SO.Month) AS Month,
#     COALESCE(SI.ItemID, SO.ItemID) AS ItemID,
#     COALESCE(SI.ItemCode, SO.ItemCode) AS ItemCode,
#     COALESCE(SI.[Description], SO.[Description]) AS Product_Name,
#     COALESCE(SI.Total_Added, 0) AS Total_Added,
#     COALESCE(SO.Total_Sold, 0) AS Total_Sold
# FROM StockIn SI
# FULL OUTER JOIN StockOut SO
# ON SI.Month = SO.Month AND SI.ItemID = SO.ItemID
# ORDER BY Month DESC;
# """
#
# cursor = conn.cursor()
# cursor.execute(SQL_QUERY)
#
#
#
# records = cursor.fetchall()
# for r in records:
#     print(f"{r.Month}\t{r.ItemID}\t{r.ItemCode}\t{r.Product_Name}\t{r.Total_Added}\t{r.Total_Sold}")
#
#
# cursor.to_excel('output.xlsx', index=False)
#
# print("تم تصدير البيانات بنجاح إلى ملف output.xlsx")






import pyodbc
import pandas as pd

SERVER = 'DESKTOP-KMRFAP7'
DATABASE = 'AwtadSonicData'
USERNAME = 'sa'
PASSWORD = '123'

# Connection string
connectionString = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=DESKTOP-KMRFAP7;DATABASE=AwtadSonicData;UID=sa;PWD=123"
conn = pyodbc.connect(connectionString)

# SQL query
SQL_QUERY1 ="""
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
"""
# SQL query
SQL_QUERY2 = """
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
"""
# SQL query
SQL_QUERY3 ="""
SELECT 
    SO.OrderID,
    SO.OrderDate,
    E.EmployeeID,
    E.EmployeeCode
FROM 
   [AwtadSonicData].[dbo].[SalesOrder] AS SO
JOIN 
    [AwtadSonicData].[dbo].[Employee] AS E
ON 
    SO.EmployeeID = E.EmployeeID
WHERE 
    SO.OrderID IS NOT NULL
ORDER BY 
    SO.OrderDate DESC;
"""


SQL_QUERY4 ="""
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
"""




SQL_QUERY5 ="""
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

"""

# Execute query
cursor = conn.cursor()
cursor.execute(SQL_QUERY5)

# Fetch results
records = cursor.fetchall()
columns = [column[0] for column in cursor.description]

# Convert to DataFrame
df = pd.DataFrame.from_records(records, columns=columns)

# Save DataFrame to Excel
df.to_excel('output5.xlsx', index=False)

# Close cursor and connection
cursor.close()
conn.close()

print("تم تصدير البيانات بنجاح إلى ملف output.xlsx")
