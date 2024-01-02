library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(plotrix)
library(janitor)

#Have 'BIKE Data' (from 'Citi Bike' - NYC Bike Sharing Program): 
#- ALL TRIPS during 'JANUARY 2020'  -  VERY LARGE Dataset, over a Million Records! 

#(FOLLOWS SAME PROCEDURE used for PYTHON DATA ANALYSIS IBM Course):

#                1. Get a General FEEL for the Data:
jan_bike_df <- read_csv('January_Bike_Trips.csv')
#Viewing the DataFrame, Columns, Number of Records and Data Types:
View(jan_bike_df)
colnames(jan_bike_df)  #15 Columns 
nrow(jan_bike_df)   # '1,240,596' Rows
str(jan_bike_df) #Data Types for EACH Column


#Specifically Selecting the 'Start' Locations and their 'tripduration'
#Also, proving that 'tripduration' is simply 'stoptime - starttime' for each row, then converted to 'seconds':
start_locations <- jan_bike_df %>%
  select(tripduration, `start station name` ,`start station longitude`, `start station latitude`, starttime, stoptime) %>%
  mutate(duration = (stoptime - starttime)*60) %>% 
  clean_names()   #replace spaces in column names with '_' (make names CLEAN and CONSISTENT)
head(start_locations)


#Finding 'AVERAGE TRIP DURATION', for Trips taken from EACH 'start station':
average_trip_duration <- start_locations %>% 
  group_by(start_station_name) %>% 
  summarize(average_trip_duration = mean(tripduration), na.rm=TRUE)
head(average_trip_duration)


#Can Create 'HEAT MAP' of 'START LOCATIONS' (longitude AND latitude):
# (HEAT MAP = COUNTS/Frequencies for 2 Variables TOGETHER, COLOR-CODED)
citibike_heatmap <- ggplot(jan_bike_df, aes(x=`start station longitude`, y = `start station latitude`)) + 
                    geom_bin2d(binwidth = c(0.001,0.001)) +
                    labs(x = 'Starting Location Longitude', y = 'Starting Location Latitude', fill='Count') 
citibike_heatmap     #use 'fill=' in LABS to change the the 'LEGEND TITLE' LABEL


#Calculating AVERAGE SPEED and AGE of the Riders FROM our DataFrame:
    #(are YOUNGER Riders On Average at HIGHER SPEEDS than Older Riders?)
#Note: is VERY LARGE Dataset - so SHOULD NARROW DOWN/FILTER DOWN the Rows (JUST so RUNS QUICKER, OR can wait a bit for it to run - OPTIONAL!)

#FILTERING for ONLY Trips LESS THAN 900 seconds (15 Minutes):
short_trips <- all_data %>%
     filter(tripduration < 900)
head(short_trips)

#Are GIVEN COLUMN for 'birth.year' (DOB of Riders). This DATA is from 2020
#    So can do '2020 - birth.year' to get AGE:
short_trips <- short_trips %>%
     mutate(age = 2020 - birth.year)
head(short_trips)


# FIRST need to find 'DISTANCE' traveled (BEFORE we find 'Speed')
#    HOW do we find DISTANCE between two points GIVEN the 'LONGITUDES and LATITUDES' of START and END?
# Can use 'distHaversine()' FUNCTION from 'geosphere' LIBRARY  (= way to calculate SHORTEST DISTANCE Between 2 Points)
# - Takes ARGUMENTS for 2 DATAFRAMES - containing LONGITUDES and LATITUDES for 'START' and 'END' Locations.
# - FROM these 2 START and END locations, can FIND the DISTANCE between them!
install.packages("geosphere")
library(geosphere)

starting <- short_trips %>%
    select(start.station.longitude, start.station.latitude)
ending <- short_trips %>%
    select(end.station.longitude, end.station.latitude)
#NOW can add NEW COLUMN for 'Distance' into our 'short_trips' dataframe:
short_trips <- short_trips %>%
    mutate(Distance = distHaversine(starting, ending))     
colnames(short_trips)   #Now have 'Distance' Column - COOL!

#SPEED = 'Distance' / 'tripduration'   - SIMPLE! Create 'Speed' Column:
short_trips <- short_trips %>%
     mutate(speed = Distance / tripduration)
head(short_trips$speed)     # '$' to ACCESS ELEMENTS (COLUMNS) in DataFrames!

#NOW can see 'AVERAGE' SPEED, 'GROUPED by AGE':
average_speed_by_age <- short_trips %>%
     group_by(age) %>%
     summarize(average_speed = mean(speed))     #Simple Grouping!
head(average_speed_by_age)

#NICE! Now time to PLOT a LINE GRAPH for 'Average Speed' for EACH 'AGE':
average_speed_by_age_plot <- ggplot(average_speed_by_age, aes(x=age, y= average_speed)) + 
                             geom_line()  +
                             labs(title = "Average Speed of Citi Bike Users by Age (January 2020)", x="Age", y="Average Speed (m/s)") +
                             theme(plot.title = element_text(hjust = 0.5))
#(note: 'theme(plot.title = element_text(hjust=...)) used to ADJUST POSITION of 'plot.title')

average_speed_by_age_plot

#NOW lets GROUP BY 'age' AND 'gender':               '1 = MALE, 2 - FEMALE, 0 = UNSPECIFIED Gender'
average_speed_by_age_and_gender <- short_trips %>%
  group_by(age, gender) %>%
  summarize(average_speed = mean(speed)) 
head(average_speed_by_age_and_gender) 

#PLOTTING - Can CREATE PLOT INSIDE a PIPING as shown BELOW:
average_speed_by_age_and_gender %>% 
  filter(age < 80, !(gender==0)) %>%    #Best to FILTER to MORE REASONABLE AGE RANGE and for 'Male' and 'Female' ONLY
  ggplot(aes(x = age, y = average_speed, color = factor(gender))) + geom_line() + 
  labs(title = "Average speed of Citi Bike users by age (January 2020)", x = "Age", y = "Average Speed (m/s)") + 
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_color_discrete(labels = c("Male", "Female"))
#Had to 'factor()' for 'gender' - since is DISCRETE VARIABLE for '0', '1', '2'!
# FILTERED OUT 'gender = 0' TOO (ONLY including 'gender = 1 or 2' - MALE or FEMALE). SIMPLE!


#  STACKED BAR PLOT of AGES and GENDER 'Distribution' (i.e. COUNT/FREQUENCY of EACH Age/Gender GROUPING)
age_counts <- short_trips %>%
  group_by(age, gender)  %>%
  tally() %>%            #'tally()' Function gives 'COUNT of BIKERS' for EACH 'AGE and GENDER' GROUPING
  rename('Count' = 'n') %>%
  filter(age < 80, !(gender == 0))            
head(age_counts)   # SAME as doing 'summarize(count = n())'! 
#'tally()' STORES 'COUNTS' in Column called 'n' - just RENAMED this to 'Count'

age_counts_plot <- ggplot(age_counts, aes(x=age, y=Count, fill=factor(gender))) + 
                   geom_bar(position='stack', stat='identity') +
                   labs(title = "Citi Bike Users By Age And Gender", x = "Age", y = "Count") +
                   theme(plot.title = element_text(hjust = 0.5)) + 
                   scale_fill_discrete(name="Gender", labels = c("Male Identifying","Female Identifying"))
age_counts_plot
#Successfully shows distribution as STACKED BAR PLOT of MALE vs. FEMALE Proportions for EACH 'AGE' Grouping.






