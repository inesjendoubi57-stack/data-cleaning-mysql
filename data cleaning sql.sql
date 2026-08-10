SHOW WARNINGS ;
SELECT version();
USE world_dayoffs  ;
SHOW CREATE TABLE layoffs;
SELECT COUNT(*)
FROM layoffs ;
SELECT *
FROM layoffs 
LIMIT 10;
SELECT *
FROM layoffs ;
CREATE TABLE stagging_layoffs
LIKE layoffs ;
INSERT INTO stagging_layoffs
SELECT *
FROM layoffs ;
-- remove_duplicates
SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date') AS row_num 
FROM stagging_layoffs ;
WITH duplicates_cte AS
( 
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date') AS row_num 
FROM stagging_layoffs
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;
CREATE TABLE `stagging_layoffs2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
   `row_num` INT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM stagging_layoffs2 ;
INSERT INTO stagging_layoffs2 
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num 
FROM stagging_layoffs ;
DELETE FROM stagging_layoffs2 
WHERE row_num > 1 ;
-- Standardizing data

SELECT company,TRIM(company)
FROM stagging_layoffs2 ;
UPDATE stagging_layoffs2 
SET company= TRIM(company);
SELECT *
FROM stagging_layoffs2
WHERE industry LIKE 'Crypto%' ;
UPDATE stagging_layoffs2
SET industry = 'CRYPTO'
WHERE industry LIKE 'Crypto%' ;
SELECT DISTINCT location
FROM stagging_layoffs2 ;
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM stagging_layoffs2 
ORDER BY 1 ;
UPDATE stagging_layoffs2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'united states%';


SELECT 
	date,
	STR_TO_DATE(TRIM(date), '%m/%d/%Y') AS DATES
FROM stagging_layoffs2 ;
DESCRIBE stagging_layoffs2;
SELECT `date`
FROM stagging_layoffs2
LIMIT 10;
UPDATE stagging_layoffs2
SET date = STR_TO_DATE(TRIM(date), '%m/%d/%Y') ;
ALTER TABLE stagging_layoffs2
MODIFY COLUMN date DATE ; 