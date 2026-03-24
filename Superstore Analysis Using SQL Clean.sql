-- ============================================
-- SUPERSTORE BUSINESS CASE ANALYSIS
-- Author: Om Kodgire
-- Tool: MySQL Workbench
-- Dataset: Kaggle Superstore (9,994 rows)
-- ============================================

USE superstore;

-- ============================================
-- PHASE 1: EXECUTIVE KPI DASHBOARD
-- Question: What is the overall business health?
-- ============================================

SELECT
    ROUND(SUM(Sales), 2)                        AS total_revenue,
    ROUND(SUM(Profit), 2)                       AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS profit_margin_pct,
    COUNT(DISTINCT `Order ID`)                  AS total_orders,
    COUNT(DISTINCT `Customer ID`)               AS unique_customers
FROM superstore_clean;


-- ============================================
-- PHASE 2: DISCOUNT LEAKAGE ANALYSIS
-- Question: Is discounting destroying profit?
-- ============================================

SELECT
    CASE
        WHEN Discount = 0        THEN '0 - No Discount'
        WHEN Discount <= 0.20    THEN '1 - Low (1-20%)'
        WHEN Discount <= 0.40    THEN '2 - Medium (21-40%)'
        ELSE                          '3 - High (>40%)'
    END                                         AS discount_band,
    COUNT(*)                                    AS order_count,
    ROUND(SUM(Sales), 2)                        AS total_sales,
    ROUND(SUM(Profit), 2)                       AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS avg_margin_pct
FROM superstore_clean
GROUP BY discount_band
ORDER BY discount_band;


-- ============================================
-- PHASE 3: REGIONAL x SEGMENT MATRIX
-- Question: Which markets to invest in or exit?
-- ============================================

SELECT
    Region,
    Segment,
    ROUND(SUM(Sales), 2)                        AS revenue,
    ROUND(SUM(Profit), 2)                       AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS margin_pct,
    COUNT(*)                                    AS total_orders
FROM superstore_clean
GROUP BY Region, Segment
ORDER BY margin_pct DESC;


-- ============================================
-- PHASE 4: PRODUCT SUB-CATEGORY RANKING
-- Question: Which product lines are unprofitable?
-- ============================================

WITH category_stats AS (
    SELECT
        Category,
        `Sub-Category`,
        ROUND(SUM(Sales), 2)                        AS revenue,
        ROUND(SUM(Profit), 2)                       AS profit,
        ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS margin_pct,
        COUNT(*)                                    AS orders
    FROM superstore_clean
    GROUP BY Category, `Sub-Category`
)
SELECT
    Category,
    `Sub-Category`,
    revenue,
    profit,
    margin_pct,
    orders,
    RANK() OVER (PARTITION BY Category ORDER BY profit DESC) AS rank_in_category
FROM category_stats
ORDER BY Category, rank_in_category;


-- ============================================
-- PHASE 5: CUSTOMER RFM SEGMENTATION
-- Question: Who are our most valuable customers?
-- ============================================

WITH rfm_base AS (
    SELECT
        `Customer ID`,
        `Customer Name`,
        MAX(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))  AS last_order_date,
        COUNT(DISTINCT `Order ID`)                  AS frequency,
        ROUND(SUM(Sales), 2)                        AS monetary
    FROM superstore_clean
    GROUP BY `Customer ID`, `Customer Name`
),
rfm_scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY last_order_date DESC)   AS recency_score,
        NTILE(4) OVER (ORDER BY frequency DESC)         AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary DESC)          AS monetary_score
    FROM rfm_base
),
rfm_final AS (
    SELECT *,
        (recency_score + frequency_score + monetary_score) AS rfm_total,
        CASE
            WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Champion'
            WHEN (recency_score + frequency_score + monetary_score) >= 7  THEN 'Loyal'
            WHEN (recency_score + frequency_score + monetary_score) >= 5  THEN 'At Risk'
            ELSE 'Churned'
        END AS customer_segment
    FROM rfm_scored
)
SELECT
    customer_segment,
    COUNT(*)                        AS customer_count,
    ROUND(SUM(monetary), 2)         AS total_revenue,
    ROUND(AVG(monetary), 2)         AS avg_revenue_per_customer,
    ROUND(AVG(frequency), 1)        AS avg_orders
FROM rfm_final
GROUP BY customer_segment
ORDER BY total_revenue DESC;


-- ============================================
-- PHASE 6: SHIPPING OPERATIONS EFFICIENCY
-- Question: Is logistics a hidden profit drain?
-- ============================================

SELECT
    `Ship Mode`,
    COUNT(*)                                        AS total_orders,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),
        STR_TO_DATE(`Order Date`, '%m/%d/%Y')
    )), 1)                                          AS avg_shipping_days,
    ROUND(SUM(Sales), 2)                            AS total_revenue,
    ROUND(SUM(Profit), 2)                           AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)       AS margin_pct,
    ROUND(AVG(Profit), 2)                           AS avg_profit_per_order
FROM superstore_clean
GROUP BY `Ship Mode`
ORDER BY avg_shipping_days;


-- ============================================
-- BONUS: YEAR ON YEAR GROWTH TREND
-- Question: Is the business growing profitably?
-- ============================================

SELECT
    YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))     AS year,
    COUNT(DISTINCT `Order ID`)                      AS total_orders,
    ROUND(SUM(Sales), 2)                            AS revenue,
    ROUND(SUM(Profit), 2)                           AS profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)       AS margin_pct,
    ROUND(SUM(Sales) - LAG(SUM(Sales))
        OVER (ORDER BY YEAR(STR_TO_DATE
        (`Order Date`, '%m/%d/%Y'))), 2)            AS revenue_growth
FROM superstore_clean
GROUP BY year
ORDER BY year;
