/*As outlined in documentation,   
  need to join tables from the 'BikeStores' Database 
  to obtain relevant data only:
  (orderID, customer first/last name, customer city and state, 
  order date, sales volume (total units), revenue, 
  product name, product category, 
  brand name, store name, sales rep)
  This Database uses 'SCHEMAS' to logically group the Tables by 'production' or 'sales' 
  (just keeps it organized and clear when joining)
*/

SELECT o.order_id, 
       o.order_date,   
       CONCAT(c.first_name, ' ',c.last_name) AS customer_name,
	   c.city,
	   c.state,
	   --Sales Volume = Total Quantity, Revenue = TOTAL of 'quantity * list_price' (just need to GROUP by all other columns)
	   SUM(oi.quantity) AS 'total_units',
	   SUM(oi.quantity*oi.list_price) AS 'revenue',
	   --product_name is found in production.products table
	   p.product_name,
	   --category is found in production.categories
	   cat.category_name AS product_category,
	   --brands are found in production.brands
	   b.brand_name,
	   --store_name is found in sales.stores
	   st.store_name,
	   --Sales Rep 'first and last names' are given in 'sales.staffs' table. Will need to CONCAT these 2 fields together
       CONCAT(stf.first_name, ' ', stf.last_name) AS sales_rep
FROM sales.orders AS o
JOIN sales.customers AS c
ON o.customer_id = c.customer_id
JOIN sales.order_items AS oi
ON o.order_id = oi.order_id
JOIN production.products AS p
ON oi.product_id = p.product_id
JOIN production.categories AS cat
ON p.category_id = cat.category_id
JOIN production.brands AS b
ON p.brand_id = b.brand_id
JOIN sales.stores AS st
ON o.store_id = st.store_id 
JOIN sales.staffs AS stf
ON o.staff_id = stf.staff_id
--since used aggregate functions for some calculations, need to GROUP BY the other fields:
GROUP BY o.order_id,   
         CONCAT(c.first_name, ' ',c.last_name),
	     c.city,
	     c.state,
		 o.order_date,
		 p.product_name,
	     cat.category_name,
		 b.brand_name,
		 st.store_name,
		 CONCAT(stf.first_name, ' ', stf.last_name) 
;
--this has created a data table which contains ALL data needed for analysis!


--Now, will perform Analysis in SQL (as alternative to Pivot Tables in Excel)
--the above query result was imported into excel. Now, could simply import it BACK INTO SQL as a NEW TABLE in the BikeStores Database, then perform analysis on that table.
--OR could create a TEMP TABLE from the above result, so it can be queried further (this is the better option):
DROP TABLE IF EXISTS #bikestore_data;
CREATE TABLE #bikestore_data (
order_id int,
order_date date,
customer_name varchar(100),
city varchar(100),
state varchar(100),
total_units int,
revenue float,
product_name varchar(100), 
product_category varchar(100),
brand_name varchar(100),
store_name varchar(100),
sales_rep varchar(100)
);
INSERT INTO #bikestore_data
SELECT o.order_id, 
       o.order_date,   
       CONCAT(c.first_name, ' ',c.last_name) AS customer_name,
	   c.city,
	   c.state,
	   --Sales Volume = Total Quantity, Revenue = TOTAL of 'quantity * list_price' (just need to GROUP by all other columns)
	   SUM(oi.quantity) AS 'total_units',
	   SUM(oi.quantity*oi.list_price) AS 'revenue',
	   --product_name is found in production.products table
	   p.product_name,
	   --category is found in production.categories
	   cat.category_name AS product_category,
	   --brands are found in production.brands
	   b.brand_name,
	   --store_name is found in sales.stores
	   st.store_name,
	   --Sales Rep 'first and last names' are given in 'sales.staffs' table. Will need to CONCAT these 2 fields together
       CONCAT(stf.first_name, ' ', stf.last_name) AS sales_rep
FROM sales.orders AS o
JOIN sales.customers AS c
ON o.customer_id = c.customer_id
JOIN sales.order_items AS oi
ON o.order_id = oi.order_id
JOIN production.products AS p
ON oi.product_id = p.product_id
JOIN production.categories AS cat
ON p.category_id = cat.category_id
JOIN production.brands AS b
ON p.brand_id = b.brand_id
JOIN sales.stores AS st
ON o.store_id = st.store_id 
JOIN sales.staffs AS stf
ON o.staff_id = stf.staff_id
--since used aggregate functions for some calculations, need to GROUP BY the other fields:
GROUP BY o.order_id,   
         CONCAT(c.first_name, ' ',c.last_name),
	     c.city,
	     c.state,
		 o.order_date,
		 p.product_name,
	     cat.category_name,
		 b.brand_name,
		 st.store_name,
		 CONCAT(stf.first_name, ' ', stf.last_name) 
;
--checking that temp table is correct:
SELECT *
FROM #bikestore_data;


                      /*  Exploratory Data Analysis  */
--Finding Total Revenue by Year:
SELECT YEAR(order_date) AS 'Year', ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY YEAR(order_date)
ORDER BY 1;
--from this, will create a bar chart, showing total revenue in each year category

--Total Revenue by Year AND Month:
SELECT YEAR(order_date) AS 'Year', 
       MONTH(order_date) AS 'Month',
       ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY 1, 2;
--from this, can produce a line chart, showing change in total revenue BY month, with separate plots for each respective year

-- Revenue by 'State':
SELECT state, ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY state
ORDER BY 2 DESC;
--Customers appear to be soley located in New York, California and Texas.
--New York makes up most of the overall revenue.
--this will ultimately be visualized in a Map Chart in Tableau

--Revenue for each 'Store':
SELECT store_name, ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY store_name
ORDER BY 2 DESC;
--for our 3 stores (Baldwin Bikes, Santa Cruz Bikes and Rowlett Bikes)
--see that 'Baldwin Bikes' appears to have highest revenue
--can make a Pie Chart, showing % of Total Revenue generated by EACH Store

--Revenue for each 'Brand':
SELECT brand_name, ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY brand_name
ORDER BY 2 DESC;
--out of the 9 brands, 'Trek' generates the most revenue compared to the rest
--this data can be visualized as a horizontal bar chart

--Revenue for each 'Product Category':
SELECT product_category, ROUND(SUM(revenue), 2) AS 'Revenue'
FROM #bikestore_data
GROUP BY product_category
ORDER BY 2 DESC;
--out of the 7 different types of bikes, 'Mountain Bikes' are generating a lot of revenue
--alternatively, could see which product category is MOST POPULAR (has most units sold)
SELECT product_category, SUM(total_units) AS 'Units_Sold'
FROM #bikestore_data
GROUP BY product_category
ORDER BY 2 DESC;
--while 'Mountain Bikes' generate the most profit, 'Cruiser Bicycles' are most popular (with most units sold)
--this data is also best visualized as a horizontal bar chart (since have quite a few categories, would look neater with horizontal bars)

--Which 'Customers' give the highest revenue (top 10)?
SELECT TOP(10) customer_name AS 'Customer', ROUND(SUM(revenue),2) AS 'Revenue'
FROM #bikestore_data
GROUP BY customer_name
ORDER BY 2 DESC;
--see that 'Pamella Newman' is giving us the most revenue, closely followed by Abby Gamble and Sharyn Hopkins.
--best visualized as a horizontal bar chart

--Similarly, which 'Sales Reps' give the highest revenue (top 10)?
SELECT TOP(10) sales_rep AS 'sales_rep', ROUND(SUM(revenue),2) AS 'Revenue'
FROM #bikestore_data
GROUP BY sales_rep
ORDER BY 2 DESC;
--see that 'Marcelene Boyer' is giving us the most revenue, closely followed by Venta Daniel and then Genna Serrano.
--again, can be visualized as a horizontal bar chart

--All 8 Visualizations can be presented within a Sales Dashboard 
--important to include FILTERS (time-series filter for Year, State, Store...)
--also can add interactivity to CLICK (or hover) to filter, as another option!





