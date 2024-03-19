

#%%                      DATABASES IN PYTHON - IBM PROJECT ASSINGMENT 

#                         INTRODUTION to 'Business Task':
#Have 'REAL-WORLD' Dataset, from 'Chicago Data Portal'
#Aim of Organization - Improve Education Outcomes for Children and Youth in Chicago
#This will be achieved by QUERYING the Datasets provided to gather IMPORTANT INSIGHTS
#Then can SHARE QUERIES and RESULTS (peer-assessed)

#VIEW/INSPECT the DATASETS:
# = 3 DATASETS from Chicago Data Portal
#- 'Chicago Socioeconomic Indicators' (includes 6 socioeconomic indicators of public health and 'hardship index'. From 2008-2012)
#- 'Chicago Public Schools' (All School LEVEL PERFORMANCE Data, used to create CPS School REPORT CARDS for '2011-2012')
#- 'Chicago Crime Data' - REPORTED INCIDENTS of CRIME (except murder where data exists for each victim) in Chicago, from 2001-present (minus 7 MOST RECENT Days)

#Note - 'Crime Data' ORIGINAL Dataset is over 6.5 million rows. For this assignment will SIMPLY use a SUBSET of this large dataset
#More Info on TABLE SCHEMA found at 'https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2?utm_medium=Exinfluencer&utm_source=Exinfluencer&utm_content=000026UJ&utm_term=10006555&utm_id=NA-SkillsNetwork-Channel-SkillsNetworkCoursesIBMDeveloperSkillsNetworkDB0201ENSkillsNetwork20127838-2021-01-01&cm_mmc=Email_Newsletter-_-Developer_Ed%2BTech-_-WW_WW-_-SkillsNetwork-Courses-IBMDeveloperSkillsNetwork-DB0201EN-SkillsNetwork-20127838&cm_mmca1=000026UJ&cm_mmca2=10006555&cm_mmca3=M12345678&cvosrc=email.Newsletter.M12345678&cvo_campaign=000026UJ'

#%%                       Establish CONNECTION with the SQLite Database 
import sqlite3
con = sqlite3.connect("FinalDB.db")    #(creates this Database within the Current Working Directory)
cur = con.cursor()

#                             'LOAD Datsets' INTO the 'DATABASE' 
#-First, as PANDAS DATAFRAME:
import pandas as pd
census_df = pd.read_csv('ChicagoCensusData.csv') 
publicschools_df = pd.read_csv('ChicagoPublicSchools.csv')
crime_df = pd.read_csv('ChicagoCrimeData.csv')

#-LOAD these DataFrames AS SQL TABLES INTO 'FinalDB.db':
census_df.to_sql("CENSUS_DATA", con, if_exists='replace', index=False,method="multi")
publicschools_df.to_sql("CHICAGO_PUBLIC_SCHOOLS", con, if_exists='replace', index=False,method="multi")
crime_df.to_sql("CHICAGO_CRIME_DATA", con, if_exists='replace', index=False,method="multi")



#                    'Obtaining METADATA' (QUERYING the Database System Catalog)
#In 'SQLite3', METADATA is GIVEN in TABLE 'sqlite_master'
cur.execute('''SELECT name
               FROM sqlite_master 
               WHERE type = "table"
            ''')
metadata_name = cur.fetchall()
metadata_name  #Shows that the 3 Tables 'CENSUS_DATA', 'CHICAGO_PUBLIC_SCHOOLS' and 'CHICAGO_CRIME_DATA' have ALL been ADDED to the Connected Database!

#QUERYING for 'Number of COLUMNS' in 'CENSUS_DATA' Table:
cur.execute('''SELECT count(name)
               FROM PRAGMA_TABLE_INFO('CENSUS_DATA')
               
            ''')
column_count = cur.fetchall()
column_count         #'CENSUS_DATA' has '9 Columns'

#Retrieving All 'COLUMN NAMES', 'DATA TYPES' and 'LENGTH' (for CENSUS_DATA):
cur.execute('''SELECT name, type, Length(type)
               FROM PRAGMA_TABLE_INFO('CENSUS_DATA')               
            ''')
column_data = cur.fetchall()
column_data   #have obtained 'CENSUS_DATA' Table Metadata for EACH COLUMN

#SAVING this Metadata INTO a DATAFRAME:
metadata_df = pd.read_sql_query('''SELECT name, type, Length(type)
               FROM PRAGMA_TABLE_INFO('CENSUS_DATA')               
            ''', con)



#%%                 'WRITE and EXECUTE' QUERIES (SQL ANALYSIS within a Python IDE)

#  Q1 - 'Total Number of Crimes RECORDED in CRIME Table?'
cur.execute("""SELECT COUNT(DISTINCT ID)
               FROM CHICAGO_CRIME_DATA;
            """)
total_crimes= cur.fetchall()
total_crimes      # 533 Crimes Recorded in 'CHICAGO_CRIME_DATA' Table

#  Q2 - 'Community Areas with Per Capita Income BELOW 11,000?'
cur.execute("""SELECT COMMUNITY_AREA_NAME, PER_CAPITA_INCOME
               FROM CENSUS_DATA
               WHERE PER_CAPITA_INCOME < 11000
               ORDER BY 2 DESC;
            """)
per_capita_below_11k = cur.fetchall()
per_capita_below_11k

#  Q3 - 'All Case Numbers for CRIMES involving MINORS?'
cur.execute("""SELECT CASE_NUMBER, PRIMARY_TYPE, DESCRIPTION
               FROM CHICAGO_CRIME_DATA
               WHERE PRIMARY_TYPE LIKE '%MINOR%' OR DESCRIPTION LIKE '%MINOR%';
            """)
crimes_minors= cur.fetchall()
crimes_minors

#  Q4 - 'g All Kidnapping Crimes involving a CHILD?' (Note: Children are NOT considered 'MINORS' for purpose of crime analysis)
cur.execute("""SELECT PRIMARY_TYPE, DESCRIPTION
               FROM CHICAGO_CRIME_DATA
               WHERE PRIMARY_TYPE LIKE '%kidnap%' OR DESCRIPTION LIKE '%ABDUCTION%';
            """)
kidnapping_child = cur.fetchall()
kidnapping_child    #'KIDNAPPING', 'CHILD ABDUCTION/STRANGER'

#  Q5 - 'KINDS of Crimes recorded AT SCHOOLS (no repetitions)?' 
cur.execute("""SELECT DISTINCT PRIMARY_TYPE
               FROM CHICAGO_CRIME_DATA
               WHERE LOCATION_DESCRIPTION LIKE '%SCHOOL%';
            """)
crimes_at_schools = cur.fetchall()
crimes_at_schools

#  Q6 - 'Types of Schools and AVERAGE SAFETY SCORE for EACH?'
cur.execute("""SELECT "Elementary, Middle, or High School", ROUND(AVG(SAFETY_SCORE),2)
               FROM CHICAGO_PUBLIC_SCHOOLS
               GROUP BY 1
               ;
            """)
average_safety_scores = cur.fetchall()
average_safety_scores    #('ES', 49.52), ('HS', 49.62), ('MS', 48.0)

#  Q7 - '5 Community Areas with HIGHEST % of Households BELOW POVERTY LINE?'
cur.execute("""SELECT COMMUNITY_AREA_NAME, PERCENT_HOUSEHOLDS_BELOW_POVERTY
               FROM CENSUS_DATA
               ORDER BY 2 DESC
               LIMIT 5
               ;
            """)
highest_percentage_below_poverty = cur.fetchall()
highest_percentage_below_poverty  #('Riverdale', 56.5), ('Fuller Park', 51.2), ('Englewood', 46.6), ('North Lawndale', 43.1), ('East Garfield Park', 42.4)

#  Q8 - 'COMMUNITY AREA (number) which is 'MOST CRIME PRONE'? (Only display 'COMMUNITY_AREA_NUMBER')
cur.execute("""SELECT COMMUNITY_AREA_NUMBER
               FROM (SELECT COMMUNITY_AREA_NUMBER, COUNT(ID)
               FROM CHICAGO_CRIME_DATA
               WHERE COMMUNITY_AREA_NUMBER IS NOT NULL
               GROUP BY 1
               ORDER BY 2 DESC
               LIMIT 1)
               ;
            """)
most_crime_prone_area = cur.fetchall()
most_crime_prone_area    # COMMUNITY_AREA_NUMBER - 25

#  Q9 - 'Find NAME of COMMUNITY AREA with HIGHEST HARDSHIP INDEX (USING SUBQUERY)?'
cur.execute("""SELECT COMMUNITY_AREA_NAME, HARDSHIP_INDEX
               FROM CENSUS_DATA
               WHERE HARDSHIP_INDEX = (SELECT MAX(HARDSHIP_INDEX)
                                       FROM CENSUS_DATA)
               ;
            """)
community_highest_hardship = cur.fetchall()
community_highest_hardship  # Riverdale, HARDSHIP_INDEX = 98

#  Q10 - 'Find COMMUNITY AREA NAME with MOST NUMBER of CRIMES (USING SUBQUERY)?'
#1st way - using SUBQUERY:
cur.execute("""SELECT COMMUNITY_AREA_NAME
               FROM CENSUS_DATA
               WHERE COMMUNITY_AREA_NUMBER = (SELECT COMMUNITY_AREA_NUMBER
                                             FROM (SELECT COMMUNITY_AREA_NUMBER, COUNT(ID)
                                             FROM CHICAGO_CRIME_DATA
                                             WHERE COMMUNITY_AREA_NUMBER IS NOT NULL
                                             GROUP BY 1
                                             ORDER BY 2 DESC
                                             LIMIT 1))
               ;
            """)
community_most_crime = cur.fetchall()
community_most_crime      # = 'Austin'

#2nd way - using JOIN:
cur.execute("""WITH previous AS (SELECT COMMUNITY_AREA_NAME, cd.COMMUNITY_AREA_NUMBER, COUNT(*)
               FROM CENSUS_DATA AS cd
               JOIN CHICAGO_CRIME_DATA ccd
               ON cd.COMMUNITY_AREA_NUMBER = ccd.COMMUNITY_AREA_NUMBER
               GROUP BY 1, 2
               ORDER BY 3 DESC
               LIMIT 1)
               SELECT COMMUNITY_AREA_NAME
               FROM previous
               ;
            """)
#Note: 'WITH' statement NOT NECESSARY, but just ADDS CLARITY to final output (so JUST gives 'COMMUNITY_AREA_NAME'! Again, could do this with a SUBQUERY in 'FROM' statement too!
community_most_crime1 = cur.fetchall()
community_most_crime1



#%%                              PERFORMING 'JOINS' between these Tables:

#For Communities with 'Hardship_Index of 98', List ALL School Names, with Community Names and Average Attendance 
cur.execute("""
               SELECT NAME_OF_SCHOOL, 
                      cps.COMMUNITY_AREA_NAME,
                      cps.AVERAGE_STUDENT_ATTENDANCE, 
                      HARDSHIP_INDEX
               FROM CHICAGO_PUBLIC_SCHOOLS cps
               LEFT JOIN CENSUS_DATA csd
               ON cps.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
               WHERE csd.HARDSHIP_INDEX = 98;
               
            """)
schools_hardship_98 = cur.fetchall()
schools_hardship_98

#Listing Case Number, Crime Type and Community Area for ALL Crimes in Area Number '18'
cur.execute("""
               SELECT CASE_NUMBER, PRIMARY_TYPE, csd.COMMUNITY_AREA_NAME, cc.COMMUNITY_AREA_NUMBER
               FROM CHICAGO_CRIME_DATA cc
               JOIN CENSUS_DATA csd
               ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
               WHERE cc.COMMUNITY_AREA_NUMBER = 18;
               
            """)
community_18_crimes = cur.fetchall()
community_18_crimes      # ('JA560123', 'CRIMINAL DAMAGE', 'Montclaire', 18.0), ('JA107722', 'OTHER OFFENSE', 'Montclaire', 18.0)


##Listing 'ALL' CRIMES which took place AT a 'SCHOOL':
cur.execute("""
                SELECT CASE_NUMBER, 
                       PRIMARY_TYPE AS 'CRIME_TYPE', 
                       DESCRIPTION AS 'CRIME_DESCRIPTION', 
                       LOCATION_DESCRIPTION, 
                       COMMUNITY_AREA_NAME, 
                       cc.COMMUNITY_AREA_NUMBER
                       FROM CHICAGO_CRIME_DATA cc
                       LEFT JOIN CENSUS_DATA csd
                       ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
                       WHERE cc.LOCATION_DESCRIPTION LIKE '%school%'
                       ORDER BY CRIME_TYPE;
               
            """)
school_crimes= cur.fetchall()
school_crimes_df = pd.read_sql_query("""   
                    SELECT CASE_NUMBER, 
                    PRIMARY_TYPE AS 'CRIME_TYPE', 
                    DESCRIPTION AS 'CRIME_DESCRIPTION', 
                    LOCATION_DESCRIPTION, 
                    COMMUNITY_AREA_NAME, 
                    cc.COMMUNITY_AREA_NUMBER
                    FROM CHICAGO_CRIME_DATA cc
                    LEFT JOIN CENSUS_DATA csd
                    ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
                    WHERE cc.LOCATION_DESCRIPTION LIKE '%school%'
                    ORDER BY CRIME_TYPE;
               """, con)
school_crimes_df.head()
#Note - used 'LEFT JOIN' to obtain for ALL 'CRIMES' (EVEN IF the COMMUNITY Area Details are NOT GIVEN)


#For Oakland, Armour Square, Edgewater and CHICAGO, list ASSOCIATED 'community_area_numbers' and 'case_numbers':
#-need to ensure ALL AREAS are joined, so 'JOIN' such that ALL COMMUNITY AREAS are included, EVEN IF CRIMES are NOT REPORTED there)
cur.execute(""" SELECT CASE_NUMBER, csd.COMMUNITY_AREA_NAME,cc.COMMUNITY_AREA_NUMBER
                FROM CENSUS_DATA csd
                LEFT JOIN  CHICAGO_CRIME_DATA cc
                ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
                WHERE csd.COMMUNITY_AREA_NAME IN ('Oakland', 'Armour Square', 'Edgewater', 'CHICAGO')  
                ORDER BY `csd`.`COMMUNITY_AREA_NAME`  DESC
            """)
community_crimes = cur.fetchall()
community_crimes
community_crimes_df = pd.read_sql_query(""" 
                SELECT CASE_NUMBER, csd.COMMUNITY_AREA_NAME,cc.COMMUNITY_AREA_NUMBER
                FROM CENSUS_DATA csd
                LEFT JOIN  CHICAGO_CRIME_DATA cc
                ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
                WHERE csd.COMMUNITY_AREA_NAME IN ('Oakland', 'Armour Square', 'Edgewater', 'CHICAGO')  
                ORDER BY `csd`.`COMMUNITY_AREA_NAME`  DESC
               """, con)
community_crimes_df


#                  CREATING a 'VIEW'

# Create 'VIEW' which ONLY SELECTS 'School Name' and 'icon' fields from 'CHICAGO_PUBLIC_SCHOOLS'
#(This way, Users CANNOT SEE the ACTUAL SCORES given to Schools, ONLY the 'ICON' associated with their Score)
cur.execute(""" CREATE VIEW CHICAGO_PUBLIC_SCHOOLS_VIEW AS 
                SELECT NAME_OF_SCHOOL AS 'School_Name', 
                       Safety_Icon AS 'Safety_Rating',
                       Family_involvement_Icon AS 'Family_Rating',
                       Environment_Icon AS 'Environmental_Rating',
                       Instruction_Icon AS 'Instruction_Rating',
                       Leaders_Icon AS 'Leaders_Rating',
                       Teachers_Icon AS 'Teachers_Rating'
                FROM CHICAGO_PUBLIC_SCHOOLS
            """)
public_schools_view= cur.fetchall()
public_schools_view

#Querying the View:
cur.execute(""" SELECT School_Name, Leaders_Rating
                FROM CHICAGO_PUBLIC_SCHOOLS_VIEW
            """)
select_public_schools_view= cur.fetchall()
select_public_schools_view



#%%                CREATING a 'STORED PROCEDURE'

# (NOTE - Code Below WONT WORK HERE, since SQLite3 does NOT SUPPORT 'STORED PROCEDURES'. So best used in 'MySQL')
#Want to make sure WHEN 'ICON' Field is UPDATED, then the CORRESPONDING 'SCORE' Field is ALSO Updated

cur.execute(""" CREATE PROCEDURE UPDATE_LEADERS_SCORE (IN in_School_ID INTEGER, in_Leader_Score INTEGER)
                BEGIN 
                   UPDATE CHICAGO_PUBLIC_SCHOOLS
                   SET Leaders_Score = in_Leader_Score
                   WHERE School_ID = in_School_ID;
                   
                   IF in_Leader_Score > 0 AND in_Leader_Score < 20 THEN
                       UPDATE CHICAGO_PUBLIC_SCHOOLS
                       SET Leaders_Icon = 'Very Weak'
                       WHERE School_ID = in_School_ID;
                   ELSEIF in_Leader_Score < 40 THEN
                       UPDATE CHICAGO_PUBLIC_SCHOOLS
                       SET Leaders_Icon = 'Weak'
                       WHERE School_ID = in_School_ID;
                   ELSEIF in_Leader_Score < 60 THEN
                       UPDATE CHICAGO_PUBLIC_SCHOOLS
                       SET Leaders_Icon = 'Average'
                       WHERE School_ID = in_School_ID;
                   ELSEIF in_Leader_Score < 80 THEN
                       UPDATE CHICAGO_PUBLIC_SCHOOLS
                       SET Leaders_Icon = 'Strong'
                       WHERE School_ID = in_School_ID;
                    ELSE
                       UPDATE CHICAGO_PUBLIC_SCHOOLS
                       SET Leaders_Icon = 'Very Strong'
                       WHERE School_ID = in_School_ID;
                   END IF;
                END   
            """)
stored_procedure_update = cur.fetchall()
stored_procedure_update



#Finally, Closing the Database Connection
con.close()










#%%

