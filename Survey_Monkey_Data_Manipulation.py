
#'Pandas' is most important library when working with Structured Data
#useful for data manipulation and transformation of DataFrames
import pandas as pd
import os
import numpy as np

#Important to ORGANIZE VIRTUAL ENVIRONMENT for specific projects
#(why? - AVOID any COMPATABILITY ISSUES in future)
#use 'getcwd' to GET the CURRENT WORKING DIRECTORY (Folder) so this is SAVED as a 'Present-Working-Directory' (pwd) string
#makes it easier WHEN MOVING Files to different directories, so STAYS as CURRENT WORKING
pwd = os.getcwd()
print(pwd)    # "C:\Users\Ezhan Khan"
#(just another way to get the working directory than just manually copying and pasting it!)

df = pd.read_csv(r"C:\Users\Ezhan Khan\Documents\CAPSTONE PROJECTS\Survey_Monkey_Data_Manipulation\Survey_Monkey_Output_CSV.csv")
df = pd.read_csv(f"{pwd}\Survey_Monkey_Output_CSV.csv")
df.head()
df.shape #dataset contains 198 rows, 100 columns

#As we want to change data, created a copy which can be modified:
df_modified = df

#Viewing Columns in the dataset:
df_modified.columns

#Want to DROP SOME Columns - Start Date, End Date, Email, First and Last Name and Custom Date
df_modified.drop(columns = ['Start Date', 'End Date', 'Email Address',
       'First Name', 'Last Name', 'Custom Data 1'], axis = 1, inplace=True)
df_modified.columns  #above columns have been dropped now


#            Now will UNPIVOT the Data (turn into LONG DATA)
#Need a method called '.melt()':
#(note - mark of a good developer/programmer is knowing what to look up and when - dont have to memorize everything)
#         ' df.melt(id_vars, value_vars, var_name, value_name) '
# id_vars = identifier variables (these are kept AS IS)
# value_vars = what variables to UNPIVOT (becomes LONG Data)
#(great documentation for 'Pandas' on their website)

#Copy 'df.columns' for first 8 columns into a list - this will become 'Demographics' Column
id_vars = list(df_modified.columns[:8])
id_vars # 'list()' converts from 'index' into a 'list'
#Now, for 'value_vars' want to UNPIVOT All 'QUESTIONS' (1 Column contains QUESTIONS, Another contains ALL ANSWERS):
value_vars = list(df_modified.columns[8:])
value_vars
#Now, can add NAMES for 'Variable' Column = QUESTIONS (and Subquestions) and 'Value' Column = ANSWERS
#given by 'var_name' and 'value_name'

df_melted = df_modified.melt(id_vars=id_vars, 
                             value_vars = value_vars,
                             var_name = "Question and Subquestion", 
                             value_name = "Answer")


#ALSO NEED - 'Question' Column (original question) and 'Total Respondents' Column (=HOW MANY people RESPONDED to a QUESTION)
#'Question' can be added using a 'JOIN'
#IMPORT IN Excel Sheet (as CSV) containing QUESTIONS (= sheet where we merged the 2 headers into one):
questions_import = pd.read_csv(r"C:\Users\Ezhan Khan\Documents\CAPSTONE PROJECTS\Survey_Monkey_Data_Manipulation\Questions_Sheet.csv")

questions = questions_import  #create copy (as usual)
#Drop unecessary columns, only keep 'Question' and 'Question + Subquestion' Columns
questions.columns
questions.drop(columns = ['Raw Question', 'Subquestion','Subquestion2','Text Col' ], axis = 1, inplace=True)
questions

#To JOIN 'questions' WITH 'df_melted', use MERGE METHOD:
df_merged = pd.merge(left = df_melted, right = questions, how='left', left_on ='Question and Subquestion' , right_on="Question + Subquestion")
#Note - ALWAYS CHECK NUMBER OF ROWS NEEDED at END of JOIN is CORRECT - EASY MISTAKE to MAKE! (i.e. ensure correct number of rows after joining!)
print(f"Original Data: {len(df_melted)}")
print(f"Merged Data: {len(df_merged)}")  #SAME LENGTH! Both 17028 - GOOD!


#Now, want to find 'Total Respondents' using GROUP BY:
#So GROUPED BY the 'Question' Column, want TOTAL (COUNT) of Respondents
responders = df_merged.groupby(['Question'])['Respondent ID'].count().reset_index()
responders
#here, specified .groupby([column_to_groupby])['aggregate_column'].count()
#Use '.reset_index()' to CONVERT from series to DATAFRAME again
#(otherwise, will return SERIES with 'Question' as INDEX and COUNT of 'Answer' for EACH 'Question' as the Column)

#WRONG VALUES! Try again - this time using 'nunique()' ()
df_merged.groupby(['Question'])['Respondent ID'].nunique().reset_index()
#get '198' for EACH value - WRONG! Some Respondents did NOT answer certain questions

#Instead, FIND ALL values in 'Answer' Column which are 'NOT NULL':
respondents = df_merged[df_merged['Answer'].notnull()]
respondents   #just FILTERED to ONLY get ROWS where 'Answer' is NOT NULL
total_respondents = respondents.groupby('Question')['Respondent ID'].nunique().reset_index()
#GOOD!

#Will JOIN 'total_respondents' WITH 'df_merged' (same as above!)
#Can JOIN ON 'Question' Column - FIRST, must RENAME 'Respondent ID' in 'total_respondents' - otherwise get 2 versions 'x' and 'y' of Respondent ID, which we DONT WANT!!
total_respondents.rename(columns = {"Respondent ID":"Respondents"}, inplace=True)
total_respondents
#JOIN on 'Question' (so for EACH QUESTION, want Number of RESPONDENTS)
df_merged_2 = pd.merge(left = df_merged, right = total_respondents, how='left', left_on ='Question' , right_on="Question")
print(f"Original Data: {len(df_merged)}")
print(f"Merged Data: {len(df_merged_2)}")  #SAME LENGTH! Both 17028 - GOOD!
df_merged_2


#HOW MANY people (COUNT) answered the SAME ANSWER PER QUESTION?
#  - so GROUP BY 'Question and Subquestion' AND 'Answer' to get COUNT for that
same_answer= df_merged  #[df_merged['Answer'].notnull()]
same_answer #just FILTERED to ONLY get ROWS where 'Answer' is NOT NULL
same_answer = same_answer.groupby(['Question and Subquestion', 'Answer'])['Respondent ID'].nunique().reset_index()
#so, for EACH 'Question + Subquestion' and EACH 'Answer', COUNT the number of RESPONDENTS

#Again, rename 'Respondent ID' to something else (before JOIN:
same_answer.rename(columns = {"Respondent ID":"Same Answer"}, inplace=True)
same_answer

#JOIN ON 'Question and Subquestion' and 'Answer' Columns
df_merged_3 = pd.merge(left = df_merged_2, right = same_answer, how='left', left_on =['Question and Subquestion', 'Answer'] , right_on=['Question and Subquestion', 'Answer'])
print(f"Original Data: {len(df_merged_2)}")
print(f"Merged Data: {len(df_merged_3)}")  #SAME LENGTH! Both 17028 - GOOD!
df_merged_3

#FILL IN 'NaN' (null) values for 'Same Answer' Column with '0'
df_merged_3['Same Answer'].replace(np.nan, 0, inplace=True)



#FINAL STEP? - RENAME the Column Headers so they are more MEANINGFUL and SIMPLER!
df_merged_3.columns
output = df_merged_3
output.rename(columns = {'Identify which division you work in - Response':'Division Primary', 'Identify which division you work in - Other (please specify)':'Division Secondary', 'Which of the following best describes your position level? - Response': 'Position', 'Which generation are you apart of? - Response' : 'Generation', 'Please select the gender in which you identify - Response': 'Gender', 'Which duration range best aligns with your tenure at your company? - Response':'Tenure', 'Which of the following best describes your employment type? - Response': 'Employment Type'}, inplace=True)

#All done! Now simply LOAD this DataFrame to a CSV or EXCEL file!
output.to_csv('Survey_Monkey_Final_Output.csv', index = False)








#%%