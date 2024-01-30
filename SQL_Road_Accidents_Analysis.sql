                /*  Road Accidents Dataset SQL Analysis  */

--Need to validate the data in order to create the dashboard from this
USE [Road Accident Project];

--ensure number of records matches that from csv file (i.e. all rows successfully imported)
SELECT *
FROM [Road Accident Project].dbo.Road_Accidents_SQL_Analysis;

--Current Year Casualties (assume current year is '2022'):
SELECT SUM(number_of_casualties) AS Total_Casualties
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022';
--'197.7k' Current Year Casualties

-- Total Casualties for Each Year (2021 and 2022):
SELECT YEAR(accident_date), SUM(number_of_casualties) AS Total_Casualties
FROM Road_Accidents_SQL_Analysis
GROUP BY YEAR(accident_date);

--Total Casualties for Current Year on Different Road Surfaces:
SELECT road_surface_conditions AS Road_Surface, SUM(number_of_casualties) AS Total_Casualties
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
GROUP BY road_surface_conditions
ORDER BY 2 DESC;
--the most casualties are predominantly for 'Dry' road surfaces (131.9k), followed by 'Wet or damp'

--Total Current Year Casualties for Different 'Weather Conditions':
SELECT weather_conditions AS Weather_Conditions, SUM(number_of_casualties) AS Total_Casualties
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
GROUP BY weather_conditions
ORDER BY 2 DESC;


--Current Year 'Accidents':
SELECT COUNT(DISTINCT accident_index)
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022';
--had '144.4k' Accidents in 2022


--Current Year 'Casualties' by Accident Severity:
--    (including 'percent of total' for each too)
SELECT accident_severity, 
       SUM(number_of_casualties) AS casualties,
       --percent of total found using 'SUBQUERY' to obtain OVERALL TOTAL Casualties:
	   (ROUND(CAST(SUM(number_of_casualties) AS float) / 
	          CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis WHERE YEAR(accident_date) = '2022') AS float),4) 
			  *100)  AS 'percent_of_total_casualties'
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
GROUP BY accident_severity
ORDER BY 2 DESC;
--see that most accidents are 'slight' and much fewer are actually 'Fatal'
-- fatal casualties made up '1.71%' of total casualties in 2022


-- Current Year Casualties by 'Vehicle Type'
--Have MANY Categories of Vehicle Type
--best to GROUP THESE into BROAD Categories, using CASE 
WITH CTE AS (
SELECT CASE 
       WHEN vehicle_type IN ('Van / Goods 3.5 tonnes mgw or under', 'Goods 7.5 tonnes mgw and over', 'Goods over 3.5t. and under 7.5t')
	   THEN 'Van'
	   WHEN vehicle_type IN ('Motorcycle over 500cc', 'Motorcycle over 125cc and up to 500cc', 'Motorcycle 50cc and under', 'Motorcycle 125cc and under', 'Pedal cycle')
	   THEN 'Bike'
	   WHEN vehicle_type IN ('Bus or coach (17 or more pass seats)', 'Minibus (8 - 16 passenger seats)')
	   THEN 'Bus'
	   WHEN vehicle_type IN ('Car', 'Taxi/Private hire car')
	   THEN 'Car'
	   WHEN vehicle_type = 'Agricultural vehicle' 
	   THEN 'Agricultural'
	   ELSE 'Other'
	   END AS 'Vehicle_Category',
number_of_casualties
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
)
SELECT Vehicle_Category, 
       SUM(number_of_casualties) AS casualties,
	   (ROUND(CAST(SUM(number_of_casualties) AS float) / 
	          CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis WHERE YEAR(accident_date) = '2022') AS float),4) 
			  *100)  AS 'percent_of_total_casualties'

FROM CTE
GROUP BY Vehicle_Category
ORDER BY 2 DESC;
--see that an overwhelming number of casualties is from 'Cars'. Then 'Vans' and 'Bikes'
--79.6% of casualties are car-related.


--Comparing CURRENT Year with PREVIOUS Year MONTHLY Trends:
SELECT YEAR(accident_date) AS 'Year', 
       MONTH(accident_date) AS 'Month_Number',
	   --(just added month NAME for more clarity)
	   DATENAME(MONTH, accident_date) AS 'Month', 
	   --(dont have to include 'percent of total', but is slightly easier to understand than the whole numbers)
	   SUM(number_of_casualties) AS 'Casualties',
	   (ROUND(CAST(SUM(number_of_casualties) AS float) / 
	          CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis) AS float),4) 
			  *100)  AS 'Percent_of_Total_Casualties'
FROM Road_Accidents_SQL_Analysis
GROUP BY YEAR(accident_date), 
         MONTH(accident_date),
		 DATENAME(MONTH, accident_date)
ORDER BY 1, 2;
--neatly ordered for each year, each month of that year
--allows for easy comparison for CY with PY, month-by-month


-- Current Year Casualties by 'Road Type'
SELECT road_type AS 'Road_Type', 
       SUM(number_of_casualties) AS 'Casualties',
	   (ROUND(CAST(SUM(number_of_casualties) AS float) / 
	          CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis WHERE YEAR(accident_date) = '2022') AS float),4) 
			  *100)  AS 'Percent_of_Total_Casualties'
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
GROUP BY road_type
ORDER BY 2 DESC;
--in 2022, almost 3/4 of total casualties came from 'Single carriageway' 


--Current Year Casualties by Area (Urban or Rural)
SELECT urban_or_rural_area,
       SUM(number_of_casualties) AS 'Casualties',
	   (ROUND(CAST(SUM(number_of_casualties) AS float) / 
	          CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis WHERE YEAR(accident_date) = '2022') AS float),4) 
			  *100)  AS 'Percent_of_Total_Casualties'
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
GROUP BY urban_or_rural_area
ORDER BY 2 DESC;
--roughly 62% of casualties are from 'Urban' Areas, while fewer (38%) are from Rural Areas

--Current Year Casualties by 'Light Condition' (Night or Day)
--SIMPLIFY by GROUPING into just 2 Categories - 'Night' and 'Dark'
WITH CTE AS 
(SELECT CASE 
       WHEN light_conditions IN ('Darkness - lights lit', 'Darkness - no lighting','Darkness - lighting unknown', 'Darkness - lights unlit')
	   THEN 'Night'
	   ELSE 'Day'
	   END AS 'Light_Conditions',
	   number_of_casualties
FROM Road_Accidents_SQL_Analysis
WHERE YEAR(accident_date) = '2022'
)
SELECT Light_Conditions,
SUM(number_of_casualties) AS 'Casualties',
(ROUND(CAST(SUM(number_of_casualties) AS float) / 
 CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis WHERE YEAR(accident_date) = '2022') AS float),4) 
 *100)  AS 'Percent_of_Total_Casualties'
FROM CTE
GROUP BY Light_Conditions
ORDER BY 2 DESC;
--in 2022, almost 3/4 of casualties happen during the Day, with roughly 1/4 of casualties during Night


-- TOP 10 'Locations' with Highest Casualties (for entire dataset - all years total)
--('local_authority' column contains the location data)
SELECT TOP(10) local_authority, 
               SUM(number_of_casualties) AS 'Casualties',
(ROUND(CAST(SUM(number_of_casualties) AS float) / 
 CAST((SELECT SUM(number_of_casualties) FROM Road_Accidents_SQL_Analysis) AS float),4) 
 *100)  AS 'Percent_of_Total_Casualties'
FROM Road_Accidents_SQL_Analysis
--WHERE YEAR(accident_date) = '2022'
GROUP BY local_authority
ORDER BY 2 DESC;
--highest number of casualties are located in Birmingham, Leeds and Bradford
--out of a total of '422' locations, 'Birmingham' casualties make up over 2% of total.


/* Now, can complile these Queries 
   and their respective Results into a text document (Word),
   to create a comprehensive report of this validation process
   (allows for reproducible analysis)
*/

