CREATE TABLE sales 
LIKE train;
insert sales
select * 
from train;
update sales 
set `Order Date` = str_to_date(`Order Date`,'%d/%m/%Y');
alter table sales 
modify column `Order Date` date;
update sales 
set `Ship Date` = str_to_date(`Ship Date`,'%d/%m/%Y');
alter table sales 
modify column `Ship Date` date;
WITH raw_rfm AS (
    SELECT 
        `Customer ID`, 
        DATEDIFF((SELECT MAX(`Order Date`) FROM sales), MAX(`Order Date`)) AS Recency, 
        COUNT(DISTINCT `Order ID`) AS Frequency, 
        SUM(`Sales`) AS Monetary
    FROM sales
    GROUP BY `Customer ID`
), 
score_rfm AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M
    FROM raw_rfm
),
rfm_scores AS (
    SELECT *, 
        CONCAT(R, F, M) AS RFM_CELL, 
        (R + F + M) / 3 AS Average_score
    FROM score_rfm
)
-- الجزء النهائي للعرض والتصنيف
SELECT *,
    CASE 
        WHEN R = 5 AND F = 5 AND M = 5 THEN 'Champion'
        WHEN R >= 4 AND F >= 4 THEN 'Loyal Customers'
        WHEN R <= 4 AND F = 1 THEN 'New Customers'
        WHEN R <= 2 AND F = 1 THEN 'Lost Customers'
        WHEN R >= 3 AND F >= 3 AND M >= 3 THEN 'Potential Loyalist'
        ELSE 'At Risk'
    END AS Customer_segment
FROM rfm_scores
ORDER BY R DESC, F ASC, M ASC;