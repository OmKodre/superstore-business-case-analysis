CREATE DATABASE superstore;
USE superstore;
select * from superstore_clean 

show tables 
-- Check row count
SELECT COUNT(*) FROM superstore_clean;
-- Check column names
DESCRIBE superstore_clean;
-- Preview first 5 rows
SELECT * FROM superstore_clean LIMIT 5; 
 
# 1 How is the business doing?
	-- SUM(Sales) → total revenue the business generated
	-- 	SUM(Profit) → how much actually remained after costs
	-- 	Profit / Sales * 100 → margin percentage — the most critical health metric
	-- 	COUNT(DISTINCT Order ID) → how many unique transactions
	-- 	COUNT(DISTINCT Customer ID) → how many unique customers served
    
SELECT
    ROUND(SUM(Sales), 2)                        AS total_revenue,
    ROUND(SUM(Profit), 2)                       AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS profit_margin_pct,
    COUNT(DISTINCT `Order ID`)                  AS total_orders,
    COUNT(DISTINCT `Customer ID`)               AS unique_customers
FROM superstore_clean; 



# 1 Executive Summary Finding 1 — Below-Benchmark Profitability
	-- - Revenue: $2.27M | Profit: $282K | Margin: 12.45%
	-- - Retail benchmark: 15% margin
	-- - Gap represents ~$56,800 in unrealized annual profit
	-- - Hypothesis: Discount policy and product mix are primary drivers
	-- - → Investigated in Phase 2 and Phase 4

# 2 Is our discounting strategy destroying profit? 
Select 
	Case 
		When Discount = 0 Then '0 - No Discount'
        When Discount <= 0.20 Then '1 - Low (1-20%)'
        When Discount <= 0.40 Then '2 - Medium (21-40%)'
        Else '3 - High (>40%)' 
	END As discount_band,
Count(*) As order_count, 
Round(Sum(Sales),2) as total_sales,
Round(Sum(Profit),2) as total_profit,
Round(Sum(Profit)/Sum(Sales) * 100,2) as avg_margin_percentage 
From superstore_clean 
Group By discount_band 
Order By discount_band;

-- ## Finding 2 — Discount Policy is the Primary Margin Killer
-- - Orders with >40% discount: -77.2% margin, losing $98,327
-- - Orders with 21-40% discount: -15.31% margin, losing $35,825
-- - Combined loss from discounted orders: -$134,152
-- - No-discount orders: 29.57% margin — carrying the entire business
-- - Recommendation: Cap discounts at 20% maximum. 
--   Eliminate >40% discount approvals without CFO sign-off. 



# 3 Regional × Segment Profitability Matrix 
Select 
	Region, Segment, 
    Round(Sum(Sales),2) As revenue, 
    Round(Sum(Sales),2) as profit,
    Round(Sum(Profit)/Sum(Sales)*100,2) as Margin_Percentage,
    Count(*) as total_orders 
From superstore_clean 
Group By Region, Segment 
Order By Margin_Percentage DESC;

# ## Finding 3 — Regional & Segment Profitability Matrix
	-- ### Business Question
	-- Which region-segment combinations should we invest in, optimize, or exit?
	-- ### Methodology
	-- Aggregated 9,994 transactions across 4 regions and 3 segments.
	-- Calculated revenue, profit, and margin % per combination.
	-- Classified each using consulting Invest/Optimize/Fix/Restructure framework. 
	-- ### Key Findings
	-- 1. STAR PERFORMER — East Home Office
	--    - Only combination exceeding 20% margin threshold
	--    - 483 orders at premium profitability
	--    - Action: Protect pricing, prioritize retention, replicate model
	-- 2. CRISIS MARKET — Central Consumer
	--    - 1,181 orders (high volume) at only 3.62% margin
	--    - Nearly breakeven despite being 3rd highest order volume
	--    - Root cause: Likely excessive discounting (cross-reference Finding 2)
	--    - Action: Immediate discount audit, pricing floor enforcement
	-- 3. WEST IS THE BENCHMARK REGION
	--    - All 3 West segments above 12% margin
	--    - Most consistent regional performance across all segments
	--    - Action: Use West pricing and discount policies as template
	-- 4. SOUTH HOME OFFICE IS A HIDDEN RISK
	--    - Only 265 orders at 6.18% margin
	--    - Low volume + low margin = not worth continued investment
	--    - Action: Consolidate with South Corporate operations
	-- ### Recommendations
	-- 1. Replicate East Home Office pricing discipline across all regions
	-- 2. Enforce discount cap of 20% in Central Consumer immediately
	-- 3. Use West region as operational benchmark for margin management
	-- 4. Deprioritize South Home Office — redirect sales resources to West Consumer  


# 4 Product Sub-Category Ranking
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

# 4 Findings 
	## Finding 4 — Product Sub-Category Profitability Ranking
	-- ### Key Findings
	-- 1. ELIMINATE OR REPRICE — Tables & Bookcases (Furniture)
	--    - Tables: $206K revenue, -$8.56% margin, losing $17,725
	--    - Bookcases: $114K revenue, -3.02% margin, losing $3,472
	--    - Combined furniture loss: -$21,197
	--    - Action: Enforce price floors, renegotiate supplier contracts,
	--      consider discontinuing deep-discount furniture orders
	-- 2. SCALE IMMEDIATELY — Paper & Labels (Office Supplies)
	--    - Paper: 43.41% margin | Labels: 44.42% margin
	--    - Highest margin sub-categories in entire business
	--    - Action: Increase marketing spend, expand SKU range
	-- 3. PROTECT — Copiers (Technology)
	--    - $55,617 profit on only 68 orders = $818 profit per order
	--    - Highest profit per order in entire business
	--    - Action: Dedicated enterprise sales motion, no discounting
	-- 4. WATCH — Machines (Technology)
	--    - $189K revenue at 1.79% margin — near breakeven
	--    - Any discount on Machines = guaranteed loss
	--    - Action: Strict no-discount policy on Machines 

# 5 
	# Customer RFM Segmentation recency_score + frequency_score + monetary_score

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
)
SELECT
    `Customer ID`,
    `Customer Name`,
    last_order_date,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score)  AS rfm_total,
    CASE
        WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Champion'
        WHEN (recency_score + frequency_score + monetary_score) >= 7  THEN 'Loyal'
        WHEN (recency_score + frequency_score + monetary_score) >= 5  THEN 'At Risk'
        ELSE                                                               'Churned'
    END AS customer_segment
FROM rfm_scored
ORDER BY rfm_total DESC; 

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

	-- ## Finding 5 — Customer RFM Segmentation

	-- ### Business Question
	-- Who are our most valuable customers and where is retention risk highest?

	-- ### Methodology
	-- RFM framework applied across 793 customers.
	-- Scored 1-4 on Recency, Frequency, Monetary using NTILE quartiles.
	-- Combined score classified into Champion / Loyal / At Risk / Churned.

	-- ### Results

	-- | Segment  | Customers | Total Revenue | Avg/Customer | Avg Orders |
	-- |----------|-----------|---------------|--------------|------------|
	-- | At Risk  | 210       | $798,440      | $3,802       | 7.9        |
	-- | Loyal    | 266       | $697,164      | $2,620       | 5.6        |
	-- | Churned  | 110       | $576,188      | $5,238       | 9.1        |
	-- | Champion | 207       | $200,656      | $969         | 3.8        |

	-- ### Key Findings

	-- 1. CRITICAL — At Risk segment drives highest total revenue
	--    - $798K from 210 customers showing disengagement signals
	--    - 7.9 avg orders = high historical loyalty, now at risk
	--    - Action: Immediate retention campaign, personalized outreach,
	--      loyalty incentives before they move to Churned

	-- 2. URGENT — Churned customers were the highest spenders
	--    - $5,238 avg revenue per customer — highest of all segments
	--    - 110 customers = $576K in lost recurring revenue
	--    - Action: Win-back campaign with premium offers,
	--      dedicated re-engagement budget of 10-15% of lost revenue

	-- 3. COUNTERINTUITIVE — Champions are lowest revenue contributors
	--    - $969 avg revenue despite perfect RFM score
	--    - Recent + frequent buyers but low ticket size
	--    - Action: Upsell and cross-sell campaigns to increase
	--      basket size among Champion segment

	-- 4. REVENUE AT RISK
	--    - At Risk + Churned = 320 customers = $1.37M revenue at risk
	--    - Represents 60% of total business revenue
	--    - Action: Customer success function needed immediately

	-- ### Recommendations
	-- 1. Prioritize At Risk retention over Champion acquisition
	-- 2. Allocate win-back budget specifically for Churned high-spenders
	-- 3. Upsell Champions to increase their monetary score
	-- 4. Build early warning system — flag customers going 90+ days
	--    without purchase as pre-At Risk


# 6 Shipping & Operations Efficiency 
 
 
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

	-- ## Finding 6 — Shipping & Operations Efficiency

	-- ### Business Question
	-- Is logistics a hidden profit drain across shipping modes?
	-- ### Results
	-- | Ship Mode      | Orders | Avg Days | Margin % | Avg Profit/Order |
	-- |----------------|--------|----------|----------|-----------------|
	-- | Same Day       | 527    | 0.0      | 12.58%   | $30.41          |
	-- | First Class    | 1,501  | 2.2      | 13.96%   | $32.50          |
	-- | Second Class   | 1,886  | 3.2      | 12.46%   | $29.96          |
	-- | Standard Class | 5,780  | 5.0      | 12.04%   | $27.95          |
	-- ### Key Findings
	-- 1. FIRST CLASS IS THE SWEET SPOT
	--    - Best margin (13.96%) and highest profit per order ($32.5)
	--    - Premium shipping correlates with premium product purchases
	--    - Action: Incentivize customers to upgrade from Standard
	--      to First Class — improves both experience and margin
	-- 2. STANDARD CLASS IS A VOLUME TRAP
	--    - 58% of all orders at lowest margin and profit per order
	--    - High volume does not compensate for low per-order returns
	--    - Action: Introduce minimum order value for Standard Class
	--      to improve per-order economics
	-- 3. DATA QUALITY FLAG — Same Day Shows 0 Days
	--    - Average shipping days of 0.0 is anomalous
	--    - Possible recording error — ship date = order date
	--    - Action: Audit Same Day order records for data integrity
	-- 4. SHIPPING IS NOT THE PRIMARY MARGIN DRIVER
	--    - Only 1.92% margin spread across all shipping modes
	--    - Discount policy (Finding 2) remains dominant margin factor
	--    - Action: Focus margin improvement efforts on discount
	--      controls rather than shipping optimization
	-- ### Recommendations
	-- 1. Promote First Class as default shipping tier
	-- 2. Set minimum order value for Standard Class eligibility
	-- 3. Audit Same Day shipping records for data quality
	-- 4. Do not over-invest in shipping optimization —
	--    discount policy reform has 10x higher margin impact


# 7 Year on Year Revenue Trend
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

	-- # Revenue is growing every year (+50% from 2014→2017) but margin peaked at 13.33% in 2016 
	-- and is declining in 2017 despite record revenue. Classic "growing but leaking" pattern 
	-- — the business is scaling its discount problem alongside its revenue.
