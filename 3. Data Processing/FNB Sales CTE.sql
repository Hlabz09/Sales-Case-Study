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

-- Calculating metrics for each period
WITH period_metrics_big AS (
  SELECT 
    CASE
      WHEN Date BETWEEN '2013-12-30' AND '2014-01-07' THEN 'Promotion_1'
      WHEN Date BETWEEN '2014-02-07' AND '2014-02-17' THEN 'Promotion_2'
      WHEN Date BETWEEN '2014-02-21' AND '2014-03-17' THEN 'Promotion_3'
      WHEN Date BETWEEN '2014-04-10' AND '2014-04-22' THEN 'Promotion_4'
      ELSE 'Baseline'
    END AS Period_Key,
    AVG(Sales / `Quantity Sold`) AS Avg_Unit_Price,
    AVG(`Quantity Sold`) AS Avg_Quantity_Sold
  FROM fnb_sales.sales.dataset
  GROUP BY 
    CASE
      WHEN Date BETWEEN '2013-12-30' AND '2014-01-07' THEN 'Promotion_1'
      WHEN Date BETWEEN '2014-02-07' AND '2014-02-17' THEN 'Promotion_2'
      WHEN Date BETWEEN '2014-02-21' AND '2014-03-17' THEN 'Promotion_3'
      WHEN Date BETWEEN '2014-04-10' AND '2014-04-22' THEN 'Promotion_4'
      ELSE 'Baseline'
    END
),

-- Getting baseline metrics
baseline_big AS (
  SELECT 
    Avg_Unit_Price AS Baseline_Price,
    Avg_Quantity_Sold AS Baseline_Quantity
  FROM period_metrics_big
  WHERE Period_Key = 'Baseline'
),

-- Calculating Price Elasticity of Demand (PED) for each period
elasticity_by_period AS (
  SELECT 
    pm.Period_Key,
    ROUND(
      ((pm.Avg_Quantity_Sold - b.Baseline_Quantity) / b.Baseline_Quantity) / 
      ((pm.Avg_Unit_Price - b.Baseline_Price) / b.Baseline_Price)
    , 2) AS Price_Elasticity_of_Demand
  FROM period_metrics_big pm
  CROSS JOIN baseline_big b
  WHERE pm.Period_Key != 'Baseline'
)

-- Building the main query with all metrics
SELECT 
       d.Date,
       YEAR(d.Date) AS Transaction_year,
       DATE_FORMAT(d.Date, 'MMMM') AS Transaction_month,
       DATE_FORMAT(d.Date, 'dd') AS Transaction_day,
       DAYNAME(d.Date) AS Transaction_dayname,
       ROUND((d.`Quantity Sold`), 2) AS `Quantity Sold`,
       ROUND((d.Sales), 2) AS Sales,

       -- Daily sales price per unit
       ROUND((d.Sales / d.`Quantity Sold`), 2) AS `Daily Sales Price Per Unit`,

       -- Average sales price per unit: simple average of the daily unit prices (whole dataset)
       ROUND(AVG(d.Sales / d.`Quantity Sold`) OVER (), 2) AS `Average Sales Price Per Unit`,

       -- Average sales price per unit: weighted (total sales / total quantity, whole dataset)
       ROUND(SUM(d.Sales) OVER () / SUM(d.`Quantity Sold`) OVER (), 2) AS `Weighted Average Sales Price Per Unit`,

       -- Average sales price per unit within the same promotion period
       ROUND(AVG(d.Sales / d.`Quantity Sold`) OVER (
           PARTITION BY CASE
               WHEN d.Date BETWEEN '2013-12-30' AND '2014-01-07' THEN 'Promotion period 1'
               WHEN d.Date BETWEEN '2014-02-07' AND '2014-02-17' THEN 'Promotion period 2'
               WHEN d.Date BETWEEN '2014-02-21' AND '2014-03-17' THEN 'Promotion period 3'
               WHEN d.Date BETWEEN '2014-04-10' AND '2014-04-22' THEN 'Promotion period 4'
               ELSE 'Non Promotion'
           END
       ), 2) AS `Average Sales Price Per Unit (Period)`,

       ROUND((d.`Cost Of Sales`), 2) AS `Cost Of Sales`,
       ROUND((d.Sales - d.`Cost Of Sales`), 2) AS `Daily Gross Profit`,
       ROUND(((d.Sales - d.`Cost Of Sales`) / d.Sales) * 100, 2) AS `Daily % Gross Profit`,
       ROUND(((d.Sales - d.`Cost Of Sales`) / d.`Quantity Sold`) / (d.Sales / d.`Quantity Sold`) * 100, 2) AS `Daily % Gross Profit Per Unit`,

       CASE 
           WHEN (d.Sales / d.`Quantity Sold`) < 37.07 * 0.90 THEN 'Promotion'
           ELSE 'Non-promotion'
       END AS `Promotion Status`,
       CASE
           WHEN d.Date BETWEEN '2013-12-30' AND '2014-01-07' THEN 'Promotion period 1'
           WHEN d.Date BETWEEN '2014-02-07' AND '2014-02-17' THEN 'Promotion period 2'
           WHEN d.Date BETWEEN '2014-02-21' AND '2014-03-17' THEN 'Promotion period 3'
           WHEN d.Date BETWEEN '2014-04-10' AND '2014-04-22' THEN 'Promotion period 4'
           ELSE 'Non Promotion'
       END AS `Promotion Period`,
       e.Price_Elasticity_of_Demand AS `Price Elasticity of Demand`,
       ROUND(LAG(d.Sales - d.`Cost Of Sales`) OVER (ORDER BY d.Date), 2) AS previous_gross_profit,
       ROUND((d.Sales - d.`Cost Of Sales`) - LAG(d.Sales - d.`Cost Of Sales`) OVER (ORDER BY d.Date), 2) AS gross_profit_change,
       CASE
           WHEN (d.Sales - d.`Cost Of Sales`) > LAG(d.Sales - d.`Cost Of Sales`) OVER (ORDER BY d.Date) THEN 'Growth'
           WHEN (d.Sales - d.`Cost Of Sales`) < LAG(d.Sales - d.`Cost Of Sales`) OVER (ORDER BY d.Date) THEN 'Decline'
           ELSE 'No Change'
       END AS gross_profit_indicator
FROM fnb_sales.sales.dataset d
LEFT JOIN elasticity_by_period e
  ON CASE
       WHEN d.Date BETWEEN '2013-12-30' AND '2014-01-07' THEN 'Promotion_1'
       WHEN d.Date BETWEEN '2014-02-07' AND '2014-02-17' THEN 'Promotion_2'
       WHEN d.Date BETWEEN '2014-02-21' AND '2014-03-17' THEN 'Promotion_3'
       WHEN d.Date BETWEEN '2014-04-10' AND '2014-04-22' THEN 'Promotion_4'
     END = e.Period_Key
ORDER BY d.Date;
