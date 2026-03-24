# Retail Business Case Analysis — SQL Consulting Project

> Simulating how a KPMG/Deloitte analyst would diagnose operational 
> leakages, segment underperforming markets, and deliver executive 
> recommendations — using SQL as the sole analytical engine.

---

## 🎯 Project Objective

Most data projects answer "what happened."
This project answers "so what, and what should the business do."

Using 9,994 retail transactions from a US-based superstore (2014–2017),
this analysis replicates a real consulting engagement across 6 
analytical workstreams — each producing a business recommendation,
not just a chart.

---

## 🗂️ Dataset

- **Source:** Kaggle — Superstore Sales Dataset
- **Link:** https://www.kaggle.com/datasets/vivek468/superstore-dataset-final
- **Size:** 9,994 rows × 21 columns
- **Period:** 2014–2017
- **Tool:** MySQL Workbench (SQL only, with light Python preprocessing)

---

## 🏗️ Project Structure

superstore-business-case/
│
├── data/
│   └── superstore_final.csv
│
├── preprocessing/
│   └── prep.py
│
├── sql/
│   ├── 01_kpi_dashboard.sql
│   ├── 02_discount_analysis.sql
│   ├── 03_regional_matrix.sql
│   ├── 04_product_ranking.sql
│   ├── 05_rfm_segmentation.sql
│   ├── 06_shipping_ops.sql
│   └── 07_yoy_trend.sql
│
├── insights/
│   └── executive_summary.md
│
└── README.md

---

## 📊 Analytical Workstreams

### Phase 1 — Executive KPI Dashboard
**Question:** What is the overall business health?

| Metric | Value |
|---|---|
| Total Revenue | $2,272,449 |
| Total Profit | $282,857 |
| Profit Margin | 12.45% |
| Total Orders | 4,931 |
| Unique Customers | 793 |

**Finding:** Margin of 12.45% sits below the retail benchmark of 15%,
representing ~$56,800 in unrealized annual profit.

---

### Phase 2 — Discount Leakage Analysis
**Question:** Is our discounting strategy destroying profit?

| Discount Band | Orders | Margin % |
|---|---|---|
| No Discount | 4,657 | +29.57% |
| Low (1–20%) | 3,693 | +11.91% |
| Medium (21–40%) | 459 | -15.31% |
| High (>40%) | 885 | -77.20% |

**Finding:** Orders with >40% discount lose 77 cents per dollar of 
revenue. Combined discount losses = -$134,152, entirely offsetting 
profits from no-discount orders.

**Recommendation:** Cap discounts at 20%. Require CFO approval for 
any discount exceeding 40%.

---

### Phase 3 — Regional × Segment Matrix
**Question:** Which markets should we invest in or exit?

| Region | Segment | Margin % | Action |
|---|---|---|---|
| East | Home Office | 20.97% | 🟢 Invest |
| West | Consumer | 15.74% | 🟢 Invest |
| Central | Consumer | 3.62% | 🔴 Restructure |
| South | Home Office | 6.18% | 🟠 Fix |

**Finding:** Central Consumer generates 1,181 orders at only 3.62% 
margin — high volume, near-zero return. East Home Office is the only 
market exceeding 20% margin.

**Recommendation:** Replicate East Home Office pricing discipline 
across all regions. Immediate discount audit in Central Consumer.

---

### Phase 4 — Product Sub-Category Ranking
**Question:** Which product lines are structurally unprofitable?

| Sub-Category | Margin % | Profit |
|---|---|---|
| Labels | 44.42% | +$5,546 |
| Paper | 43.41% | +$32,712 |
| Copiers | 37.20% | +$55,617 |
| Bookcases | -3.02% | -$3,472 |
| Tables | -8.56% | -$17,725 |

**Finding:** Tables and Bookcases lose $21,197 combined. Copiers 
generate $818 profit per order — highest in the business. Paper 
and Labels are high-margin hidden stars.

**Recommendation:** Price floor enforcement on Tables. Scale Paper 
and Labels. Protect Copiers from any discounting.

---

### Phase 5 — Customer RFM Segmentation
**Question:** Who are our most valuable customers?

| Segment | Customers | Revenue | Avg/Customer |
|---|---|---|---|
| At Risk | 210 | $798,440 | $3,802 |
| Loyal | 266 | $697,164 | $2,620 |
| Churned | 110 | $576,188 | $5,238 |
| Champion | 207 | $200,656 | $969 |

**Finding:** Churned customers had the highest avg spend ($5,238) — 
the business lost its best customers. At Risk + Churned = $1.37M 
revenue at risk, representing 60% of total revenue.

**Recommendation:** Immediate retention campaign for At Risk segment. 
Win-back budget for Churned high-spenders. Upsell Champions to 
increase basket size.

---

### Phase 6 — Shipping Operations
**Question:** Is logistics a hidden profit drain?

| Ship Mode | Avg Days | Margin % | Avg Profit/Order |
|---|---|---|---|
| First Class | 2.2 | 13.96% | $32.50 |
| Same Day | 0.0 | 12.58% | $30.41 |
| Second Class | 3.2 | 12.46% | $29.96 |
| Standard Class | 5.0 | 12.04% | $27.95 |

**Finding:** Only 1.92% margin spread across shipping modes — 
shipping is not the primary margin driver. Discount policy has 
10x higher margin impact than shipping optimization.

---

### Bonus — Year on Year Growth Trend

| Year | Revenue | Margin % | Growth |
|---|---|---|---|
| 2014 | $481,763 | 10.18% | — |
| 2015 | $464,426 | 13.11% | -$17,337 |
| 2016 | $601,265 | 13.33% | +$136,839 |
| 2017 | $724,994 | 12.80% | +$123,729 |

**Finding:** Revenue grew 50% from 2014–2017 but margin peaked 
in 2016 and declined in 2017. The business is scaling its 
discount problem alongside its revenue — a classic 
"growing but leaking" pattern.

---

## 🔑 Master Recommendations

1. **Discount Reform** — Cap at 20%, CFO approval above 40%
   → Estimated margin recovery: +$134,152 annually

2. **Regional Fix** — Audit Central Consumer pricing immediately
   → 1,181 orders at 3.62% margin is unsustainable

3. **Product Rationalization** — Price floors on Tables
   → Stop absorbing -$17,725 annual loss on one sub-category

4. **Customer Retention** — At Risk campaign is highest ROI action
   → $798,440 revenue base showing disengagement signals

5. **Scale Winners** — Paper, Labels, Copiers need more investment
   → Highest margin products are currently undersold

---

## 🛠️ SQL Concepts Used

| Concept | Used In |
|---|---|
| Aggregations (SUM, COUNT, AVG) | All phases |
| CASE WHEN | Phase 2, 5 |
| GROUP BY / ORDER BY | All phases |
| CTEs (WITH clause) | Phase 4, 5 |
| Window Functions (RANK, NTILE, LAG) | Phase 4, 5, 7 |
| STR_TO_DATE, DATEDIFF | Phase 6, 7 |
| Subqueries | Phase 5 |

---

## 💼 Resume Bullet

> Conducted end-to-end SQL-based business case analysis on 9,994 
> retail transactions simulating a consulting engagement; identified 
> 3 margin-leakage drivers via discount segmentation, RFM customer 
> tiering, and regional profitability matrix — delivered executive 
> recommendations across 6 analytical workstreams resulting in 
> $134K recoverable margin identified.

---

## 👤 Author
Om Kodgire  
Computer Engineering Graduate — PCCOE Pune  
[LinkedIn](#) | [GitHub](#)