USE HR_Analysis_Project;

--imported in flat file (CSV) 'Human_Resources_Data.csv'
--Inspecting Data 
SELECT *
FROM HR_Data;
--Ensuring all rows have been imported successfully:
SELECT COUNT(*)
FROM HR_Data;

                         /*  Data Cleaning  */

-- 'id' (primary key) is not specific. Renamed to 'emp_id' using Object Explorer

--Checking Data Types
SELECT birthdate 
FROM HR_Data;

--Already changed LOCALE of date fields so they are consistent (using Power Query)
--To achieve this in SQL, can write:
/*
SET sql_safe_updates = 0    --(i.e. allows you to update data - once cleaning is done, convert BACK to 1)
UPDATE HR_Data
SET birthdate = CASE 
                WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
				WHEN birthdate LIKE '%-%' THEN THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
                ELSE NULL
END; 
*/
--noticed that '/' separator is used for values not converted to dates, whereas '-' was used to separate for dates
--so using CASE statement, find where string contains '/', THEN CONVERTS TO 'date' format
--do same for '-'. ELSE set to 'NULL'
--MODIFY 'Data Type' of TABLE itself (permenantly) using 'UPDATE' with 'SET' and 'CAST()' function. OR use Object Explorer - right-click table - Modify
--Above query can be repeated for 'hiredate' too. 


SELECT termdate 
FROM HR_Data;
--Viewing 'termdate' column. Has been stored as DATE with a TIMESTAMP value
--can REMOVE the TIMESTAMP component, since is not needed here

SELECT termdate, SUBSTRING(termdate, 1, 10) AS 'termdate_DATE'
FROM HR_Data
--using 'SUBSTRING' extracted just the first 10 characters (YYYY-MM-DD part) of termdate values
ALTER TABLE HR_Data
ADD termdate_date nvarchar(50);
UPDATE HR_Data
SET termdate_date = SUBSTRING(termdate, 1, 10); 
--Also, must change to DATE data type:
UPDATE HR_Data
SET termdate_date = CAST(termdate_date AS date);


--Using 'birthdate', will CALCULATE values for 'age' Column (easier to work with):
--first ADD the NEW COLUMN 'age' (integer data type)
ALTER TABLE HR_Data 
ADD age INT;
--Calculate age by DIFFERENCE between 'birthdate' and CURRENT Date
SELECT birthdate, DATEDIFF(year, birthdate, getdate()) AS 'age'
FROM HR_Data;
--good, but this is just differnce between 'Year' component of the DATE. 
--So? Could do for 'day' component, then DIVIDE by '365' (days in a year)
SELECT birthdate, DATEDIFF(day, birthdate, getdate()) / 365 AS 'age'
FROM HR_Data
--Now just SET 'age' column values to this calculation:
UPDATE HR_Data
SET age = DATEDIFF(day, birthdate, getdate()) / 365; 

SELECT birthdate, age
FROM HR_Data;

--Now, need to ensure all ages are correct (positive values):
SELECT MIN(age) AS 'youngest', MAX(age) AS 'oldest'
FROM HR_Data;   --youngest employee age is 21, oldest is 59



                           /*  ANALYSIS  */

--Gender Breakdown of employees in the company:
SELECT gender, COUNT(*) AS 'employee_count'
FROM HR_Data
WHERE termdate IS NULL
GROUP BY gender
ORDER BY employee_count DESC;
--note: only want those employees who are STILL employeed (therefore 'termdate' is NULL)
--see that majority of employees in this dataset are 'Male', followed by 'Female' then 'Non-Conforming' as lowest


--Race/Ethnicity Breakdown of employees in the company:
SELECT race, COUNT(*) AS 'employee_count'
FROM HR_Data
WHERE termdate IS NULL
GROUP BY race
ORDER BY employee_count DESC;
--see that majority of employees are 'White', followed by employees with 'Two or More' Races, Black/African American and Asian being prominent races.


--Age Distribution of employees in the company:
SELECT min(age) AS youngest, 
       max(age) AS oldest,
	   avg(age) AS average_age
FROM HR_Data
WHERE termdate IS NULL;
--finding 'age group' with highest number of employees:
WITH HR AS(
SELECT *, CASE
          WHEN age BETWEEN 18 AND 24 THEN '18-24'
		  WHEN age BETWEEN 25 AND 34 THEN '25-34'
		  WHEN age BETWEEN 35 AND 44 THEN '35-44'
		  WHEN age BETWEEN 45 AND 54 THEN '45-54'
		  WHEN age BETWEEN 55 AND 64 THEN '55-65'
		  ELSE '65+'
	   END AS 'age_group'
FROM HR_Data
)
SELECT age_group, COUNT(*) AS 'employee_count'
FROM HR
WHERE termdate IS NULL
GROUP BY age_group
ORDER BY age_group;
--for CASE statement field, need to use CTE in order to GROUP BY that field (BY NAME). 

--Similarly, can find age_group distribution by 'gender':
WITH HR AS(
SELECT *, CASE
          WHEN age BETWEEN 18 AND 24 THEN '18-24'
		  WHEN age BETWEEN 25 AND 34 THEN '25-34'
		  WHEN age BETWEEN 35 AND 44 THEN '35-44'
		  WHEN age BETWEEN 45 AND 54 THEN '45-54'
		  WHEN age BETWEEN 55 AND 64 THEN '55-65'
		  ELSE '65+'
	   END AS 'age_group'
FROM HR_Data
)
SELECT age_group, gender, COUNT(*) AS 'employee_count', AVG(age) AS average_age
FROM HR
WHERE termdate IS NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;
--gives breakdown of employees for each gender within each age_group


--Number of employees working at headquarters vs at remote locations:
SELECT DISTINCT location
FROM HR_Data;   --viewing, have either 'Headquarters' OR 'Remote'
--aggregating by location:
SELECT location, COUNT(*) AS employee_count
FROM HR_Data
WHERE termdate IS NULL
GROUP BY location
ORDER BY employee_count DESC;
--see that majority of employees (13,510) work at the 'Headquarters'. Only 4575 work remotely  


--Average Length of employment for employees who have left the company (i.e. termdate value given)
--viewing all employment years for former employees:
SELECT hire_date, 
       termdate_date,
	   ROUND(CAST(DATEDIFF(day, hire_date, termdate_date)/365 AS float), 2) AS 'employment_years'
FROM HR_Data
WHERE termdate_date IS NOT NULL AND termdate_date < getdate()   --only interested in former employees as of now, so their termination date must be before the current date.
ORDER BY termdate_date;
--Now, finding the AVERAGE Length of employment
SELECT ROUND(AVG(DATEDIFF(day, hire_date, termdate_date)/365), 2) AS 'employment_years'
FROM HR_Data
WHERE termdate_date IS NOT NULL AND termdate_date < getdate()   --only interested in former employees as of now, so their termination date must be before the current date.
--Average employment duration is 7 years.


--Gender Distribution acrosss Departments and Job Titles?
--first, viewing possible jobtitles in the company:
SELECT DISTINCT jobtitle AS Job_Titles
FROM HR_Data
ORDER BY Job_Titles;
--viewing possible departments:
SELECT DISTINCT department
FROM HR_Data;

--Gender Distribution across Departments:
SELECT department, gender, COUNT(*) AS count
FROM HR_Data
WHERE termdate_date IS NULL
GROUP BY department, gender
ORDER BY department, gender;
--Gender Distribution across Job Titles:
SELECT jobtitle, gender, COUNT(*) AS count
FROM HR_Data
WHERE termdate_date IS NULL
GROUP BY jobtitle, gender
ORDER BY jobtitle, gender;


--Distribution of Job Titles across company:
SELECT jobtitle, COUNT(*) as count
FROM HR_Data
WHERE termdate_date IS NULL
GROUP BY jobtitle
ORDER BY jobtitle;


--Department with Highest TURNOVER RATE (=rate at which employees leave the company):
--  = total employees who left during a given time period / total employees in the department IN that Time Period
WITH calculations AS (
SELECT department, 
       COUNT(*) AS total_count, 
	   SUM(CASE WHEN termdate_date IS NOT NULL AND termdate_date <= getdate()
	            THEN 1
	       ELSE 0 END) AS terminated_count
FROM HR_Data
GROUP BY department )
SELECT department, terminated_count, total_count, ROUND(CAST(terminated_count AS float)/CAST(total_count AS float) *100,2) AS turnover_rate
FROM calculations
ORDER BY turnover_rate DESC;
--note: same result could be achieved with a Subquery too

--Distribution of Employees across Locations by City and State:
SELECT location_state, location_city, COUNT(*) AS count
FROM HR_Data
WHERE termdate_date IS NULL
GROUP BY location_state, location_city
ORDER BY location_state, location_city;


--Change in employee count over time based on hire and term dates:
--i.e. for each year, want to see HOW MANY employees were HIRED, how many were TERMINATED and PERCENTAGE CHANGE over time
WITH calculation AS (
SELECT YEAR(hire_date) AS year,
	         COUNT(*) AS hires,
			  SUM(CASE WHEN termdate_date IS NOT NULL AND termdate_date <= getdate()
	                   THEN 1
	                   ELSE 0 END) AS terminations
	  FROM HR_Data
	  GROUP BY YEAR(hire_date) 
)
SELECT year, 
       hires, 
       terminations, 
       hires - terminations AS net_change,
       ROUND((hires-terminations)/CAST(hires AS float)*100,2) AS net_percentage_change
FROM calculation
ORDER BY year ASC;
     

--(Average) Tenure Distribution for Each Department:
--i.e. how long (in years) does each employee stay in each department, before leaving company.
SELECT department, 
       ROUND(AVG(datediff(day, hire_date, termdate_date)/365),0) AS average_tenure
FROM HR_Data
WHERE termdate_date IS NOT NULL AND termdate_date <= getdate()
GROUP BY department
ORDER BY department;

--Each Analysis Query Output has been copied into an Excel Worksheet (to store the outputs).


--Once Analysis is complete, can load this data into an Excel File
--Just establish a Connection in Excel with Microsoft SQL Server



