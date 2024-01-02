
#%%                      IBM Data Exploration PORTFOLIO PROJECT - 'King County Housing Dataset'

#This Project demonstrates the ability to perform essential data processing and exploratory data analysis on an initially unfamiliar dataset. 
#Furthermore, performing deeper analysis through model development and evaluation

#Real Estate Investment Trust - want to start Investing in 'RESIDENTIAL REAL ESTATE'
#Determine 'MARKET PRICE' of a House, based on 'SET of FEATURES'

#Analyse and Predict HOUSING PRICES

#Dataset - 'House Sale Prices' for King County (including Seattle)
#Homes Sold BETWEEN 'May 2014 - May 2015'

#Importing all Necessary Libraries for the Analysis:         (highlight code to run and press f9)
from matplotlib import pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from scipy import stats  
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler,PolynomialFeatures
from sklearn.linear_model import LinearRegression


#  1. IMPORT the Dataset:           (obtained dataset by providing the URL to the CSV file)
file_name='https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-DA0101EN-SkillsNetwork/labs/FinalModule_Coursera/data/kc_house_data_NaN.csv'
df = pd.read_csv(file_name)
df.head(5)
len(df)  #'df' has '21,613' Rows of Data - quite Large!
#Can View the COLUMNS and their respective Data Types:
print(df.dtypes)   

#  2. Perform some DATA CLEANING:
#The Columns 'id' and 'Unamed: 0' are NOT NEEDED for Analysis (so can DROP them!)
df.drop(['id', 'Unnamed: 0'], axis=1, inplace = True)
#Getting Summary Statistics for ALL Columns:
Summary_Stats = df.describe(include = "all")
Summary_Stats  

#Viewing if any Columns contain MISSING (NULL) VALUES:
print(df.info())  #see that 'bedrooms' and 'bathrooms' columns have MISSING VALUES
#Can ALSO CHECK this by using '.is_null' and '.value_counts':
missing_data = df.isnull()    #Converts to 'BOOLEAN Values' (True = NULL, False = NOT NULL)
for column in missing_data.columns.values:
    print(column)
    print(missing_data[column].value_counts())
    print("")  
#bedrooms' is missing '13 values', 'bathrooms' is missing '10'

#For 'bedrooms', REPLACE these 'NULL' Values with 'Column MEAN':
df['bedrooms'].replace(np.NaN, int(df['bedrooms'].mean()), inplace=True)
#Do the SAME for 'bathrooms':
df['bathrooms'].replace(np.NaN, int(df['bathrooms'].mean()), inplace=True)
#Note: use int() to ROUND Average to WHOLE NUMBER (since cannot have float for number of bedrooms/bathrooms)

#CHECKING that NULL values have been REPLACED:
df['bedrooms'].isnull().value_counts()
df['bathrooms'].isnull().value_counts()   
#'False' for ALL ROWS of df (21,613 rows) - ALL NULLS REPLACED!



#                               3.  EXPLORATORY DATA ANALYSIS:
#Finding 'COUNTS' of UNIQUE 'floors' values:
df['floors'].value_counts().to_frame()
#(converted to a 'DataFrame' using '.to_frame()' method)
#See that MOST Houses appear to have '1 Floor' ONLY = '10,680' Rows of Houses

#'BOXPLOT' - to Compare PRICE of Houses WITH or WITHOUT Waterfront:
sns.boxplot(x="waterfront", y="price", data=df)
#Appears that  Boxplot for 'waterfront=0' (House WITHOUT Waterfront) has MORE Price 'OUTLIERS'

#'REGRESSION PLOT' - see if 'sqft_above' and 'price' have +ve or -ve Correlation:
sns.regplot(x="sqft_above", y="price", data=df, line_kws = {"color":"red"})
plt.ylim(0,)     
#there is clearly a POSITIVE CORRELATION - increase in 'sqft_above' leads to a noticable increase in 'price'  
#Use '.corr()' to see OTHER CORRELATIONS with 'price':
correlations = df.corr()
#accessing just the 'price' column and sorting from HIGHEST Correlation to LOWEST
correlations['price'].sort_values(ascending=False)
#See that 'sqft_living' has HIGHEST CORRELATION with 'price'
#'grade', 'sqft_above' and 'bathrooms' ALSO have notably high correlations!



#                                  4.  MODEL DEVELOPMENT:
#Fitting LINEAR REGRESSION MODEL
# 'long' = Predictor X Variable, 'price' = Y Variable
lm = LinearRegression()  #Linear Regression OBJECT
X = df[['long']]
Y = df['price']
lm.fit(X,Y)           #'TRAINING' the MODEL
Yhat_simple = lm.predict(X)    #ARRAY for PREDICTED House 'price' (i.e. 'REGRESSION LINE' Data Points)
Yhat_simple[0:5]   #viewing First 5 Elements/Predicted Values
lm.intercept_     #7430229.31
lm.coef_          #array([56377.72275781])
#'R-Squared':
lm.score(X,Y)     # = 0.00046769, VERY WEAK FIT

#Now, for 'sqft_living' = Predictor X Variable, 'price'=Y Variable
lm1 = LinearRegression()
X = df[['sqft_living']]
Y = df['price']
lm1.fit(X,Y)           #'TRAINING' the MODEL
Yhat_simple = lm1.predict(X)    #ARRAY for PREDICTED House 'price' (i.e. 'REGRESSION LINE' Data Points)
Yhat_simple[0:5]   #viewing First 5 Elements/Predicted Values
lm1.intercept_     #-43580.743
lm1.coef_          #array([280.6235679])
#'R-Squared':
print(lm1.score(X,Y))     # = 0.49285  -  Good Fit

# 'MULTIPLE LINEAR REGRESSION' - fitting 'Multiple Features' to predict 'price':
features = ["floors", "waterfront","lat" ,"bedrooms" ,"sqft_basement" ,"view" ,"bathrooms","sqft_living15","sqft_above","grade","sqft_living"]     
lm_mult = LinearRegression()
Z = df[features]
Y = df['price']
#Use 'lm.fit' again (as before)
lm_mult.fit(Z, Y)
#OBTAIN 'ARRAY of PREDICTED' Values (using PREDICTOR VARIABLES in 'Z' Array/DataFrame):
Yhat_mult = lm_mult.predict(Z)  
Yhat_mult
Yhat_mult = Yhat_mult.reshape(1,-1)  #RESHAPES from 'Single Column' Array to STANDARD SINGLE ARRAY (i.e. like 1D List)
#Find 'intercept (b0) and 'coefficients' (b1, b2, b3...) the SAME WAY:
lm_mult.intercept_    # array([-32390214.49990257])
lm_mult.coef_         #Array of coefficients:  array([[-2.92878942e+04,  6.02005241e+05,  6.72991263e+05, -2.59895205e+04,  6.44290194e+01,  6.70763755e+04, -3.24458746e+03,  4.42849089e+00,  6.49472865e+01, 8.20190705e+04,  1.29376306e+02]])
#'R-Squared':
print(lm_mult.score(Z,Y))    # = 0.6577 -  BETTER FIT for 'MULTIPLE' Linear Regression!

#Creating 'PIPELINE' to EFFICIENTLY perform SEQUENCE of STEPS:
Input = [('scale', StandardScaler()), ('polynomial', PolynomialFeatures(include_bias = False)), ('model', LinearRegression())]
piped = Pipeline(Input)     # = 'PIPELINE OBJECT'
piped   
#Now 'TRAIN' this PIPELINE OBJECT, FIT 'Z' and 'Y'!
Z - Z.astype("float64")
piped.fit(Z, Y)
ypiped = piped.predict(Z)   # = PREDICTED Y Values 
ypiped[0:10]   #viewing first 10 Predicted Y Values

R_Squared_Piped = r2_score(Y, ypiped)
R_Squared_Piped    # '= 0.75134'  -  EVEN BETTER FIT!



#                                5.  Model 'EVALUATION' and 'REFINEMENT':
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import train_test_split

#SPLIT Data into 'TRAINING' and 'TESTING' SETS:
y_data = df['price'] 
x_data = df[features]
#Using '15%' of Data for 'TESTING' Set:
x_train, x_test, y_train, y_test = train_test_split(x_data, y_data, test_size=0.15,random_state=0)
print(f"Test Samples: {x_test.shape[0]}")       #'3242' Samples
print(f"Training Samples: {x_train.shape[0]}")  #'18371' samples

#RIDGE REGRESSION MODEL using 'Training Data'
from sklearn.linear_model import Ridge
#Here, using 'alpha = 0.1':
RidgeModel = Ridge(alpha = 0.1)
#FITTING to 'TRAINING' Subset
RidgeModel.fit(x_train, y_train)
#Use 'RidgeModel.score()' to find R-squared Value for 'TESTING' Subset:
test_score = RidgeModel.score(x_test, y_test)
print(test_score)     # = 0.64848   
#Still GOOD Fit, but now have Less 'Over-Fitting' and REDUCED 'Standard ERRORS' for our Regression Model

#INSTEAD, performing '2nd Order' POLYNOMIAL TRANSFORM:
pr = PolynomialFeatures(degree=2)
x_train_pr=pr.fit_transform(x_train)
x_test_pr=pr.fit_transform(x_test)
#Create 'RIDGE REGRESSION' Object (using 'alpha = 0.1')    
RidgeModel = Ridge(alpha = 0.1)
#FITTING 'Ridge Model' (using 'fit' AS USUAL!)
RidgeModel.fit(x_train_pr,y_train)    #'TRAIN' the MODEL
Yhat_ridge = RidgeModel.predict(x_test_pr)  #MADE PREDICTION (using 'TEST' Data). 
#Now COMPARING:
print(f'predicted: {Yhat_ridge[0:4]}')
print(f'test set: {list(y_test[0:4])}')

#TEST Data 'R-Squared' Score for Ridge Regression (of 2nd Order Polynomial):
test_score1 = RidgeModel.score(x_test_pr, y_test)
print(test_score1)         # '= 0.7164'  = BETTER Fit!


# Creating a DISTRIBUTION PLOT for this 'Yhat' (PREDICTED) and 'Y'(ACTUAL) Values:
def DistributionPlot(RedFunction, BlueFunction, RedName, BlueName, Title):
    #'RedFunction' = ACTUAL y-data, 'BlueFunction' = PREDICTED y-Data
    width = 12
    height = 10   #just specifying specific SIZE of PLOT
    plt.figure(figsize=(width, height))
    #PLOTTING the 2 'kdeplots' for the 2 Functions:
    ax1 = sns.kdeplot(RedFunction, color="r", label=RedName)
    ax2 = sns.kdeplot(BlueFunction, color="b", label=BlueName, ax=ax1)
    #(Note: 'kdeplot' = 'KERNEL-Distribution-Estimation' Plot, SIMILAR to 'Histogram' Distribution. Used for 'CONTINUOUS PROBABILITY DENSITY' Curve)
    #('kdeplot' is just ALTERNATIVE to 'distplot'!)
    
    #Plotting the LABELS:
    plt.title(Title)      
    plt.xlabel('Price')
    plt.ylabel('Proportion')
    plt.show()
    plt.close()

#Distribution Plot, showing FIT of this FINAL MODEL:    
Title = "Distribution Plot of 'Predicted Value Using Testing Data (Yhat)' vs 'Testing Data (Y) Distribution'"
DistributionPlot(y_test, Yhat_ridge, "Actual Values (Test)", "Predicted Values (Test)", Title)
#as we see, the 'BlueFunction' ('Predicted' Y-Values Function) is QUITE CLOSE to the 'RedFunction' ('Actual' Y-values Function)

#COMPARE to 'DISTRIBUTION PLOT' for 'sqft_living' (SIMPLE LINEAR):
Title = "Distribution Plot of 'Predicted Value Using Testing Data (Yhat)' vs 'Testing Data (Y) Distribution'"
DistributionPlot(Y, Yhat_simple, "Actual Values (Test)", "Predicted Values (Test)", Title)
#(may need to refresh 'Y' value, before running. Occasionally comes up with error)

#COMPARE to 'DISTRIBUTION PLOT' for 'Yhat_mult' (MULTIPLE LINEAR):
Title = "Distribution Plot of 'Predicted Value Using Testing Data (Yhat)' vs 'Testing Data (Y) Distribution'"
DistributionPlot(Y ,Yhat_mult , "Actual Values (Test)", "Predicted Values (Test)", Title)




#%%                 Repeating a SIMILAR EDA Methodology for a Different Dataset - 'Medical Insurance Charges' Dataset

#Performing EDA and MODEL DEVELOPMENT and EVALUATION for 'Medical Insurance Charges' Dataset 
#(Modified Version of 'Medical Insurance Price Prediction' Dataset from 'Kaggle')

#                        Dataset VARIABLES: 
# 'Age' (integer)
# 'Gender' (1=Female, 2=Male)
#  BMI (Float)
#  No_of_Children (Integer)
# 'Smoker' (1=Smoker, 0=Non-Smoker)
# 'Region' (Northwest=1, Northeast=2, Southwest=3, Southeast=4)
# 'Charges' (Float, in USD)

#                           OBJECTIVES:
# 'Load Data'
# 'Clean Data/Deal with Blanks' 
#  Run 'Exploratory Data Analysis' (identify Variables/Attributes with MOST AFFECT on 'Charges')
#  Develop 'SINGLE' VARIABLE and 'MULTI'-VARIABLE Linear Regression Models (i.e. to PREDICT 'Charges')
#  Use 'RIDGE REGRESSION' (refine PERFORMANCE of Linear Regression Models)

from matplotlib import pyplot as plt
import matplotlib
import seaborn as sns
import pandas as pd
import numpy as np
from scipy import stats  

#   1.  LOADING and VIEWING the DATASET
filepath = 'https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-DA0101EN-Coursera/medical_insurance_dataset.csv'
df = pd.read_csv(filepath, header=None)
df.head()  #But, has NO HEADER YET. SO? must ADD IT:
headers = ['Age', 'Gender', 'BMI', 'No_of_Children', 'Smoker', 'Region', 'Charges']
df.columns = headers
df.head() # Now ALL have HEADERS ADDED.

#Now dealing with MISSING VALUES:
#-these are given as '?'. BETTER to REPLACE with 'NaN'
df = df.replace("?", np.NaN)

#Viewing DATA TYPES of the Columns:
df.dtypes     #assigned Data Types AUTOMATICALLY, but can CHANGE this if we WANT
#Viewing SUMMARY STATISTICS for ALL Columns (including Non-Numerical Data/'Objects'):
summary_stats = df.describe(include = "all")
print(summary_stats)
#Extra 'Information' ('non-null'):
print(df.info())   
#'.info()' USED to 'IDENTIFY any COLUMNS' with 'NULL' (MISSING VALUES) 
#See that 'Age' and 'Smoker' Columns HAVE some MISSING DATA!




#   2.  DATA CLEANING

#Can ALSO VIEW any MISSING/NULL Values like so (COOL!)
missing_data = df.isnull()    #Converts to BOOLEAN Values (True = NULL, False = NOT NULL)
for column in missing_data.columns.values:
    print(column)
    print(missing_data[column].value_counts())
    print("")

#                       HOW do we HANDLE any MISSING DATA?
#  - for 'CONTINUOUS Attributes' (like 'Age'), REPLACE with 'MEAN' Values
mean_age= int(np.mean(df['Age'].astype('float64')))
mean_age   # = approximately '39 years old (INTEGER)'
#Replacing All MISSING VALUES from 'Age' column with the 'MEAN Age'
df["Age"].replace(np.nan, mean_age, inplace=True)  
df[df["Age"] == np.NaN]   #EMPTY Dataframe - ALL 'np.nan' Values REPLACED!

#  - for 'CATEGORICAL Attributes' ('Smoker'), REPLACE with 'MODE' Value
counts_smoker = df['Smoker'].value_counts()
print(counts_smoker)  # see that '0' is MOST COMMON (2201 Rows = people who DONT SMOKE)
#Replacing ALL MISSING VALUES from 'Smoker' Column with '0' ('Mode' Category)
df['Smoker'].replace(np.nan, '0', inplace=True)

#Changing 'DATA TYPE' of 'Age' Column to 'INTEGER':
df['Age'] = df['Age'].astype('int64')
df.dtypes   #'Age' is NOW an 'INTEGER'!
#Changing 'DATA TYPE' of 'Smoker' to 'INTEGER' too:
df['Smoker'] = df['Smoker'].astype('int64')

#'DOUBLE-CHECKING' - NOW have NO 'NULLS'! (ALL ROWS of ALL Columns are 'NON-NULLS')
print(df.info())  
print(df.dtypes)

#'Charges' Columns is in USD, so must KEEP to '2d.p. ONLY':
df['Charges'] = np.round(df[['Charges']], 2)
print(df.head(n=5))

#Could try 'BINNING' the 'Charges' Column into CATEGORIES:
bins = np.linspace(np.min(df['Charges']), np.max(df['Charges']), 4)
bins
#provide GROUP NAMES:
group_names = ["Low", "Medium", "High"]
#Then use df['New_Binned_Column'] = 'pd.cut(column, bins, labels, include_lowest = True )'
df['Charges_Binned'] = pd.cut(df['Charges'], bins, labels=group_names, include_lowest=True)
#(ADDED the NEW BINNED COLUMN to the DataFrame)
df[['Charges', 'Charges_Binned']]  #See that 'prices' have been GROUPED INTO 'BINS' (Low, Medium and 'High')


#Selecting 'Charges', FILTERING for 'Low', 'Medium' and 'High' in 'Charges_Binned':
Low_Charges = df[df['Charges_Binned'] == 'Low'][['Charges']]   
Medium_Charges = df[df['Charges_Binned'] == 'Medium'][['Charges']]   
High_Charges = df[df['Charges_Binned'] == 'High'][['Charges']]   
#Printing the MIN and MAX Values of EACH CATEGORY:
for Category in [Low_Charges, Medium_Charges, High_Charges]:
    print(f"Minimum {str(np.min(Category))} Maximum {str(np.max(Category))} \n")


#PLOTTING 'BAR CHART' of COUNTS in Each Category:
color = (0.2, # redness 
        0.7, # greenness
         0.6, # blueness
         1 # transparency
         ) 
#               Create Bars:    
fig, ax = plt.subplots()
ax.bar(group_names, df['Charges_Binned'].value_counts(), color=color)    #used '.value_counts()' to get 'FREQUENCIES' for 'EACH (Binned) Category'
plt.xlabel('Charges', fontsize=18)
plt.ylabel('Count', fontsize=18)    #'fontsize' sets SIZE of FONT (for labels, ticks...)
plt.xticks(fontweight = 'bold', fontsize=15)     #'fontweight' can make font "bold"
plt.yticks(fontsize=15)
plt.title('Charges Category Counts')      #As we see, MOST 'Charges' are within this 'LOWER Bin' Category.
plt.show()



#    3.  EXPLORATORY DATA ANALYSIS:

#Can use 'REGRESSION PLOT' to show 'Charges' with respect to 'BMI;
sns.regplot(x="BMI", y="Charges", data=df, line_kws = {"color":"red"})
plt.ylim(0,)      #Quite Weak Real Correlation between 'BMI' and 'Charges'
#

#Lets Create 'BOX PLOT' for 'Charges', for EACH 'Smoker' Category (0=not smoker, 1=smoker):
sns.boxplot(x="Smoker", y="Charges", data=df)

#Printing 'CORRELATION Matrix' for ENTIRE DATASET:
correlation_matrix_df = df.corr()
#as we see, 'Correlation' between a Lot of the Variables is quite POOR.

#  'AGGREGATE STATISTICS' - using '.groupby()' method: 
df.dtypes    #seeing which Columns to potentially GROUP BY!
df_test = df[['Age', 'Gender', 'Charges']]    #choose our specific rows
#Finding 'Average Charges' for EACH AGE and for EACH GENDER:
df_group = df_test.groupby(['Age', 'Gender'], as_index=False).mean()
df_group  
#Renaming 'Charges' to 'Average Charges' (More Descriptive!)  
df_group.rename(columns = {'Charges': 'Average Charges'}, inplace=True)
print(df_group.sort_values(by=['Average Charges'], ascending = False))
#See that the 'HIGHEST Average Charges' = 26262.17 is for Age = 60, Gender = 2 (Male)
#EASIER to VISUALIZE as a 'PIVOT TABLE':
df_group_pivot = df_group.pivot(index='Gender', columns = 'Age')
print(df_group_pivot)
#Switches around 'index' and 'columns' values, so can view as 'WIDE' or 'LONG' Data Format (vice versa) 

#Can GROUP to find 'MAX Charges' BY 'Region':
df_test2 = df[['Region', 'Charges']]    
df_group2 = df_test2.groupby(['Region', ], as_index=False).max()
df_group2.rename(columns = {'Charges': 'Max Charges'}, inplace=True)
print(df_group2.sort_values(by=['Max Charges'], ascending=False))
#See that 'Region = 4' (South East) has HIGHEST Max Charges!
#Region = 3 (South West) has LOWEST Max Charges

#Can use '.sum()' to find TOTAL CHARGES for EACH 'Age' or EACH 'Gender':


#GROUP to find 'Median BMI' for each 'Age Group', for 'Each Gender':
df_test3 = df[['Age', 'Gender', 'BMI']]    
df_group3 = df_test3.groupby(['Age', 'Gender'], as_index=False).median()
df_group3.rename(columns = {'BMI': 'Median BMI'}, inplace=True)
print(df_group3.sort_values(by=['Median BMI'], ascending=False))
#Healthy BMI Range is '18.5-24.9'. IF BMI is '30 or Higher', this is OBESE.
#See that a Male, Age 64 has HIGHEST Median BMI at '35.73' = Obsese Range

#Is there a CORRELATION between 'BMI' and 'Age'?
df[['BMI', 'Age']].corr()   #0.113 = WEAK Correlation!
pearson_coeff, p_value = stats.pearsonr(df['BMI'], df['Age'])
print(p_value)    # '2.395e-09' = VERY SMALL p_value, so STRONG CERTAINTY in this RESULT




#      4.  MODEL DEVELOPMENT
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error, r2_score

# Fitting 'SIMPLE' LINEAR REGRESSION:
# - here, using 'Smoker' as 'Predictor Variable', 'Charges' as Y-Variable to PREDICT 
lm = LinearRegression()  #Linear Regression OBJECT
X = df[['Smoker']]
Y = df['Charges']
lm.fit(X,Y)           #'TRAINING' the MODEL
Yhat = lm.predict(X)    #ARRAY for PREDICTED 'prices' (i.e. 'REGRESSION LINE' Data Points)
Yhat[0:5]   #viewing First 5 Elements/Predicted Values
lm.intercept_     #8417.87      
lm.coef_          #23805.27
#'R-Squared':
lm.score(X,Y)   #0.6221  - indicates Pretty GOOD FIT.


# Fitting 'MULTIPLE' Linear Regression: 
#Apart from 'Y' as 'Charges', now have 'ALL COLUMNS' of DataFrame as 'X'
lm_mult = LinearRegression()
Z = df.drop(['Charges','Charges_Binned'], axis=1)
Y = df[['Charges']]
Z.dtypes    #checking to ensure data types are approrpiate for regression analysis
Y.dtypes
#Use 'lm.fit' again (as before)
lm_mult.fit(Z, Y)
#OBTAIN 'ARRAY of PREDICTED' Values (using PREDICTOR VARIABLES in 'Z' Array/DataFrame):
Yhat_mult = lm_mult.predict(Z)  #201 elements of Yhat (SAME as Length of 'PREDICTOR Variables (Z)' Sample)
#Find 'intercept (b0) and 'coefficients' (b1, b2, b3, b4) the SAME WAY:
lm_mult.intercept_    
lm_mult.coef_         
#'R-Squared':
lm_mult.score(Z,Y)    #0.7504  -  BETTER FIT for 'MULTIPLE' Linear Regression.


#Creating 'PIPELINE' to EFFICIENTLY perform SEQUENCE of STEPS:
Input = [('scale', StandardScaler()), ('polynomial', PolynomialFeatures(include_bias = False)), ('model', LinearRegression())]
piped = Pipeline(Input)     # = 'PIPELINE OBJECT'
piped   
#Now 'TRAIN' this PIPELINE OBJECT, FIT 'Z' and 'Y'!
Z - Z.astype("float64")
piped.fit(Z, Y)
ypiped = piped.predict(Z)   # = PREDICTED Y Values 
ypiped[0:10]   #viewing first 10 Predicted Y Values

R_Squared_Piped = r2_score(Y, ypiped)
R_Squared_Piped    # '= 0.84368'  -  EVEN BETTER FIT.



# 5. 'MODEL EVALUATION' and 'REFINEMENT':

#DIVIDE Dataset into 'x_data' and 'y_data' Parameters:
y_data = df['Charges'] 
x_data = df.drop(['Charges', 'Charges_Binned'], axis=1)
#SPLITTING Data so '20%' is used for 'TESTING', '80%' TRAINING:
from sklearn.model_selection import train_test_split
x_train, x_test, y_train, y_test = train_test_split(x_data, y_data, test_size=0.20,random_state=0 )
print(f"Test Samples - {x_test.shape[0]}")       #'555' Samples
print(f"Training Samples - {x_train.shape[0]}")  #'2217' samples

#'RIDGE REGRESSION' Model, for 'Alpha = 0.1':
from sklearn.linear_model import Ridge
RidgeModel = Ridge(alpha = 0.1)
#FITTING to 'TRAINING' Subset
RidgeModel.fit(x_train, y_train)
#Use 'RidgeModel.score()' to find R-squared Value for TESTING Subset:
test_score = RidgeModel.score(x_test, y_test)
test_score             # R-Squared =  '0.747'   
#This is a GOOD FIT and also has 'LESS OVERFITTING', due to use of 'Alpha' HyperParameter.


#Using POLYNOMIAL TRANSFORMATION (degree=2) Instead:
pr = PolynomialFeatures(degree=2)
#POLYNOMIAL TRANSFORM:
x_train_pr=pr.fit_transform(x_train)
x_test_pr=pr.fit_transform(x_test)
#FITTING/'TRAINING' the 'Ridge Regression MODEL'
RidgeModel.fit(x_train_pr,y_train)    
#use 'r2_score(Y, Yhat)', since is 'POLYNOMIAL':
yhat = RidgeModel.predict(x_test_pr)
r_squared_ridge = r2_score(y_test, yhat)
r_squared_ridge    # '= 0.841'   
#VERY GOOD FIT, with LESS OVERFITTING.


#%%