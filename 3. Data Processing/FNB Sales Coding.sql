-- Databricks notebook source
SELECT *
FROM fnb_sales.sales.dataset;

--Checking for duplicate dates
SELECT 
    Date,
    COUNT(*) AS duplicate_count
FROM fnb_sales.sales.dataset
GROUP BY Date
HAVING COUNT(*) > 1;

--Checking for complete duplicates records
SELECT
     Date,
     Sales,
     `Cost Of Sales`,
     `Quantity Sold`,
     COUNT(*) AS duplicate_count
FROM fnb_sales.sales.dataset
GROUP BY 
    Date,
    Sales,
    `Cost Of Sales`,
    `Quantity Sold`
HAVING COUNT(*) > 1; 

--Checking the number of records
SELECT
    COUNT(*)  AS total_records
FROM fnb_sales.sales.dataset;

--Checking for NULL values
SELECT
    COUNT(*) AS total_row,
    COUNT(Date) AS total_date,
    COUNT(Sales) AS total_sales,
    COUNT(`Cost Of Sales`) AS total_cost_of_sales,
    COUNT(`Quantity Sold`) AS total_quantity_sold
FROM fnb_sales.sales.dataset;

--Calculaating total revenue
SELECT Date, 
       ROUND ((Sales/`Quantity Sold`*`Quantity Sold`), 2) AS Revenue
FROM fnb_sales.sales.dataset;

--Checking minimum and maximum values
SELECT
    MIN(Sales) AS min_sales,
    MAX(Sales) AS max_sales,
    MIN(`Cost Of Sales`) AS min_cost_of_sales,
    MAX(`Cost Of Sales`) AS max_cost_of_sales,
    MIN(`Quantity Sold`) AS min_quantity_sold,
    MAX(`Quantity Sold`) AS max_quantity_sold
FROM fnb_sales.sales.dataset;

--Checking for negative values
SELECT
    COUNT(*) AS total_row,
    COUNT(CASE WHEN Sales < 0 THEN 1 END) AS total_negative_sales,
    COUNT(CASE WHEN `Cost Of Sales` < 0 THEN 1 END) AS total_negative_cost_of_sales,
    COUNT(CASE WHEN `Quantity Sold` < 0 THEN 1 END) AS total_negative_quantity_sold
FROM fnb_sales.sales.dataset;

--Checking the average sales price per unit
SELECT
    SUM(Sales) / SUM(`Quantity Sold`) AS average_sales_unit_price
FROM fnb_sales.sales.dataset;

---Compare promotion vs normal period ( 25 August 2015 - 7 September 2015)
WITH promotion AS (

    SELECT
        SUM(Sales) AS total_sales,
        SUM(`Quantity Sold`) AS total_quantity,
        SUM(`Cost Of Sales`) AS total_cost
    FROM fnb_sales.sales.dataset
    WHERE Date BETWEEN '2015-08-25' AND '2015-09-07'
),

normal_period AS (

    SELECT
        SUM(Sales) AS total_sales,
        SUM(`Quantity Sold`) AS total_quantity,
        SUM(`Cost Of Sales`) AS total_cost
    FROM fnb_sales.sales.dataset
    WHERE Date BETWEEN '2015-08-11' AND '2015-08-24'
) 

SELECT
    ROUND(p.total_sales / NULLIF(p.total_quantity, 0), 2) AS promotion_sales_price_per_unit,
    ROUND(n.total_sales / NULLIF(n.total_quantity, 0), 2) AS normal_period_sales_price_per_unit,
    
    p.total_quantity AS promotion_quantity,
    n.total_quantity AS normal_quantity,
    ROUND(p.total_sales, 2) AS promotion_sales,
    ROUND(n.total_sales, 2) AS normal_sales,
    ROUND(p.total_sales - p.total_cost, 2) AS promotion_gross_profit,
    ROUND(n.total_sales - n.total_cost, 2) AS normal_gross_profit
FROM promotion p
CROSS JOIN normal_period n;

--Price Elasticity of Demand
WITH promotion AS (
    SELECT 
        SUM (Sales) / NULLIF(SUM(`Quantity Sold`), 0) AS promotion_price,
        SUM(`Quantity Sold`) AS promotion_quantity
FROM fnb_sales.sales.dataset
WHERE Date BETWEEN '2015-08-25' AND '2015-09-07'
),

normal_period AS (
    SELECT 
        SUM (Sales) / NULLIF(SUM(`Quantity Sold`), 0) AS normal_price,
        SUM(`Quantity Sold`) AS normal_quantity
FROM fnb_sales.sales.dataset
WHERE Date BETWEEN '2015-08-11' AND '2015-08-24'
)

SELECT
    ROUND(promotion_price, 2) AS promotion_price,
    ROUND(normal_price, 2) AS normal_price,
    promotion_quantity,
    normal_quantity,
    ROUND(
        (
            (promotion_quantity - normal_quantity) / NULLIF(promotion_quantity, 0)
        )
        /
        (
            (promotion_price - normal_price) / NULLIF(normal_price, 0)
        ),
        2
        ) AS price_elasticity
FROM promotion
CROSS JOIN normal_period; 
      
WITH daily_metrics AS (

   SELECT
        Date,
        Sales,
        `Cost Of Sales`,
        `Quantity Sold`,

    -- Sales price per unit
    Sales / NULLIF(`Quantity Sold`, 0) AS daily_sales_price_per_unit,

    -- Average sales price per unit
    AVG(Sales / NULLIF(`Quantity Sold`, 0)) OVER() AS average_sales_price_per_unit,
    
    -- Gross profit  
    Sales - `Cost Of Sales` AS gross_profit,

    -- Gross profit %
    (Sales - `Cost Of Sales`) / NULLIF(Sales, 0) * 100 AS daily_gross_profit_percent,

    -- Gross profit per unit
    (Sales - `Cost Of Sales`) / NULLIF(`Quantity Sold`, 0)  AS gross_profit_per_unit

FROM fnb_sales.sales.dataset
)

SELECT
    Date,
    Sales,
    `Cost Of Sales`,
    `Quantity Sold`,
    ROUND(daily_sales_price_per_unit, 2) AS daily_sales_price_per_unit,
    ROUND(average_sales_price_per_unit, 2) AS average_sales_price_per_unit,
    ROUND(gross_profit, 2) AS gross_profit,
    ROUND(daily_gross_profit_percent, 2) AS gross_profit_percent,
    ROUND(gross_profit_per_unit, 2) AS gross_profit_per_unit
FROM daily_metrics
ORDER BY Date;


--Average unit sales price
SELECT
    ROUND(
        SUM(Sales) / NULLIF(SUM(`Quantity Sold`), 0),
        2
    ) AS Average_Unit_Sales_Price

FROM fnb_sales.sales.dataset;

--Daily % gross profit
SELECT
    Date,
    ROUND(
        SUM(Sales - `Cost Of Sales`) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Daily_Gross_Profit_Percent
FROM fnb_sales.sales.dataset
GROUP BY Date
ORDER BY Date;

--Daily gross profit per unit
SELECT
    Date,
    ROUND(
        (
            (sales / NULLIF(`Quantity Sold`, 0))
            -
            (`Cost Of Sales` / NULLIF(`Quantity Sold`, 0))
        )
        / NULLIF(
            sales / NULLIF(`Quantity Sold`, 0),
            0
        ) * 100,
        2    
    ) AS gross_profit_per_unit_percent
FROM fnb_sales.sales.dataset
ORDER BY Date;

   


