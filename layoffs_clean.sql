-- Check the data.

SELECT *
FROM dbo.layoffs;


-- Change data types. I did it this way because the preview gave me errors, this gets the job done.

ALTER TABLE dbo.layoffs
ALTER COLUMN total_laid_off VARCHAR(MAX);

UPDATE dbo.layoffs
SET total_laid_off = LTRIM(RTRIM(total_laid_off));

SELECT *
FROM dbo.layoffs
WHERE total_laid_off LIKE '%NULL%';

UPDATE dbo.layoffs
SET total_laid_off = '999999999'
WHERE total_laid_off LIKE '%NULL%';

ALTER TABLE dbo.layoffs
ALTER COLUMN total_laid_off INT;


UPDATE dbo.layoffs
SET date = LTRIM(RTRIM(date));

SELECT *
FROM dbo.layoffs
WHERE date IS NULL;

ALTER TABLE dbo.layoffs
ALTER COLUMN date DATE;


-- Let's leave that, and do the serious stuff NOT in the original table, so we have a backup

SELECT *
INTO dbo.layoffs_stage
FROM dbo.layoffs;

SELECT *
FROM dbo.layoffs_stage;


-- Remove duplicates

SELECT *, 
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions ORDER BY company) duplicates
FROM dbo.layoffs_stage;

WITH duplicates_cte AS (
SELECT *, 
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions ORDER BY company) Duplicates
FROM dbo.layoffs_stage)
DELETE
FROM duplicates_cte
WHERE Duplicates > 1;


-- Standardizing data

UPDATE dbo.layoffs_stage
SET country = LTRIM(RTRIM(country));

SELECT DISTINCT industry
FROM layoffs_stage
ORDER BY 1;

UPDATE dbo.layoffs_stage
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

UPDATE dbo.layoffs_stage
SET country = TRIM(TRAILING '.' FROM country);


-- Let's try to populate blanks or nulls.

SELECT DISTINCT industry
FROM dbo.layoffs_stage
ORDER BY 1;

SELECT *
FROM dbo.layoffs_stage
WHERE industry IS NULL;

UPDATE dbo.layoffs_stage
SET company = NULL
WHERE company = '';

SELECT *
FROM layoffs_stage t1
JOIN layoffs_stage t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_stage t1
JOIN layoffs_stage t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE dbo.layoffs_stage
SET funds_raised_millions = NULL
WHERE funds_raised_millions LIKE '%999999999%';

SELECT *
FROM dbo.layoffs_stage;


-- Nothing more to do because there's not a total employees, so we don't know how much it affect overall, but the end!
-- Let's now do some analysis

SELECT MAX(total_laid_off) Max_laid_off, MAX(percentage_laid_off) Max_percentage_laid_off
FROM layoffs_stage;

SELECT *
FROM layoffs_stage
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT company, industry, country, SUM(total_laid_off) Sum_laid_off
FROM layoffs_stage
GROUP BY company, industry, country
ORDER BY Sum_laid_off DESC;

SELECT YEAR(date) year, SUM(total_laid_off)
FROM layoffs_stage
GROUP BY YEAR(date)
ORDER BY year DESC;


SELECT FORMAT(date, 'yyyy-M') AS Year_Month, SUM(total_laid_off) Sum_laid_off
FROM layoffs_stage
GROUP BY FORMAT(date, 'yyyy-M')
ORDER BY Sum_laid_off DESC;


-- Let's do a rolling total!

WITH Rolling_Total AS
(
SELECT FORMAT(date, 'yyyy-M') AS Year_Month, SUM(total_laid_off) Sum_Month_Year
FROM layoffs_stage
GROUP BY FORMAT(date, 'yyyy-M')
)
SELECT Year_Month, SUM(Sum_Month_Year) OVER(ORDER BY Year_Month) 
FROM Rolling_Total;

DELETE
FROM layoffs_stage
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


-- I've had to change the datatype to nvarchar because the window function was having problems with it. Good that is in the date format

ALTER TABLE dbo.layoffs_stage  
ALTER COLUMN date nvarchar(150);

SELECT SUBSTRING(date,1,7) Year, SUM(total_laid_off) Total_Sum_Laid_off
FROM layoffs_stage
GROUP BY SUBSTRING(date,1,7);

WITH Roll_Total AS 
(
SELECT SUBSTRING(date,1,7) Year_Month, SUM(total_laid_off) Total_Sum
FROM layoffs_stage
WHERE SUBSTRING(date,1,7) IS NOT NULL
GROUP BY SUBSTRING(date,1,7)
)
SELECT Year_Month, Total_Sum, SUM(Total_Sum) OVER(ORDER BY Year_Month) Rolling_Total
FROM Roll_Total;

SELECT company, YEAR(date) Year, SUM(total_laid_off) Total_Sum
FROM layoffs_stage
GROUP BY company, YEAR(date)
ORDER BY Total_Sum DESC;

WITH Company_Year AS 
(
SELECT company, YEAR(date) Year, SUM(total_laid_off) Total_Sum
FROM layoffs_stage
WHERE date IS NOT NULL
GROUP BY company, YEAR(date)
HAVING SUM(total_laid_off) IS NOT NULL
)
SELECT *, DENSE_RANK() OVER(PARTITION BY Year ORDER BY Total_Sum DESC) Rank
FROM Company_Year
ORDER BY Rank, year;


WITH Company_Year AS 
(
SELECT company, YEAR(date) Year, SUM(total_laid_off) Total_Sum
FROM layoffs_stage
WHERE date IS NOT NULL
GROUP BY company, YEAR(date)
HAVING SUM(total_laid_off) IS NOT NULL
), Company_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY Year ORDER BY Total_Sum DESC) Rank
FROM Company_Year
)
SELECT *
FROM Company_Rank
WHERE Rank <= 5;

SELECT *
FROM [dbo].[layoffs_stage];

-- Finished. Happy with the results. I guess I can dive more into it but I'm happy with what I've got. Thanks to Alex The Analyst, really great guy.























































