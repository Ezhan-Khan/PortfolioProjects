USE Ecommerce_Dashboard_Analysis;

--viewing to ensure data fields have been correctly imported (from csv):
SELECT TOP(100) *
FROM ecommerce_data
ORDER BY Row_ID;

--How many years does the dataset cover?
SELECT DISTINCT YEAR(Order_Date) AS 'Year'
FROM ecommerce_data
ORDER BY YEAR(Order_Date) ASC;
--dataset covers 2011, 2012, 2013 and 2014 (most recent)
--so will need filters for 'Year' in our dashboard
--from this, can include 'YOY' % growth (comparing current year metrics with previous year values)

--Overall Metrics (KPIs) - Sales, Profit, Quantity, Total Orders, Profit Margin
SELECT ROUND(SUM(sales),2) AS Total_Sales,
       ROUND(SUM(profit),2) AS Total_Profit,
	   SUM(quantity) AS Total_Quantity,
	   COUNT(DISTINCT Order_ID) AS Number_of_Orders,
	   ROUND((SUM(profit)/SUM(sales))*100,2) AS Profit_Margin
FROM ecommerce_data;
-- '$2,297,200.86' total sales
-- '$286,397.02' total profit
-- '37873' total quantity (i.e. units sold)
-- '5009' total orders 
-- '12.47%' profit margin

--Can repeat above, now AGGREGATING for EACH YEAR:
SELECT YEAR(order_date) AS Year,
       ROUND(SUM(sales),2) AS Total_Sales,
       ROUND(SUM(profit),2) AS Total_Profit,
	   SUM(quantity) AS Total_Quantity,
	   COUNT(DISTINCT Order_ID) AS Number_of_Orders,
	   ROUND((SUM(profit)/SUM(sales))*100,2) AS Profit_Margin
FROM ecommerce_data
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);
--could visualize change in sales or profit by year 
-- (using bar chart or line chart if by month instead)

--To make this clearer, could find % of Total Profit made up by EACH YEAR:
SELECT YEAR(order_date) AS Year,
       ROUND(SUM(profit),2) AS Total_Profit,
	   ROUND((SUM(profit) / (SELECT SUM(profit) FROM ecommerce_data))*100,2) AS Percent_of_Total
FROM ecommerce_data
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);
--Good! See a steady increase in profit year by year
--from 17.3% of total in 2011 to 32.65% of total in 2014

-- for 'Year-on-Year Growth' in Profit, can use WINDOWS FUNCTIONS (LAG):
--  '=(current_year_profit - previous_year_profit)/ previous_year_profit'
SELECT YEAR(order_date) AS Year,
       ROUND(SUM(profit),2) AS Total_Profit,
	   ROUND((SUM(profit) - LAG(SUM(profit),1,SUM(profit)) OVER (ORDER BY YEAR(order_date)))     
	   / (LAG(SUM(profit),1,SUM(profit)) OVER (ORDER BY YEAR(order_date))),3)*100 
	   AS 'YOY_Profit'
FROM ecommerce_data
GROUP BY YEAR(order_date);
--from 2013 to 2014, saw a 14.4% growth in profit

--Similarly, can find 'Year-on-Year Growth' in Sales:
SELECT YEAR(order_date) AS Year,
       ROUND(SUM(sales),2) AS Total_Sales,
	   ROUND((SUM(sales) - LAG(SUM(sales),1,SUM(sales)) OVER 
	                        (ORDER BY YEAR(order_date)))     
	   / (LAG(SUM(sales),1,SUM(sales)) OVER 
	     (ORDER BY YEAR(order_date))),3)*100 AS 'YOY_Sales'
FROM ecommerce_data
GROUP BY YEAR(order_date);
--from 2013 to 2014, saw a 20.62% growth in sales

--'Year-on-Year Growth' in Quantity:
SELECT YEAR(order_date) AS Year,
       ROUND(SUM(quantity) ,2) AS Total_Quantity,
	   ROUND(CAST((SUM(quantity)  - LAG(SUM(quantity) ,1,SUM(quantity) ) OVER 
	                        (ORDER BY YEAR(order_date))) AS float)     
	   / CAST(LAG(SUM(quantity) ,1,SUM(quantity) ) OVER 
	     (ORDER BY YEAR(order_date))AS float),3)*100 AS 'YOY_Quantity'
FROM ecommerce_data
GROUP BY YEAR(order_date);
--from 2013 to 2014, saw a 27.5% growth in total 'quantity'

--'Year-on-Year Growth' in # of Orders:
SELECT YEAR(order_date) AS Year,
       ROUND(COUNT(DISTINCT Order_ID),2) AS Total_Orders,
	   ROUND(CAST((COUNT(DISTINCT Order_ID) - LAG(COUNT(DISTINCT Order_ID),1,COUNT(DISTINCT Order_ID)) OVER 
	                        (ORDER BY YEAR(order_date))) AS float)     
	   / CAST(LAG(COUNT(DISTINCT Order_ID),1,COUNT(DISTINCT Order_ID)) OVER 
	     (ORDER BY YEAR(order_date))AS float),3)*100 AS 'YOY_Orders'
FROM ecommerce_data
GROUP BY YEAR(order_date);
--from 2013 to 2014, saw a 29.2% growth in total number of yearly orders 

--'Year-on-Year Growth' in Profit Margin:
SELECT YEAR(order_date) AS Year,
       ROUND((SUM(profit)/SUM(sales))*100,2) AS Profit_Margin,
	   ROUND(CAST(((SUM(profit)/SUM(sales))- LAG((SUM(profit)/SUM(sales)),1,(SUM(profit)/SUM(sales))) OVER 
	                        (ORDER BY YEAR(order_date))) AS float)     
	   / CAST(LAG((SUM(profit)/SUM(sales)),1,(SUM(profit)/SUM(sales))) OVER 
	     (ORDER BY YEAR(order_date))AS float),3)*100 AS 'YOY_Orders'
FROM ecommerce_data
GROUP BY YEAR(order_date);
--from 2013 to 2014, saw a 5.1 decrease in profit margin


--Which State is performing the best in terms of 'Sales'?
--first, can quickly check how many states are within the dataset
SELECT COUNT(DISTINCT State) AS Number_of_States
FROM ecommerce_data;   --49 States

SELECT State, ROUND(SUM(sales),2) AS sales
FROM ecommerce_data
GROUP BY State
ORDER BY 2 DESC;
--California has the most sales, followed by New York and then Texas
--a filled map would visualize this well (i.e. darker fill colour = more sales in that particular state)

--Total Profit by CATEGORY:
SELECT Category, 
       ROUND(SUM(profit), 2) AS Profit,
	   ROUND((SELECT SUM(profit) FROM ecommerce_data),2) AS Grand_Total,
	   ROUND((SUM(profit)/(SELECT SUM(profit) FROM ecommerce_data))*100,2) AS Percent_of_Total
FROM ecommerce_data
GROUP BY Category
ORDER BY 2 DESC;
--see that 50.79% of profit is from Technology Products, 42.77% is from Office Supplies
--only 6.44% of profit is from Furniture

--Total SALES by Category
SELECT Category, 
       ROUND(SUM(sales), 2) AS sales,
	   ROUND((SELECT SUM(sales) FROM ecommerce_data),2) AS Grand_Total,
	   ROUND((SUM(sales)/(SELECT SUM(sales) FROM ecommerce_data))*100,2) AS Percent_of_Total
FROM ecommerce_data
GROUP BY Category
ORDER BY 2 DESC;
--in terms of % Sales, each category (technology, furniture and office supplies) are all fairly close
--Technology makes up 36.4%, Furniture makes up 32.3%, Office Supplies 31.3% of Total Sales

--Total Profit by SUB-CATEGORY (top 5):
SELECT TOP(5) Sub_Category, Category, 
       ROUND(SUM(profit), 2) AS Profit,
	   ROUND((SELECT SUM(profit) FROM ecommerce_data),2) AS Grand_Total,
	   ROUND((SUM(profit)/(SELECT SUM(profit) FROM ecommerce_data))*100,2) AS Percent_of_Total
FROM ecommerce_data
GROUP BY Sub_Category, Category
ORDER BY SUM(profit) DESC;
--'Copiers' make up 19.42% of total profit, followed by Phones (15.54%) and Accessories (14.64%)
--notice that top 3 sub-categories are all in 'Technology' Category (consistent with result from previous query!)


--Now, having explored the data, have an idea what should be visualized in an Ecommerce Sales Dashboard.









