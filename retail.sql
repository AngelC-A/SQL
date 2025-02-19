-- Found this retail dataset and got to work

SELECT *
FROM dbo.Online_Retail;

SELECT *
FROM dbo.oonline_retail;


-- Backup

SELECT *
INTO dbo.oonline_retail
FROM dbo.Online_Retail;


-- Let's remove duplicates

WITH Dups AS(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country ORDER BY CustomerID)
		AS dup
	FROM dbo.oonline_retail
)
DELETE
FROM Dups
WHERE dup > 1;


-- Some cleaning of missing values

SELECT *
FROM oonline_retail t1
JOIN oonline_retail t2
	ON t1.InvoiceNo = t2.InvoiceNo
	AND t1.InvoiceDate = t2.InvoiceDate
WHERE t1.CustomerID IS NULL
AND t2.CustomerID IS NOT NULL;

SELECT *
FROM dbo.oonline_retail
WHERE CustomerID IS NULL;

DELETE dbo.oonline_retail
WHERE CustomerID IS NULL;


-- Remove non-numeric stuff from stock code

SELECT *
FROM oonline_retail
ORDER BY StockCode DESC;

DELETE FROM oonline_retail
WHERE ISNUMERIC(StockCode) = 0;

SELECT *
FROM oonline_retail
ORDER BY StockCode DESC;

SELECT *
FROM oonline_retail
ORDER BY InvoiceNo DESC;


-- Change data types

SELECT *,
	LEFT(InvoiceDate, CHARINDEX(' ',InvoiceDate) -1) InvoiceDateFix,
	SUBSTRING(InvoiceDate, CHARINDEX(' ', InvoiceDate) +1, LEN(InvoiceDate)) InvoiceTime
FROM 
	dbo.oonline_retail;


ALTER TABLE dbo.oonline_retail
ADD OnlyDate DATE

UPDATE dbo.oonline_retail
SET OnlyDate = CAST(InvoiceDate AS DATE)


ALTER TABLE dbo.oonline_retail
ALTER COLUMN [Quantity] INT;


-- Total sales column

ALTER TABLE dbo.oonline_retail
ADD Sales DECIMAL(18,2);

UPDATE dbo.oonline_retail
SET Sales = UnitPrice * Quantity;


-- Let's see yearly and monthly sales

SELECT 
	YEAR(InvoiceDate) AS sales_year,
	MONTH(InvoiceDate) AS sales_month,
	SUM([Sales]) AS Monthly_Sales
FROM 
	dbo.oonline_retail
GROUP BY 
	YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY 
	Monthly_Sales DESC;


-- Average Order Value (AOV)

SELECT
	SUM(Sales) / COUNT(InvoiceNo) AOV
FROM dbo.oonline_retail;


-- Best selling products

SELECT 
	StockCode,
	Description,
	SUM(Sales) Total_Sales
FROM 
	dbo.oonline_retail
GROUP BY
	StockCode,
	Description
ORDER BY 
	Total_Sales DESC;


-- Sales based on country

SELECT 
	Country,
	SUM(Sales)
FROM
	dbo.oonline_retail
GROUP BY  
	Country;


-- How much a customer spends 

SELECT 
    [CustomerID], 
    COUNT([InvoiceNo]) AS total_purchases, 
    SUM([Sales]) AS total_spent
FROM 
    oonline_retail
GROUP BY 
    [CustomerID]
ORDER BY 
    total_spent DESC;


-- Total Purchase by customer

SELECT DISTINCT Description
FROM dbo.oonline_retail;

SELECT 
	[CustomerID],
	[Description],
	COUNT(InvoiceNo) purchase_count
FROM
	dbo.oonline_retail
GROUP BY 
	[CustomerID], [Description]
ORDER BY
	purchase_count DESC;


-- Purchase frequency by customer

SELECT
	[CustomerID],
	OnlyDate,
	DATEDIFF(day, MIN(OnlyDate), MAX(OnlyDate)) / COUNT(*) average_days_between_purchases
FROM
	dbo.oonline_retail
GROUP BY 
	[CustomerID], OnlyDate
ORDER BY
	OnlyDate DESC;


SELECT *
FROM dbo.oonline_retail;


-- Average Customer Lifespan

WITH CustomerMinMax AS (
    SELECT 
        CustomerID,
        MIN(InvoiceDate) AS FirstTransactionDate,
        MAX(InvoiceDate) AS LastTransactionDate
    FROM 
        oonline_retail
    GROUP BY 
        CustomerID
)
SELECT 
    AVG(DATEDIFF(YEAR, FirstTransactionDate, LastTransactionDate)) AS AvgCustomerLifespan
FROM 
    CustomerMinMax;


-- Customer Lifetime Value (CLTV)

WITH Customer AS (
    SELECT 
        c.CustomerID,
        SUM(c.Sales) AS TotalRevenue,
        AVG(c.Sales) AS AvgRevenue,
        DATEDIFF(DAY, MIN(c.InvoiceDate), MAX(c.InvoiceDate)) AS LifespanInDays
    FROM 
        oonline_retail c
    GROUP BY 
        c.CustomerID
)
SELECT 
    CustomerID,
    FORMAT(TotalRevenue * (LifespanInDays / 365.0),'N2' ) AS CustomerLifetimeValue
FROM 
    Customer
ORDER BY CustomerLifetimeValue DESC;

