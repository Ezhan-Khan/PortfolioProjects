				    /*   MySQL Data Cleaning and EDA Project   */
                    
					    /*  SECTION 1 - MySQL Data Cleaning  */

-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. Null Values/Blanks
-- 4. Remove Any Columns


-- Note: REPLACING NULLS will DEPEND on DATA
-- IF working with COMPANY Datasets, MUST be CAREFUL!!! What does Stakeholder want?

-- For MySQL, make sure 'Safe Updates' is UNTICKED so UPDATE and DELETE statements can be done (Edit - Preferences - SQL Editor)

-- BEST to CREATE COPY of Dataset to CLEAN (so ORIGINAL NOT AFFECTED!):

DROP DATABASE IF EXISTS mysql_data_cleaning;
CREATE DATABASE mysql_data_cleaning;
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
SELECT COUNT(*)
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

SELECT COUNT(*)
FROM layoffs_copy2;  -- checked that all 2361 rows successfully inserted

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
SELECT `date`, STR_TO_DATE(`date`, '%Y-%m-%d') as updated_date
FROM layoffs_copy2;
-- now, using in UPDATE statement:
UPDATE layoffs_copy2
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');
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
-- now, PUT this JOIN statement INTO an UPDATE STATEMENT:
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
FROM layoffs_copy2;    


-- Now have a much CLEANER Dataset which we can NOW USE for ANALYSIS!


					      /*  SECTION 2 - MySQL Exploratory Data Analysis  */

SELECT *
FROM layoffs_copy2;

-- Purpose of EDA is to explore and discover any interesting trends or insights in data.

-- 'percentage' laid_off is NOT very useful for THIS dataset, since we are NOT TOLD the Total Employees in the Company.
SELECT company, MAX(total_laid_off) AS Max_Laid_Off, MAX(percentage_laid_off) AS Max_Percent_Laid_off
FROM layoffs_copy2
GROUP BY company
ORDER BY 2 DESC;
-- see that on a particular date, Google laid off 12,000 people. 

-- FILTERING to view for this MAX Percentage Laid Off (=1 - i.e. ALL employees laid off in a Company!):
SELECT *
FROM layoffs_copy2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
-- see that 'Katerra' laid off the most total employees (i.e. went under) on one date, laying off all 2434 employees.

-- Which of these Companies had the most 'funds_raised_millions'?
SELECT *
FROM layoffs_copy2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- A company called 'Britishvolt' raised 2400 million in 2023 (recent!)

-- What is total number laid off for each company?
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY company
ORDER BY 2 DESC;
-- in total, Amazon has laid off the MOST overall customers (18,150), Google laid off 12,000...

-- What Date Range does this dataset cover?
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_copy2
WHERE `date` != '';    -- from 2020-01-04 TO 2023-12-02

-- What Industry has most layoffs?
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY industry
ORDER BY 2 DESC;
-- 'Consumer' and 'Retail' both have had a lot of total layoffs, each above 40,000.
-- low layoffs for Manufacturing and Fin-Tech 

-- What 'Country' has the most layoffs?
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY country
ORDER BY 2 DESC;
-- US has by far the most layoffs, at 256,559. Followed by India at almost 36,000

-- Layoffs over Time (by Year).
SELECT CAST(RIGHT(`date`, 4) AS float) AS 'Year',    
        SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY 1
ORDER BY total_laid_off DESC;
-- 2022 had the most layoffs.

-- Layoffs depending on 'Stage' of the Company?
SELECT  stage,   
        SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY 1
ORDER BY total_laid_off DESC;
-- most layoffs comes from 'Post-IPO'


SELECT `date` FROM layoffs_copy2;  -- (checking the 'dates')

--                   'Running ('Rollng') Total' Layoffs by 'MONTH'?
-- (need to EXTRACT the 'Month' from 'date' using SUBSTRING)
SELECT 
#IF date given as 'dd/mm/yyy' format, then use this:
#SUBSTRING(`date`, LOCATE('/', `date`) +1,  LOCATE('/', `date`, 2)-1)  AS 'Month',
#IF date like 'yyyy-mm-dd' then use this:
SUBSTRING(`date`, LOCATE('-', `date`) +1,  LOCATE('-', `date`)-3)  AS 'Month',
		SUM(total_laid_off)
FROM layoffs_copy2
WHERE  SUBSTRING(`date`, LOCATE('-', `date`) +1,  LOCATE('-', `date`)-3)  
		!= ''
GROUP BY 1
ORDER BY 1;

-- but, this is just 'Month' for EVERY YEAR TOGETHER
-- Better to group by 'Month AND YEAR' Together only (must Change to 'YYYY-MM' Format TOO! - otherwise WONT ORDER PROPERLY!):

#IF date given as 'dd/mm/yyy' format, then use this:
#CONCAT(SUBSTRING(`date`, LOCATE('/', `date`, 4) +1, LENGTH(`date`)), 
#                     '-',
#		SUBSTRING(`date`, LOCATE('/', `date`) +1,  LOCATE('/', `date`, 3) -1)
#			  )
#					 AS 'Month',       -- used 'CONCAT' to ADD 'Year' string WITH 'Month' String (so is YYYY-MMM format)
#IF date like 'yyyy-mm-dd' then use this:
SELECT SUBSTRING(`date`, 1,  7)  AS 'Month',
		SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
WHERE SUBSTRING(`date`, 1,  7) != ''
GROUP BY 1
ORDER BY 1;

-- RUNNING TOTAL? Put above into CTE, then use WINDOW FUNCTION to CUMMULATIVELY ADD UP total_layoffs
WITH running_total AS (
SELECT SUBSTRING(`date`, 1,  7)  AS 'Month',
		SUM(total_laid_off) AS total_layoffs
FROM layoffs_copy2
WHERE SUBSTRING(`date`, 1,  7) != ''
GROUP BY 1
ORDER BY 1
)
SELECT `Month`, total_layoffs, SUM(total_layoffs) OVER (ORDER BY `Month`) AS Running_Total
FROM running_total
ORDER BY 3;

-- How much does EACH Company lay off in a YEAR?
SELECT company, LEFT(`date`,4) AS 'Year' , SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
GROUP BY company, LEFT(`date`,4);
-- now, will use this to RANK total laid-off for EACH COMPANY (use PARTITION BY)
-- here, requires 2 CTE Chains to do this (simple):
WITH Company_Year AS (
SELECT company, LEFT(`date`,4) AS 'Years' , SUM(total_laid_off) AS total_laid_off
FROM layoffs_copy2
WHERE LEFT(`date`,4) != ''
GROUP BY company, LEFT(`date`,4)
), Company_Year_Rank AS        -- this is 2nd CTE chain! Needed so we can use 'Ranking' Column BY NAME!
(SELECT *, DENSE_RANK() OVER (PARTITION BY `Years` ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
-- this is a great YEAR-BY-YEAR SNAPSHOT of Total Layoffs for Companies. 
-- Added a RANKING too, so can see which Company had most layoffs in each year. 

-- Seeing how many countries each company is found in?
SELECT company, COUNT(DISTINCT country) 
FROM layoffs_copy2
GROUP BY 1 
ORDER BY 2 DESC;






























