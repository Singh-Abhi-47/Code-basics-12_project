-------------------------------------------------1-----------------------------------------------------------------

-- Top 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

SELECT TOP 3 maker, sum(electric_vehicles_sold) as vehicle_count_2_wheeler
FROM electric_vehicle_sales_by_makers
WHERE vehicle_category = '2-Wheelers' and date BETWEEN '2023-04-01' AND '2024-03-31'
GROUP BY maker
ORDER BY vehicle_count_2_wheeler desc

-- Bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

SELECT TOP 3 maker, sum(electric_vehicles_sold) as vehicle_count_2_wheeler
FROM electric_vehicle_sales_by_makers
WHERE vehicle_category = '2-Wheelers' and date BETWEEN '2023-04-01' AND '2024-03-31'
GROUP BY maker
ORDER BY vehicle_count_2_wheeler asc



-------------------------------------------------2-----------------------------------------------------------------
--Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.
-- Penetration Rate =  (Electric Vehicles Sold / Total Vehicles Sold) * 100  


-- We had two seperate names for Andman & Nicobar Island so we made them one
UPDATE electric_vehicle_sales_by_state
SET state = 'Andaman & Nicobar Island'
where state  = 'Andaman & Nicobar'


-- Now let's get the highest pentration rates in 2 wheeler and 4 wheeler EVs
-- 4_WHeeler: 

With CTE_State_4_Wheeler as
(
SELECT 
state,
SUM(electric_vehicles_sold) as Electric_Sum,
SUM(total_vehicles_sold) as Total_sum
FROM electric_vehicle_sales_by_state
WHERE vehicle_category = '4-Wheelers' and date like '2024%'
Group by state
)

Select TOP 5 state, 
FORMAT(((CAST(Electric_Sum as float))*100/ CAST(Total_sum as float)), 'N2') as Penetration_for_4_Wheeler
from CTE_State_4_Wheeler
Order By Penetration_for_4_Wheeler Desc

-- 2_Wheeler

With CTE_State_2_Wheeler as
(
SELECT 
state,
SUM(electric_vehicles_sold) as Electric_Sum,
SUM(total_vehicles_sold) as Total_sum
FROM electric_vehicle_sales_by_state
WHERE vehicle_category = '2-Wheelers' and date like '2024%'
Group by state
)

Select TOP 5 state, 
FORMAT(((CAST(Electric_Sum as float))*100/ CAST(Total_sum as float)), 'N2') as Penetration_for_2_Wheeler
from CTE_State_2_Wheeler
Order By Penetration_for_2_Wheeler Desc




-------------------------------------------------3-----------------------------------------------------------------
--The states with negative penetration (decline) in EV sales from 2022 to 2024?

WITH CTE_2022 AS(
SELECT state, 
sum(electric_vehicles_sold) as EV_Sold_2022,
sum(total_vehicles_sold) as Total_Sold_2022
from electric_vehicle_sales_by_state
where date between '2022-04-01' and '2023-03-31'
group by state	
),
CTE_2024 as(
SELECT state, 
sum(electric_vehicles_sold) as EV_Sold_2024,
sum(total_vehicles_sold) as Total_Sold_2024
from electric_vehicle_sales_by_state
where date between '2023-04-01' and '2024-03-31'
group by state
)


SELECT *
FROM (
    SELECT CTE_2022.state,
           CTE_2022.EV_Sold_2022,
           CTE_2024.EV_Sold_2024,
           (EV_Sold_2024 - EV_Sold_2022) AS GROWTH
    FROM CTE_2022
    JOIN CTE_2024 ON CTE_2022.state = CTE_2024.state
) AS result
WHERE GROWTH < 0
ORDER BY GROWTH


-------------------------------------------------5-----------------------------------------------------------------
-- How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?
-- Penetration Rate =  (Electric Vehicles Sold / Total Vehicles Sold) * 100  

With CTE_PentetrationRateCheck as (
select state, SUM(electric_vehicles_sold) as Total_electric_sold,
SUM(total_vehicles_sold) as Total_vehicle_sold
from electric_vehicle_sales_by_state
where state in ('Delhi', 'Karnataka') and date between '2023-04-01' and '2024-03-31'
group by state
)

select state, Total_electric_sold,
Format((cast(Total_electric_sold as float)*100) / cast(Total_vehicle_sold as float), 'N2') as Penetration_Rate_2024
from CTE_PentetrationRateCheck


-------------------------------------------------6-----------------------------------------------------------------
-- List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.
-- CAGR = [(Ending Value / Beginning Value) ** 1/n] -1


With CTE_begin_value as (
Select maker, SUM(electric_vehicles_sold) as Beginning_Value
from electric_vehicle_sales_by_makers
WHERE vehicle_category = '4-Wheelers' and date between '2022-04-01' and '2023-03-31'
group by maker
),

CTE_end_value as (
Select maker, SUM(electric_vehicles_sold) as Ending_Value
from electric_vehicle_sales_by_makers
WHERE vehicle_category = '4-Wheelers' and date between '2023-04-01' and '2024-03-31' 
group by maker
)


Select TOP 5
	   CTE_begin_value.maker, 
       CTE_begin_value.Beginning_Value, 
       CTE_end_value.Ending_Value,
	   Format(CAST(POWER((CAST(CTE_end_value.Ending_Value AS FLOAT) / CAST(CTE_begin_value.Beginning_Value AS FLOAT)), 0.5) -1 AS FLOAT), 'N2') AS CAGR_by_maker

FROM
CTE_begin_value join CTE_end_value
on CTE_begin_Value.maker = CTE_end_value.maker

Order by CAGR_by_maker desc


-------------------------------------------------7-----------------------------------------------------------------
--List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.

WITH CTE_begin AS (
    SELECT state, SUM(total_vehicles_sold) AS Beginning_Value
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2022-04-01' AND '2023-03-31'
    GROUP BY state
),

CTE_end AS (
    SELECT state, SUM(total_vehicles_sold) AS Ending_Value
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2023-04-01' AND '2024-03-31'
    GROUP BY state
)

SELECT  Top 10
    CTE_begin.state, 
    CTE_begin.Beginning_Value, 
    CTE_end.Ending_Value,
    ROUND((POWER(CAST(CTE_end.Ending_Value AS FLOAT) / CAST(CTE_begin.Beginning_Value AS FLOAT), 0.5) - 1), 4) AS CAGR_by_state
FROM CTE_begin JOIN CTE_end 
ON CTE_begin.state = CTE_end.state
Order by CAGR_by_state desc



-------------------------------------------------9-----------------------------------------------------------------
-- The projected number of EV sales (including 2-wheelers and 4-wheelers) 
-- for the top 10 states by penetration rate in 2030, based on the 
-- compounded annual growth rate (CAGR) from previous years

-- Projected Sales (2030)=EV Sales in Latest Year×(1+CAGR)^(2030−Latest Year)


WITH CTE_Sales_2022 AS (
    SELECT state, 
           SUM(electric_vehicles_sold) AS EV_Sales_2022
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2022-04-01' AND '2023-03-31'
    GROUP BY state
),

CTE_Sales_2024 AS (
    SELECT state, 
           SUM(electric_vehicles_sold) AS EV_Sales_2024
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2023-04-01' AND '2024-03-31'
    GROUP BY state
),

CTE_CAGR AS (
    SELECT 
        CTE_Sales_2022.state,
        CTE_Sales_2022.EV_Sales_2022,
        CTE_Sales_2024.EV_Sales_2024,
        POWER(CAST(CTE_Sales_2024.EV_Sales_2024 AS FLOAT) / CAST(CTE_Sales_2022.EV_Sales_2022 AS FLOAT), 1.0 / 2) - 1 AS CAGR
    FROM CTE_Sales_2022
    JOIN CTE_Sales_2024 
        ON CTE_Sales_2022.state = CTE_Sales_2024.state
),

CTE_Top_States AS (
    SELECT TOP 10 state, EV_Sales_2024, CAGR,
           Round(EV_Sales_2024 * POWER(1 + CAGR, 2030 - 2024), 2) AS Projected_Sales_2030
    FROM CTE_CAGR
    ORDER BY EV_Sales_2024 DESC
)

SELECT *
FROM CTE_Top_States
Order by Projected_Sales_2030 Desc


-------------------------------------------------10----------------------------------------------------------------
-- Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, 
-- assuming an average unit price. H

-- Growth Rate = [(Ending Value - Beginning Value) / Beginning Value] * 100

WITH CTE_2022 AS (
    SELECT vehicle_category,
           SUM(CAST(electric_vehicles_sold AS BIGINT)) AS EV_Sold_2022
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2022-01-01' AND '2022-12-31'
    AND vehicle_category IN ('4-Wheelers', '2-Wheelers')
    GROUP BY vehicle_category
),
CTE_2023 AS (
    SELECT vehicle_category,
           SUM(CAST(electric_vehicles_sold AS BIGINT)) AS EV_Sold_2023
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2023-01-01' AND '2023-12-31'
    AND vehicle_category IN ('4-Wheelers', '2-Wheelers')
    GROUP BY vehicle_category
),
CTE_2024 AS (
    SELECT vehicle_category,
           SUM(CAST(electric_vehicles_sold AS BIGINT)) AS EV_Sold_2024
    FROM electric_vehicle_sales_by_state
    WHERE date BETWEEN '2024-01-01' AND '2024-12-31'
    AND vehicle_category IN ('4-Wheelers', '2-Wheelers')
    GROUP BY vehicle_category
)

SELECT 
    CTE_2022.vehicle_category,
    -- Assigning average prices
    CASE 
        WHEN CTE_2022.vehicle_category = '4-Wheelers' THEN 1500000
        WHEN CTE_2022.vehicle_category = '2-Wheelers' THEN 85000
    END AS avg_unit_price,

    -- Calculating revenue for each year with proper casting
    CAST((CTE_2022.EV_Sold_2022 * 
          CASE 
              WHEN CTE_2022.vehicle_category = '4-Wheelers' THEN 1500000
              WHEN CTE_2022.vehicle_category = '2-Wheelers' THEN 85000
          END) AS BIGINT) AS Revenue_2022,

    CAST((CTE_2023.EV_Sold_2023 * 
          CASE 
              WHEN CTE_2023.vehicle_category = '4-Wheelers' THEN 1500000
              WHEN CTE_2023.vehicle_category = '2-Wheelers' THEN 85000
          END) AS BIGINT) AS Revenue_2023,

    CAST((CTE_2024.EV_Sold_2024 * 
          CASE 
              WHEN CTE_2024.vehicle_category = '4-Wheelers' THEN 1500000
              WHEN CTE_2024.vehicle_category = '2-Wheelers' THEN 85000
          END) AS BIGINT) AS Revenue_2024,

    -- Calculate growth rates safely
    CASE 
        WHEN CTE_2022.EV_Sold_2022 > 0 THEN 
            Round(((CAST(CTE_2024.EV_Sold_2024 AS FLOAT) - CAST(CTE_2022.EV_Sold_2022 AS FLOAT)) * 100.0 / CAST(CTE_2022.EV_Sold_2022 AS FLOAT)), 4)
        ELSE 
            NULL 
    END AS Growth_2022_vs_2024,
    
    CASE 
        WHEN CTE_2023.EV_Sold_2023 > 0 THEN 
            Round(((CAST(CTE_2024.EV_Sold_2024 AS FLOAT) - CAST(CTE_2023.EV_Sold_2023 AS FLOAT)) * 100.0 / CAST(CTE_2023.EV_Sold_2023 AS FLOAT)), 4)
        ELSE 
            NULL 
    END AS Growth_2023_vs_2024

FROM CTE_2022
JOIN CTE_2023 ON CTE_2022.vehicle_category = CTE_2023.vehicle_category
JOIN CTE_2024 ON CTE_2022.vehicle_category = CTE_2024.vehicle_category;



--------------------------------------------------------------------------------------------------------------------
----------------------------------------Prelims Research Done-------------------------------------------------------

select state, sum(electric_vehicles_sold) ev_sold_2021
from 
electric_vehicle_sales_by_state
where date between '2021-04-01' and '2022-03-31'
group by state 
order by ev_sold_2021 desc

select state, sum(electric_vehicles_sold) ev_sold_2022
from 
electric_vehicle_sales_by_state
where date between '2022-04-01' and '2023-03-31'
group by state 
order by ev_sold_2022 desc

select state, sum(electric_vehicles_sold) ev_sold_2023
from 
electric_vehicle_sales_by_state
where date between '2023-04-01' and '2024-03-31'
group by state 
order by ev_sold_2023 desc
