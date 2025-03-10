

-- SELECT * FROM city;
-- SELECT * FROM customers;
-- SELECT * FROM products;
-- SELECT * FROM sales;



-- 1. Coffee Consumer Base in Each City
-- Since 25% of a city’s population consumes coffee, how many potential coffee drinkers exist in each location?

Select 
	city_name,
	round((population *0.25)/1000000,2) as coffee_consumers_in_millions,
	city_rank
from city
order by population desc
limit 3;


-- 2. Total Coffee Sales Revenue
-- What was the total revenue generated from coffee sales across all cities in the last quarter of 2023?
	
SELECT
	ci.city_name,
	sum(s.total) as total_revenue
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON c.city_id = ci.city_id
where 
	extract(year from sale_date) = 2023
	and
	extract(quarter from sale_date) = 4
group by 1
order by 2 desc;

--3.  Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT p.product_name,
	count(s.sale_id) as Qty
FROM products p
JOIN sales s
ON p.product_id = s.product_id
group by 1
order by 2 desc;

-- 4. Average Sales Per Customer by City
-- What is the average amount spent per customer in each city?

Select ci.city_name, 
	count(distinct c.customer_id)no_of_customers,
	sum(s.total) as total_sale,
round((sum(s.total)::numeric/count(distinct c.customer_id)::numeric),2) as avg_sale_per_customer
from sales s
join customers c
on s.customer_id = c.customer_id
join city ci
on c.city_id = ci.city_id
group by 1
order by 3 desc;

-- 5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

select ci.city_name, 
round((ci.population *0.25)/1000000,2) estimated_coffee_consumers_in_millions,
count(distinct c.customer_id)
from city ci
join customers c
on ci.city_id = c.city_id
join sales s
on c.customer_id = s.customer_id
group by 1,2
order by 2 desc
;
-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2

) as t1
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customer
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customers,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_customer
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_customer,
	ct.avg_sale_pr_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_customer::numeric
		, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customer,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_customer
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers ,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_customer,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_customers::numeric
		, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC


