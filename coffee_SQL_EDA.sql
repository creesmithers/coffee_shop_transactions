-- CREATE SCHEMA coffee_sales;
USE coffee_sales;

-- CREATE TABLE coffee (
-- 	id INT AUTO_INCREMENT PRIMARY KEY,
-- 	hour_of_day INT,
--     cash_type VARCHAR(20),
--     money DECIMAL(10,2),
--     coffee_name VARCHAR(20),
--     time_of_day VARCHAR(20),
--     weekday VARCHAR(20),
--     month_name VARCHAR(20),
--     weekday_sort INT,
--     month_sort INT,
--     date DATE,
--     time TIME(6)
-- );

-- insert data
-- LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Coffee_sales.csv'
-- INTO TABLE coffee
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (hour_of_day, cash_type, money, coffee_name, time_of_day, weekday, month_name, weekday_sort, month_sort, date, time);

SELECT COUNT(*)
FROM coffee;

-- check for missing values?
SELECT 
  COUNT(*) AS total_rows,
  COUNT(*) - COUNT(coffee_name) AS missing_coffee_name,
  COUNT(*) - COUNT(money) AS missing_money,
  COUNT(*) - COUNT(weekday_sort) AS missing_weekday_sort
FROM coffee;

SELECT 
	weekday_sort, 
	sum(money)
FROM coffee
GROUP BY weekday_sort;
-- top selling days are Fri-Sun



-- check timing for top sales
SELECT
	COUNT(*) as total_sales,
	weekday_sort,
    time_of_day
FROM coffee
GROUP BY weekday_sort, time_of_day
ORDER BY total_sales DESC
LIMIT 8;
-- top: Tuesday morning 207
-- Tuesday night 205
-- Thurs Night 195
-- Saturday Afternoon 194
-- Fri Morning 193
-- Monday Morning 193

-- This makes me wonder over how long the dataset took palce
SELECT
	MIN(date), 
    MAX(date)
FROM coffee;
-- It's March 1, 2024 through Mar 23, 2025. So takes place for over a whole year. 

-- Biggest driver is always sales
SELECT 
	coffee_name, 
	sum(money) AS total_sales
FROM coffee
WHERE weekday_sort IN (5, 6, 7)
	-- only include Fri, Sat, Sun
GROUP BY coffee_name
	-- group by coffee_name to see top selling coffee
ORDER BY total_sales DESC;
-- top selilng on weekends are Lattes and Americano with milk

SELECT 
	coffee_name, 
    time_of_day, 
    sum(money) as total_sales
FROM coffee
WHERE weekday_sort IN (5, 6, 7)
	-- only include Fri, Sat, Sun
GROUP BY coffee_name, time_of_day
	-- to see when to maximize staffing look for latte/Americano with milk then time of day
ORDER BY total_sales DESC;
-- afternoon by far the top



-- Last thing to check before export. of the most popular times, what are most popular drinks? 
-- If it's something easy like a drip or cold brew we don't need many staff. 

WITH top_slots AS (
	SELECT weekday_sort, time_of_day
    FROM coffee
    GROUP BY weekday_sort, time_of_day
    HAVING COUNT(*) >= 193),
slot_drink_counts AS (
	SELECT
		c.weekday_sort,
        c.time_of_day,
        c.coffee_name,
        COUNT(*) AS order_count
	FROM coffee c
    JOIN top_slots t 
		ON c.weekday_sort = t.weekday_sort AND c.time_of_day = t.time_of_day
	GROUP BY c.weekday_sort, c.time_of_day, c.coffee_name),
ranked AS(
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY weekday_sort, time_of_day
        ORDER BY order_count DESC) as rnk
	FROM slot_drink_counts)
SELECT weekday_sort, time_of_day, coffee_name, order_count
FROM ranked
where rnk = 1
ORDER BY weekday_sort, time_of_day;
