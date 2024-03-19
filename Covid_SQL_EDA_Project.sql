
/* Used a Dataset which starts from January 2020 up to June 2021 
- this covers a suitable range of data which should lend itself to interesting insights
- analyse the substantial rise in covid cases from its emergence, till mid-2021)
*/

/*Start by ensuring all rows have successfully been imported for each table:*/
USE [SQL Exploratory Data Analysis Project];
SELECT COUNT(*) AS 'Count'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021;

SELECT COUNT(*) AS 'Count'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021;
--(Both have 137,317 rows, as expected)

--checking the Number of Blank (NULL) Entries for 'total_deaths' MATCHES that in the original excel data:
SELECT COUNT(*)
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE total_deaths IS NULL;  --(41995 as expected)

--Ordering by Location and Date (for each table):
SELECT *
FROM [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021
ORDER BY 3, 4;

SELECT *
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
ORDER BY 3, 4;


                                    /* COVID DEATHS Data */
--Select Important, Relevant Data to be used for Analysis (only important columns)
--Order by 'Location' and 'Date'
SELECT Location, date AS 'Date', total_cases AS 'Total Cases', new_cases AS 'New Cases', total_deaths AS 'Total Deaths', population AS 'Population'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE continent IS NOT NULL
Order By 1,2;   

--Compare 'Total Cases' to 'Total Deaths'
--(how many Cases are in given Countries and how many Deaths are there OUT of the Cases)
-- i.e. Likelihood of Dying if you contract COVID in your Country
SELECT Location, date, total_cases, total_deaths,
     ROUND(CAST(total_deaths AS float)/CAST(total_cases AS float)*100, 3) AS 'Percentage of Deaths'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE continent IS NOT NULL
Order By 1,2;  
--e.g. in Afghanistan, 30th June 2021 (most recent), had 4.105 % deaths. 
--See a gradual rise in % deaths, starting at 2.5% in March 2020.

--Narrow Down for JUST 'United States' Death Rates:
SELECT Location, date, total_cases, total_deaths,
     ROUND(CAST(total_deaths AS float)/CAST(total_cases AS float)*100, 3) AS 'Percentage of Deaths'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE location = 'United States'
AND continent IS NOT NULL
Order By 1,2;       --for US, starts at HIGHER % Deaths around March (e.g. 5.9% on 5th March 2020)
--At end of 2020, had nearly 20 million total_cases, with nearly 350,000 total_deaths. 
--30th June 2021 (most recent) had dropped below 2% deaths. Yet Total Cases came to over 33 million total_cases and over 600,000 deaths.

--Looking at 'Total Cases vs Population'
-- (Percentage of Population who got Covid)
SELECT Location, date, total_cases, population, 
     (CAST(total_cases AS float)/CAST(population AS float)*100)  AS 'Percentage_Cases'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE location = 'United States'
AND continent IS NOT NULL
Order By 1,2;       
--On 14th July 2020, reached 1% of total population who got Covid.
--Almost a Year later, 30th June 2021, reached 9.845% of Population who got Covid (almost 10%).
--(this definitely will be useful to visualize)


-- Countries with Overall Highest (MAX) Infection Rate compared to Population:
SELECT Location, population, 
        MAX(total_cases) AS 'Highest_Infection_Count', 
	   MAX((CAST(total_cases AS float)/CAST(population AS float)*100))  AS 'Percentage_Population_Infected'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY Percentage_Population_Infected DESC; 
--Country with Highest Infection Percentage (of population) is Bahrain, at 18.04% (total percentage infected). 
--Other Countries with High Infection Percentages are Andorra (17.4%), United States (9.845%), Brazil, Portugal...


-- Countries with Highest Death Count per Population:
SELECT Location, MAX(total_deaths) AS Total_Death_Count
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
--WHERE location = 'United States'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Death_Count DESC; 
--Issue with Data: Given Locations for CONTINENTS and other Groupings, INSTEAD of just Countries! (e.g. World, High income, Europe, South America, Africa...)
--notice that for these locations groupings, are given 'NULL' for Continent Column
--So? Can FILTER so view only 'WHERE continent IS NOT NULL'. This helps to Clean Up the Data a little!
--(added to the Statements above too)

--United States has Highest Total Death Count, at over 600,000 Deaths Total. Followed Closely by Brazil and India.
--UK Total Deaths is at 154,483.


-- Now, let's break down the data by 'CONTINENT':
--this is where 'continent' column values are NULL (i.e. Continent info given in 'location' instead):
SELECT location, MAX(total_deaths) AS Total_Death_Count
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
--WHERE location = 'United States'
WHERE continent IS NULL AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income', 'European Union')
GROUP BY location
ORDER BY Total_Death_Count DESC; 
--these are more accurate numbers than using 'continent' column (because NULLS are INCLUDED!)
--(used NOT IN to remove unecessary 'location' fields from this analysis)
--worldwide, between 2020 to mid-2021, had close to 4 million total deaths (3.99 million)
--over 1.1 million in Europe, over 1 million in South America, over 900,000 in North America, close to 800,000 in Asia and over 140,000 in Africa.
-- Continent with Lowest Total Deaths was Oceania, at 1440 deaths.

--Breaking down by 'continent' column, get slightly different results (since do NOT include NULLS here)
SELECT continent, MAX(total_deaths) AS Total_Death_Count
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
--WHERE location = 'United States'
WHERE continent IS Not NULL 
GROUP BY continent
ORDER BY Total_Death_Count DESC; 

--(DRILL DOWN: Clicking on 'North America' will show all Countries WITHIN North American Continent (Canada, US...))


--                                 'GLOBAL NUMBERS' (not aggregated by location or continent):
-- total 'new_cases' and 'new_deaths' by date:
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
             CAST(SUM(new_deaths) AS float)/CAST(SUM(new_cases) AS float)*100 AS percentage_deaths
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE continent IS NOT NULL AND new_cases != 0
GROUP BY date
Order By 1,2;     --this gives the DAILY total_cases and total_deaths GLOBALLY, as well as the % of which are deaths

--OVERALL Death Percentage (2020 to Mid-2021):
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
             CAST(SUM(new_deaths) AS float)/CAST(SUM(new_cases) AS float)*100 AS percentage_deaths
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021
WHERE continent IS NOT NULL AND new_cases != 0
Order By 1,2;     
--globally, over 181 million total cases, with 3.96 million deaths. This is a global death percentage of 2.18 %



                     /*  Querying COVID VACCINATIONS Data  */

--now will JOIN 'CovidDeaths' table with 'CovidVaccinations' (on 'location' and 'date' columns:
--Look at Total Population vs Vaccinations (total people who have been vaccinated globally?)
SELECT cd.continent, cd.location, cd.date, population, cv.new_vaccinations
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021 AS cd
JOIN [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021 cv
 ON cd.location = cv.location
AND cd.date = cv.date         --output has 137,317 rows, so both tables have successfully joined
WHERE cd.continent IS NOT NULL
ORDER BY location, date, continent;
--can see the dates when a country started vaccinations. e.g. Canada started vacccinations on 15th December 2020, at around 721.
--(note: used 'new_vaccinations', which is PER DAY)

-- Create a 'RUNNING COUNT' (cummulatively summing new_vaccinations day by day to result in a TOTAL)
--(through use of WINDOWS FUNCTION with PARTITION BY)
SELECT cd.continent, cd.location, cd.date, population, 
       cv.new_vaccinations,
       SUM(cv.new_vaccinations) OVER 
	   (PARTITION BY cd.location    --broken down by location (so restarts count country by country)
        ORDER BY cd.location, cd.date) AS 'running_vaccinations'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021 AS cd
JOIN [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021 cv
 ON cd.location = cv.location
AND cd.date = cv.date         
WHERE cd.continent IS NOT NULL AND cv.new_vaccinations IS NOT NULL  --remove NULLS, so can clearly see WHEN Vaccinations STARTED for each location
ORDER BY cd.location, cd.date, cd.continent;

--But HOW can we find the Percentage of People Vaccinated as PERCENTAGE of TOTAL POPULATION?
--Need to create either CTE or TEMP TABLE in order for this Calculation to work (since need to use the WINDOWS FUNCTION Column created above)
--Method 1: CTE
WITH Vaccinated_Populations AS 
(
SELECT cd.continent AS Continent, cd.location AS Location, cd.date AS Date, population AS Population, 
       cv.new_vaccinations AS New_Vaccinations,
       SUM(cv.new_vaccinations) OVER 
	   (PARTITION BY cd.location    
        ORDER BY cd.location, cd.date) AS 'Running_Vaccinations'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021 AS cd
JOIN [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021 cv
 ON cd.location = cv.location
AND cd.date = cv.date         
WHERE cd.continent IS NOT NULL AND cv.new_vaccinations IS NOT NULL  
--ORDER BY cd.location, cd.date, continent
)
SELECT *, ROUND((CAST(running_vaccinations AS float)/CAST(Population AS float))*100,4) AS Percentage_Vaccinated
FROM Vaccinated_Populations
--WHERE Location = 'United States';   --(can use previous query for FURTHER Calculations, as shown!)
--e.g. find that most recent percentage vaccinated in Argentina is 47.99% (30th June 2021)

--Method 2: TEMP TABLE
DROP TABLE IF EXISTS #vaccinated_populations
CREATE TABLE #vaccinated_populations (
Continent nvarchar(50),
Location nvarchar(50),
Date DATE,
Population int,
New_Vaccinations int,
Running_Vaccinations float
)
INSERT INTO #vaccinated_populations
SELECT cd.continent AS Continent, cd.location AS Location, cd.date AS Date, population AS Population, 
       cv.new_vaccinations AS New_Vaccinations,
       SUM(cv.new_vaccinations) OVER 
	   (PARTITION BY cd.location    
        ORDER BY cd.location, cd.date) AS 'Running_Vaccinations'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021 AS cd
JOIN [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021 cv
 ON cd.location = cv.location
AND cd.date = cv.date         
WHERE cd.continent IS NOT NULL AND cv.new_vaccinations IS NOT NULL  
ORDER BY cd.location, cd.date, continent;

SELECT *, ROUND((CAST(running_vaccinations AS float)/CAST(Population AS float))*100,4) AS Percentage_Vaccinated
FROM #vaccinated_populations;    --same results! Just another method to perform this calculation.


                   /* Create VIEWS to store important Analyses */
-- ONLY the Definition of the View is Stored (usually used when storing private/sensitive data which should be protected). 
-- This will be useful later, when creating visualizations from this data. (NOTE - View are NOT allowed for Temp Tables)

--Create View for CTE above (Vaccinated_Populations):
CREATE VIEW PercentPopulationVaccinated AS
WITH Vaccinated_Populations AS 
(
SELECT cd.continent AS Continent, cd.location AS Location, cd.date AS Date, population AS Population, 
       cv.new_vaccinations AS New_Vaccinations,
       SUM(cv.new_vaccinations) OVER 
	   (PARTITION BY cd.location    
        ORDER BY cd.location, cd.date) AS 'Running_Vaccinations'
FROM [SQL Exploratory Data Analysis Project].dbo.CovidDeaths_2020_to_2021 AS cd
JOIN [SQL Exploratory Data Analysis Project].dbo.CovidVaccinations_2020_to_2021 cv
 ON cd.location = cv.location
AND cd.date = cv.date         
WHERE cd.continent IS NOT NULL AND cv.new_vaccinations IS NOT NULL  
--ORDER BY cd.location, cd.date, continent
)
SELECT *, ROUND((CAST(running_vaccinations AS float)/CAST(Population AS float))*100,4) AS Percentage_Vaccinated
FROM Vaccinated_Populations;

--simple access the view (just like a table);
SELECT *
FROM PercentPopulationVaccinated;

--Can Connect SQL Views to TABLEAU for Creating Visualizations.
























