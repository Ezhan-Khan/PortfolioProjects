				    /*   MySQL Data Cleaning Project   */

-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. Null Values/Blanks
-- 4. Remove Any Columns


-- Note: REPLACING NULLS will DEPEND on DATA
-- IF working with COMPANY Datasets, MUST be CAREFUL!!! What does Stakeholder want?

-- For MySQL, make sure 'Safe Updates' is UNTICKED so UPDATE and DELETE statements can be done (Edit - Preferences - SQL Editor)

-- BEST to CREATE COPY of Dataset to CLEAN (so ORIGINAL NOT AFFECTED!):
USE mysql_data_cleaning;
CREATE TABLE layoffs_copy
LIKE layoffs;

SELECT *
FROM layoffs_copy;
-- Now, INSERT DATA INTO 'layoffs_copy'
INSERT layoffs_copy
SELECT *
FROM layoffs;
-- Now, have a COPY of the ORIGINAL Data to WORK WITH:
SELECT *
FROM layoffs_copy;


                         /*  1. Removing Duplicates:   */
-- using Windows Functions (PARTITION BY), can create ROW NUMBERS for EACH row
-- PARTITION BY all columns which SHOULD have UNIQUE VALUES in EACH ROW:
-- so, IF row_num > 1, means it is a DUPLICATED ROW, so should REMOVE THESE!.
WITH prev_table AS (
SELECT *, ROW_NUMBER() OVER (
          PARTITION BY company, location, industry, 
                       total_laid_off, percentage_laid_off, `date`,
                       stage, country, funds_raised_millions) 
		  AS row_num
FROM layoffs_copy )
SELECT *
FROM prev_table
WHERE row_num > 1;
-- can check each company individually to see IF it IS actually duplicated. 
-- REALISED that need to PARTITION BY ALL columns for this to work properly!

-- in MySQL, CANT just use 'DELETE FROM' statement on CTE (like in Microsoft SQL Server)!
-- for MySQL, can put THIS CTE Table INTO a NEW CREATE TABLE, then 'DELETE FROM' THAT:
CREATE TABLE `layoffs_copy2` (
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
-- INSERT Select Statement from CTE into this table:
INSERT INTO layoffs_copy2
SELECT *, ROW_NUMBER() OVER (
          PARTITION BY company, location, industry, 
                       total_laid_off, percentage_laid_off, `date`,
                       stage, country, funds_raised_millions) 
		  AS row_num
FROM layoffs_copy;     

-- Now, for ALL DUPLICATE ROWS (row_num > 1)and include these in the DELETE FROM statement:
DELETE 
FROM layoffs_copy2
WHERE row_num > 1;

SELECT COUNT(*)
FROM layoffs_copy2;  -- as expected, all 5 duplicate rows have been removed!


                         /*   2. Standardizing Data   */
-- use TRIM to TIDY UP 'company' column (remove unecessary whitespace):
SELECT company, TRIM(company)
FROM layoffs_copy2;
-- Update this:
UPDATE layoffs_copy2
SET company = TRIM(company);

-- for 'Industry' column:
SELECT DISTINCT industry
FROM layoffs_copy2
ORDER BY 1;
-- have some nulls and blanks (will deal with those below)
-- see a few Industry Categories are NOT STANDARDISED (e.g. have Crypto, Crypto Currency... which SHOULD ALL be SAME THING)
SELECT *
FROM layoffs_copy2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_copy2 
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';  -- all now should be 'Crypto'

-- now, looking at location:
SELECT DISTINCT location
FROM layoffs_copy2
ORDER BY 1;
-- for location names with ACCENTS, have wrongly been given (e.g. as 'Ã¼' for 'u' with umlaut), so should change these:
UPDATE layoffs_copy2
SET location = 'Dusseldorf'
WHERE location = 'DÃ¼sseldorf';
UPDATE layoffs_copy2
SET location = 'Florianopolis'
WHERE location = 'FlorianÃ³polis';
UPDATE layoffs_copy2
SET location = 'Malmo'
WHERE location = 'MalmÃ¶';

-- Now, looking at 'country':
SELECT DISTINCT country
FROM layoffs_copy2
ORDER BY 1;
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_copy2
ORDER BY 1;
-- just use to Update 'country' values to REMOVE any TRAILING '.'
UPDATE layoffs_copy2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%United States%';    -- Simple!


-- 'date' Column is currently a TEXT Data Type. SHOULD CHANGE this to 'DATE' :
SELECT DISTINCT `date`
FROM layoffs_copy2;
-- Just use STR_TO_DATE(column, format), specifying the 'DATE FORMAT' we WANT:
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%y') as updated_date
FROM layoffs_copy2;
-- now, using in UPDATE statement:
UPDATE layoffs_copy2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%y');
-- THEN, must CHANGE DATA TYPE in table to 'Date' (because is STILL TEXT, but IN a DATE FORMAT!)
ALTER TABLE layoffs_copy2
MODIFY COLUMN `date` DATE;   


                         /*   3. Working with NULL or BLANK Values   */

-- Depending on Data, can either REPOPULATE (FILL IN) OR REMOVE those rows.
-- BEST to FILL IN Blank/NULL Data so Ouptut is PROPERLY REPRESENTED!  
SELECT * 
FROM layoffs_copy2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;  -- If BOTH these Columns have NULL values, is NOT USEFUL (so should REMOVE these Rows!)

SELECT *
FROM layoffs_copy2
WHERE industry IS NULL 
OR industry = '';
-- for those rows MISSING 'industry', SHOULD be able to FILL IN, by looking at OTHER ROWS for the SAME COMPANY which DO have that 'industry' given
-- e.g. for 'Airbnb' is in 'Travel' industry, so can FILL IN where 'industry' is BLANK in this row:

-- Can use SELF-JOIN to FILL IN Blanks/NULLS:
SELECT lc1.industry, lc2.industry
FROM layoffs_copy2 lc1
JOIN layoffs_copy2 lc2
ON lc1.company = lc2.company    -- JOIN where Company AND location are SAME
AND lc1.location = lc2.location  
WHERE lc1.industry IS NULL    -- and WHERE 'industry' is GIVEN in ONE TABLE, NOT GIVEN in OTHER!
AND lc2.industry IS NOT NULL;
-- now, PUT this JOIN statemnet INTO an UPDATE STATEMENT:
UPDATE layoffs_copy2 lc1
JOIN layoffs_copy2 lc2
ON lc1.company = lc2.company
SET lc1.industry = lc2.industry
WHERE (lc1.industry IS NULL OR lc1.industry = '')
AND lc2.industry IS NOT NULL;

-- With current data given here, CANNOT POPULATE 'total_laid_off', 'percentage_laid_off' or 'funds_raised_millions'.
-- (If we were given the 'ORIGINAL Total' as a column, could do CALCULATIONS to FILL IN Blanks/Nulls there.


                         /*   4. REMOVE any UNECESSARY COLUMNS or ROWS from Columns*/

-- Note: MUST be CONFIDENT in DECISIONS when REMOVING Data from a table!
-- here, could REMOVE ROWS where 'total_laid_off' and 'percentage_laid_off' are BOTH NOT GIVEN (since wont be useful to analysis!)
DELETE 
FROM layoffs_copy2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Can also DROP 'row_num' COLUMN (since not needed here). 
ALTER TABLE layoffs_copy2
DROP COLUMN row_num;

SELECT *
FROM layoffs_copy2





