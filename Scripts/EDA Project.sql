/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'D:\my personal things\Ultimate SQL\SQL Projects\SQL EDA Project\sql-data-analytics-project\Project Materials\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'D:\my personal things\Ultimate SQL\SQL Projects\SQL EDA Project\sql-data-analytics-project\Project Materials\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'D:\my personal things\Ultimate SQL\SQL Projects\SQL EDA Project\sql-data-analytics-project\Project Materials\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO


-- Explore all objects in the Database
select * from Information_schema.TABLES


-- Explore all columns in the database
select * from INFORMATION_SCHEMA.columns

-- Checking dimensions
select distinct country from gold.dim_customers


-- Date Exploration
-- Find the date of first and last order
-- How many years of sales are available
select 
min(order_date) as first_order_date,
max(order_date) as last_order_date,
DATEDIFF(year, min(order_date), max(order_date)) as order_range_years
from gold.fact_sales
-- Find the youngest and oldest customer
select 
min(birthdate) as oldest_birthdate,
DATEDIFF(year, min(birthdate), getdate()) as oldest_age,
max(birthdate) as youngest_birthdate,
DATEDIFF(year, max(birthdate), getdate()) as youngest_age
from gold.dim_customers

-- Measures Exploration

-- Find the total sales
select sum(sales_amount) as total_sales from gold.fact_sales
-- Find the average selling price
select avg(price) as avg_price from gold.fact_sales
-- Find the total Number of orders
select COUNT(order_number) as total_orders from gold.fact_sales
select COUNT(distinct order_number) as total_distinct_orders from gold.fact_sales
-- Find the total number of customers
select count(customer_key) as total_customers from gold.dim_customers
-- Find the total number of customers that has placed an order
select count(distinct customer_key) as total_customers_Orders from gold.fact_sales

-- Generate a report that shows all key metrics of the business
select 'Total Sales' as measure_name , sum(sales_amount) as measure_value from gold.fact_sales
union all 
select 'Total Quantity', sum(quantity) from gold.fact_sales
union all
select 'Average price', avg(price) from gold.fact_sales
union all
select 'Total No Orders', count(distinct order_number) from gold.fact_sales
union all
select 'Total No Products', count(product_name) from gold.dim_products
union all
select 'Total Nr. Customers', count(customer_key) from gold.dim_customers

-- Magnitude analysis


-- Find total customers by countries
select 
country,
count(customer_key) as total_customers
from gold.dim_customers
group by country
order by total_customers desc
-- Find the total customers by gender
select 
gender,
count(customer_key) as total_customers
from gold.dim_customers
group by gender
order by total_customers desc
-- Find the total products by category
select
category,
count(product_key) as total_products
from gold.dim_products
group by category
order by total_products desc
-- what is the average cost in each category
select
category,
avg(cost) as avg_cost
from gold.dim_products
group by category
order by avg_cost desc
-- what is the total revenue generated for each category?
select 
p.category,
sum(f.sales_amount) total_revenue
from gold.fact_sales f
left join gold.dim_products p
on p.product_key = f.product_key
group by p.category
order by total_revenue desc
-- what is the total revenue generated by each customer
select 
c.customer_key,
c.first_name,
c.last_name,
sum(f.sales_amount) as total_revenue
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
group by 
	c.customer_key,
	c.first_name,
	c.last_name
order by total_revenue desc
-- what is the distribution of sold itmes across countries?
select 
c.country,
sum(f.quantity) as total_sold_items
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
group by country
order by total_sold_items desc

-- Ranking analysis

-- 1. which 5 products generate the highest revenue
select top 5
p.product_name,
sum(f.sales_amount) total_revenue
from gold.fact_sales f
left join gold.dim_products p
on p.product_key = f.product_key
group by p.product_name
order by total_revenue desc

-- Using window functions
select *
from 
(select 
	p.product_name,
	sum(f.sales_amount) total_revenue,
	rank() over(order by sum(f.sales_amount) desc) as rank_products
from gold.fact_sales f
left join gold.dim_products p
on p.product_key = f.product_key
group by p.product_name)t
where rank_products <= 5


-- 1. which 5 products generate the worst revenue
select * from 
(select 
	p.product_name,
	sum(f.sales_amount) total_revenue,
	rank() over(order by sum(f.sales_amount)) as rank_products
from gold.fact_sales f
left join gold.dim_products p
on p.product_key = f.product_key
group by p.product_name)t
where rank_products <= 5

-- Find the top 10 customers who have generated the highest revenue
select top 10
c.customer_key,
c.first_name,
c.last_name,
sum(f.sales_amount) as total_revenue
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
group by c.customer_key,
c.first_name,
c.last_name
order by total_revenue desc
-- The 3 customers with the fewest orders placed
select top 3
c.customer_key,
c.first_name,
c.last_name,
count(distinct order_number) as total_orders
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
group by c.customer_key,
c.first_name,
c.last_name
order by total_orders








































































