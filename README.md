# World Layoffs Data Cleaning Project

This repository contains a end-to-end data cleaning pipeline written in MySQL. The objective of this project is to transform raw, unstandardized layoff data into a clean, structured dataset ready for Exploratory Data Analysis (EDA).

---

##  Project Overview

Raw real-world datasets often contain missing values, duplicate entries, inconsistent string formatting, and incorrect data types. This project addresses these quality issues step-by-step using a structured ETL (Extract, Transform, Load) workflow within MySQL.

### **Key Data Cleaning Steps:**

1. **Staging Environment Setup:** Creating staging tables to protect raw source data.
2. **Duplicate Identification & Removal:** Utilizing Window Functions (`ROW_NUMBER()` over partition key columns) to drop redundant records.
3. **Data Standardization:**
* Trimming leading and trailing whitespace from text fields.
* Standardizing variations of category names (e.g., merging `'Crypto%'` values into `'Crypto'`).
* Cleaning trailing punctuation from geographic fields (e.g., `'United States.'` to `'United States'`).


4. **Data Type Conversion:** Parsing string dates into standard `DATE` objects (`YYYY-MM-DD`) and updating column types.

---

##  Data Cleaning Process & Code Walkthrough

### **1. Staging Setup**

To maintain data integrity, the raw table `layoffs` is preserved, and work is conducted in a staging table.

```sql
-- Create schema duplicate structure
CREATE TABLE stagging_layoffs LIKE layoffs;

-- Copy raw data into primary staging table
INSERT INTO stagging_layoffs
SELECT * FROM layoffs;

```

---

### **2. Removing Duplicates**

Because MySQL does not support direct `DELETE` operations using CTEs with window functions, a secondary staging table `stagging_layoffs2` with an added `row_num` column was created to filter out duplicates reliably.

> **Note on Implementation Fix:** In SQL, partition column names must not be wrapped in single quotes (e.g., `'date'`), as this evaluates the literal string instead of the column. The fixed CTE partition logic is shown below:

```sql
-- Step A: Define secondary staging table with row_num column
CREATE TABLE `stagging_layoffs2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Step B: Populate staging table with row numbers identifying duplicates
INSERT INTO stagging_layoffs2 
SELECT *,
  ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num 
FROM stagging_layoffs;

-- Step C: Delete duplicated rows (keep only row_num = 1)
DELETE FROM stagging_layoffs2 
WHERE row_num > 1;

```

---

### **3. Data Standardization**

#### **Trimming Whitespace**

Removes extra spaces surrounding company names.

```sql
UPDATE stagging_layoffs2 
SET company = TRIM(company);

```

#### **Standardizing Categorical Values**

Consolidates variations of industry names into unified labels.

```sql
UPDATE stagging_layoffs2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

```

#### **Cleaning Trailing Characters**

Fixes formatting issues in text entries (such as stripping trailing periods in country names).

```sql
UPDATE stagging_layoffs2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';

```

---

### **4. Date Parsing and Type Conversion**

Converts text-formatted date strings into standard SQL `DATE` types (`YYYY-MM-DD`).

```sql
-- Convert string date values to standard DATE format
UPDATE stagging_layoffs2
SET date = STR_TO_DATE(TRIM(date), '%m/%d/%Y');

-- Modify column definition to DATE type
ALTER TABLE stagging_layoffs2
MODIFY COLUMN date DATE;

```

---

##  Tech Stack

* **Database Engine:** MySQL 8.0+
* **SQL Concepts Applied:** Window Functions (`ROW_NUMBER`), CTEs, DDL (`CREATE`, `ALTER`), DML (`INSERT`, `UPDATE`, `DELETE`), String Functions (`TRIM`, `STR_TO_DATE`).
