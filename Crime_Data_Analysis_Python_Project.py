
#%%                 Crime Data Analysis Project

#Import in relevant libraries for the analysis:
import pandas as pd
from matplotlib import pyplot as plt
#!pip install plotly (if not already installed)
import plotly.express as px
import seaborn as sns

#Import in the dataset 'homicide_by_countries.csv'
import os
pwd = os.getcwd()
pwd

df = pd.read_csv(f'{pwd}\homicide_by_countries.csv')
df.head()
#Viewing Columns and 'shape' of dataframe:
df.columns
#provided 'Location' (Country), 'Region' (Continent), 'Subregion', 'Year', Rating and 'Count' of homicide cases
df.shape  #195 rows, 6 columns

#Check Nulls in each Column of the dataset
df.isnull().sum()    #no nulls - good

#'Rate' Column should be renamed to 'Rating' ('Rate' is a typo)
df.rename(columns = {"Rate":"Rating"}, inplace=True)
df

#Viewing Data Types:
df.dtypes
#'Rating' does not need to be a float, so can convert to integer:
df['Rating'] = df['Rating'].astype("int64")
df.dtypes  #'Rating' is now an 'int64' type

#If we wanted to convert multiple columns to integer, just use FOR LOOP:
mylist = ['Rating', 'Count', 'Year']
#for i in my_list:
#    print(i)
#    df[i] = df[i].astype('int')

#In 'Region' Column, given 'Americas' category. Would be BETTER if displayed as 'N/S America'
#REPLACE all occurances of 'Americas' with 'N/S America':
df['Region'].replace('Americas', 'N/S America', inplace=True)


#Now, will extract Top 5 Rows from this dataframe BY 'Count'
df1 = df.sort_values(by=['Count'], ascending = False)
#Now, getting TOP 5 Columns from 'df1', just use '.head(n=5)':
df1 = df[['Location', 'Count']].sort_values(by=['Count'], ascending = False).head(n=5)
df1

#Now, can PLOT 'PIE CHART' these TOP 5 Locations by Count:
df1.plot(x='Location', y='Count', kind='pie',
                                  labels = df1['Location'],  #Add Labels showing each 'Location'
                                  autopct = '%1.2f%%')      #Convert 'Count' to PERCENTAGE of TOTAL using 'autopct'
plt.legend().set_visible(False)  #(remove legend - Not needed)

#OR, can find 'Percentages' manually using Dataframe Calculation, creating NEW COLUMN 'Percentage':
df1['Percentage'] = ((df1['Count'] / df1['Count'].sum()) * 100).round(2)
df1['Percentage']  #then can use these instead of y='Count'


#Now, creating BAR CHART to visualize AGGREGATED 'Total Count', GROUPED for EVERY 'Region':
df2 = df.groupby(['Region'])['Count'].sum().reset_index().sort_values(by='Count', ascending=False)
df2   #grouped to get TOTAL (sum) of Count for EACH 'Region', SORTED DESCENDING by Total Count
#Visualizing:
df2.plot(x='Region', y='Count', kind = 'bar')
plt.show()


#Now, GROUP Data BY 'Subregion' Column, visualizing Total Count for Each 'Subregion':
df3 = df.groupby(['Subregion'])['Count'].sum().reset_index().sort_values(by='Count', ascending=False)
df3
#Visualizing using SEABORN Library:
sns.barplot(x=df3['Subregion'], y=df3['Count'])
plt.xticks(rotation = 90)  #rotate 'x axis' labels so is CLEARER
xlabels= None


#FILTERING Dataframe:
#where 'Region' is 'Asia' OR 'Europe' and 'Year' is GREATER THAN '2016'
df4 = df[df['Region'].isin(['Asia', 'Europe'])][df['Year'] > 2016]
df4[['Region', 'Year', 'Count']]   

#GROUP BY EACH 'Region' and EACH 'Year' to get 'Total Count'
df4 = df4.groupby(['Region', 'Year'])['Count'].sum().reset_index()
df4
#so, for each Region get the total count year by year of homicide cases

#Can VISUALIZE this TIME-Series data using LINE CHART:

#But, FIRST must UNSTACK (PIVOT) this aggregated dataframe
#Finds TOTAL COUNT in EACH YEAR, for EACH REGION 'Asia' and 'Europe', now given as SEPARATE COLUMNS
df_unstacked = df4.pivot(index='Year', columns = 'Region')
df_unstacked
#i.e. converts 'grouped data' into a 'PIVOT TABLE' 
#Also should convert 'Year' values to 'integer' (given as float), THEN to string
#('Year' is the INDEX of the pivot table, so need to use '.index')
df_unstacked.index = df_unstacked.index.astype('int').astype(str)
df_unstacked.index

df_unstacked.plot(kind='line', figsize=(10,6))
plt.xlabel('Year')
plt.ylabel('Count')
plt.title('Count of Asia and Europe by Year')
plt.show()


#Grouping by YEAR now, will add up 'Rating' (for EACH YEAR):
df5 = df.groupby(['Year'])['Rating'].sum().reset_index().sort_values(by='Rating', ascending=False)
df5
df5.plot(x='Year', y='Rating', kind='bar', figsize=(7,3), color='darkred', edgecolor='black')
plt.xlabel('Year')
plt.ylabel('Count')
plt.title('Sum of Rating by Region and Year')
plt.show()
#clearly shows which 'Year's have highest ratings (descending)


#Extracting Year, Region and Count Columns:
df6 = df[['Year', 'Region', 'Count']]
df6
#Group for Each Year, Each Region
df6 = df6.groupby(['Year', 'Region'])['Count'].sum().reset_index().sort_values(by='Year', ascending=False).head(40)
df6

#Plotting as Bar Chart:
#SET 'Year' AND 'Region' AS the INDEX:
df6 = df6.set_index(['Year', 'Region'])
#plot Bars for EACH '(Year, Region)' Combination!
df6.plot(kind='bar', figsize=(12,6), colormap='viridis')
plt.xlabel('Year and Region')
plt.ylabel('Sum of Count')
plt.title('Sum of Count by Year and Region')
plt.show()


#Finally, will Group data by 'Subregion' to find AVERAGE 'Count' for EACH Subregion:
df7 = df.groupby(['Subregion'])['Count'].mean().reset_index().sort_values(by='Count', ascending=False).round(2)
df7    

           #Visualize as a TREE MAP:
#first, need to CREATE NEW Dataframe, with 'Category' (Subregion), 'Value' (Count) and 'Info' (Count as well) - need these 3 Columns!
df7['Info'] = df7['Count']
df7.rename(columns = {"Subregion":"Category", "Count":"Value"}, inplace=True)
df7
#NOW can plot as a Treemap
fig = px.treemap(df7, path = ['Category'], values = 'Value', title = 'Treemap')
#update 'Tooltip' when hovering over treemap categories (called 'hovertemplate' in plotly)
fig.update_traces(hovertemplate = 'Category: %{label}<br>Value:%{value}')
#made it show a specific format - "%{label}" adds category label, '<br>' moves to new line, '%{value}' shows the value (Count)
fig.show()

















#%%
