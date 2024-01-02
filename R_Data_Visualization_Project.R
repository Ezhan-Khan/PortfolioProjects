
#                             Data Visualization Project using 'ggplot2' Package in R:

#Will perform Data Visualization for a Dataset on 'Museums in the United States'
#Load in Relevant Libraries required for Visualization:
library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(plotrix)

#Viewing the THOUSANDS of MUSEUMS (as well as 'Aquariums', 'Parks' and 'Zoos') ACROSS the U.S. See DISTRIBUTION of these institutions BY REGION (Location), TYPE and ANNUAL REVENUE. 
# Note: EACH Museum ALSO has PARENT ORGANIZATION - e.g. IF museum is IN UNIVERSITY, 'PARENT' Organisation = 'UNIVERSITY' within which the MUSEUM is found. 
museums_df <- read.csv("museums.csv")
tail(museums_df)  #Examining LAST FEW ROWS
#'Museum.Name' = Name of EACH 'INDIVIDUAL' INSTITUTION
#'Legal.Name' = Name of 'PARENT' ENTITY (Note: museums can SHARE a PARENT Entity, but EACH have a UNIQUE 'Muesum.Name'!)

#EACH INSTITUTION by 'TYPE' (BASIC Bar Plot):
museum_types <- ggplot(museums_df, aes(x=Museum.Type)) + 
  geom_bar() + 
  scale_x_discrete(labels = scales:::wrap_format(8)) 
museum_types  #'labels = scales:::wrap_format(8)' LIMITS LABELS WIDTH per Line, to MAX of 8 Characters!

# 'Is.Museum' - TRUE/FALSE BOOLEAN Column. TRUE = museums (art, history, science), FALSE = zoos, aquariums (i.e. NOT Really Museums)
museum_class <- ggplot(museums_df, aes(x=Is.Museum)) + 
  geom_bar() + 
  scale_x_discrete(labels = c("TRUE" = "Museum", "FALSE" = "Non-Museum"))
museum_class

#FILTERING JUST for A FEW STATES. THEN, use BAR PLOT with 'FACETS', to display 'Museum vs. Non-Museum' for EACH of these STATES:
museum_states <- museums_df %>%
  filter(State..Administrative.Location. %in% c("IL", "CA", "NY"))  #JUST these STATES

museum_facet <- ggplot(museum_states, aes(x=Is.Museum)) + geom_bar(aes(fill=Is.Museum)) + 
  facet_grid(cols = vars(State..Administrative.Location.)) +
  scale_x_discrete(labels = c("TRUE" = "Museum", "FALSE" = "Non-Museum")) 

museum_facet
#Have MOST Museums in 'CA', and MOST 'Non-Museums' in 'NY'. See that 'IL' has LEAST MUSEUMS AND Least 'Non-Museums'. 

#  STACKED BAR PLOT showing COUNT of MUSEUMS BY 'REGION' (Region.Code..AAM.)
#('FILL' AESTHETIC being for 'Is.Museum'. ALSO, need to 'factor(Region.Code..AAM)' to CONVERT to DISCRETE Region Codes, RATHER than as CONTINUOUS values):
museum_stacked <- ggplot(museums_df, aes(x = factor(Region.Code..AAM.), fill = Is.Museum)) + 
  geom_bar(position="stack") + 
  scale_x_discrete(labels = c("1" = "New England", "2" = "Mid-Atlantic", "3"="Southeastern", "4"="Midwest", "5"="Mountain Plains", "6"="Western")) + 
  scale_fill_discrete(labels = c("TRUE" = "Museum", "FALSE" = "Non-Museum")) + 
  labs(x = "Region", fill = 'Type')
museum_stacked
#ALSO use 'scale_x_discrete()' to RENAME 'Numeric LABELS' to TEXT (Region 'NUMBERS' are too VAGUE!) AND 'scale_fill_discrete' to RENAME the 'FILL' values in the LEGEND to 'Non-Museum' and 'Museum'

# STACKED Bar Plot for 'PERCENTAGES' of 'Museum' vs. 'Non-Museum' by Region - MAY be CLEARER! So TRANSFORM the Plot ABOVE for 'PERCENTAGES' in y-axis:
museum_stacked <- ggplot(museums_df, aes(x = factor(Region.Code..AAM.), fill = Is.Museum)) + 
  geom_bar( position="fill") + 
  scale_y_continuous(labels = scales:::percent_format()) + 
  scale_x_discrete(labels = c("1" = "New England", "2" = "Mid-Atlantic", "3"="Southeastern", "4"="Midwest", "5"="Mountain Plains", "6"="Western")) + 
  scale_fill_discrete(labels = c("TRUE" = "Museum", "FALSE" = "Non-Museum")) + 
  labs(title = 'Museum Types by Region', x = "Region", y = 'Percentage of Total', fill='Type')
museum_stacked   #ALSO 'RELABELLED' AXES, Added TITLE and RELABELLED 'fill' LEGEND 


#        'INSTITUTIONS' by 'REVENUE' 
# Will investigate HOW MUCH MONEY is Brought in by EACH INSTITUTION and HOW it varies BY 'GEOGRAPHY' (Region)
#FILTER the Dataset to REMOVE DUPLICATES (ONLY want 'Parent Organization' Level)

#DataFrame 1 'museums_revenue_df' 
#            - ONLY 'unique values' of 'Legal.Name' (REMOVE DUPLICATE ROWS)
#            - FILTER so ONLY institutions with ANNUAL REVENUE GREATER THAN 0 (i.e. NOT Free!)            
museums_revenue_df <- museums_df %>%
  distinct(Legal.Name, .keep_all = TRUE) %>% #KEEP ALL COLUMNS, REMOVES DUPLICATES 
  filter(Annual.Revenue > 0)    

#DataFrame 2 'museums_small_df'
#            - ONLY museums with 'Annual.Revenue < $1,000,000 
museums_small_df <- museums_revenue_df %>%
  filter(Annual.Revenue < 1000000)

#Dataframe 3 'museums_large_df'
#            = ONLY museums with 'Annual.Revenue > 1000000000'
museums_large_df <- museums_revenue_df %>%
  filter(Annual.Revenue > 1000000000)

#VISUALIZING for 'SMALL Museums' - HISTOGRAM of 'Annual.Revenue' DISTRIBUTION:
revenue_histogram <- ggplot(museums_small_df, aes(x=Annual.Revenue)) + 
  geom_histogram(binwidth = 20000) + 
  scale_x_continuous(labels = scales:::dollar_format())
revenue_histogram   #Must EXPERIMENT with BINWIDTH to see WHICH is BEST - OR can just see what DEFUALT looks like (AUTO-ADJUSTS for us!). About '20,000' Bindiwth seems GOOD!
#ALSO added 'DOLLAR SIGNS' using 'scales:::dollar_format()'


#VISUALIZING for 'LARGE Museums' - NOW will do BOXPLOT, with 'Region.Code..AAM.' on x-axis and 'Annual.Revenue' on y-axis.
revenue_boxplot <- ggplot(museums_large_df, aes(x=factor(Region.Code..AAM.) , y=Annual.Revenue)) + 
  geom_boxplot() + 
  scale_x_discrete(labels = c("1" = "New England", "2" = "Mid-Atlantic", "3"="Southeastern", "4"="Midwest", "5"="Mountain Plains", "6"="Western")) + coord_cartesian(ylim = c(1e9, 3e10)) + labs(x = 'Region') + 
  scale_y_continuous(labels = function(x) paste0("$", x/1e9, "B"))
revenue_boxplot

#Notice - used 'factor( )' to CONVERT 'REGIONS' to DISCRETE Values, also CHANGED LABELS for 'x scale' to the TEXT equivalents INSTEAD (CLEARER!)
#ONE Outlier dot for 'New England' is VERY FAR OFF! Makes it HARD TO READ the BOXPLOTS! 
#So? used 'coord_cartesian()' to ZOOM IN, setting 'ylim = c(1.0e9, 3.0e10)'. Now is MUCH CLEARER to see HOW Q1, Q2 (Median) and Q3 VARY for the Different REGIONS!
# 'scale_y_continuous' REFORMATS 'REVENUE' y-axis so is in BILLIONS OF DOLLARS - using 'USER-Defined' FUNCTION CUSTOM LABEL:
#       function(x) paste0("$", x/1e9, "B")   -makes sense!


#NOW for 'Revenue' across ALL MUSEUMS 'museums_revenue_df'
#  Using 'BARPLOT', with 'Region.Code..AAM.' as x-axis (converted using 'factor()'), 'Annual.Revenue' as y-axis.
#SUMMARIZE as 'MEAN REVENUE' BY Region:
revenue_barplot <- ggplot(museums_revenue_df, aes(x=factor(Region.Code..AAM.), y=Annual.Revenue)) + 
  geom_bar(aes(fill=factor(Region.Code..AAM.)), stat="summary", fun="mean") + 
  scale_fill_discrete(labels = c("1" = "New England", "2" = "Mid-Atlantic", "3"="Southeastern", "4"="Midwest", "5"="Mountain Plains", "6"="Western"))+
  scale_x_discrete(labels = c("1" = "New England", "2" = "Mid-Atlantic", "3"="Southeastern", "4"="Midwest", "5"="Mountain Plains", "6"="Western")) + 
  labs(x="Region",y="Mean Annual Revenue", title = 'Average Annual Revenue by Region') + 
  scale_y_continuous(labels = function(x) paste0("$", x/1e9, "B"))
revenue_barplot
#Using ALOT of the SAME FORMATTING for 'SCALES' and 'LABELS' to make MORE READABLE. 
#FOR FUN, just COLOR CODED to BETTER DISTINGUISH Between the REGION Bars - using 'aes(fill=...)'!

# Bar Plot 'WITH ERROR BARS':
museums_error_df <- museums_revenue_df %>%
  group_by(Region.Code..AAM.) %>%
  summarize(Mean.Revenue = mean(Annual.Revenue), Mean.SE = std.error(Annual.Revenue)) %>%
  mutate(SE.Min = Mean.Revenue - Mean.SE, 
         SE.Max = Mean.Revenue + Mean.SE)

revenue_errorbar <- ggplot(museums_error_df, aes(x=factor(Region.Code..AAM.), y=Mean.Revenue)) + 
  geom_bar(stat="identity") + 
  geom_errorbar(aes(ymin=SE.Min, ymax = SE.Max, width=0.3))
revenue_errorbar

