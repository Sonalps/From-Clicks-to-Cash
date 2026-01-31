# 🚀 From Clicks to Cash: From Raw Data to a $23.1M Growth Playbook

**One-line hook:**  
End-to-end ecommerce analytics case study turning 125K+ orders into a quantified **$23.1M revenue opportunity**, built like a real consulting engagement — not a classroom exercise. :contentReference[oaicite:0]{index=0}

---

## Executive Summary

- **What this is:** A full-funnel analytics deep dive on *TheLook*, a global fashion ecommerce business — from data validation to executive-level recommendations.
- **Scale:** ~125K orders, ~182K order items, 100K users, ~7 years of data (2019–2024 after cleaning).
- **Headline problems uncovered:**
  - 🚨 **15% cancellation rate** (2× industry benchmark)
  - 📉 **AOV decline** despite explosive revenue growth
  - 🔁 **Global retention failure** — ~96% of customers churn within 30 days
- **Bottom line:** Identified **~$23.1M in annual revenue upside** through cancellation fixes, AOV optimization, and retention programs.
- **Why it matters:** This project mirrors how a junior analyst would support growth, product, and ops teams with real business impact.

---

## Dataset & Scope

**Source:** TheLook Ecommerce sample dataset  
**Core tables:** orders, order_items, users, products, geography, cohorts, KPIs  
**Time span:** ~7 years of history → filtered to **2019–2024** (future/test dates removed)

### Data Quality Highlights
- ✅ **99%+ completeness**, zero duplicates, perfect referential integrity
- ✅ Returns at ~10% (better than 20–30% industry norm)
- ⚠️ High cancellations (15%) flagged as a business issue, not a data issue

### Key Cleaning & Validation Steps
- Filtered out future dates (2025–2026 artifacts)
- Excluded cancelled/returned orders from realized revenue
- Handled null cities/brands (`<1%`, labeled as “Unknown”)
- Price anomaly checks (flagged sub-$1 items)
- Derived metrics: order value, leakage rate, cohort retention curves

---

## Insights Deep Dive

### 📈 Revenue Growth & Trends
- Revenue exploded from **~$61K (2019) → ~$1.29M (2024)**  
- **45–62% YoY growth** across quarters — 3–4× healthy ecommerce benchmarks
- Slight deceleration at scale is *normal* and expected
- Growth is **volume-driven**, not value-driven (AOV stagnation)

---

### 💰 Average Order Value & Product Mix
- AOV slipped from **~$90 → ~$86** over time
- Root cause: **product mix shift**
  - **61% of items sold** are under $50 → only **28% of revenue**
  - **Premium items ($50+)** = 39% of volume → **72% of revenue**
- Insight: Revenue is growing *in spite of* declining order quality

---

### 🚨 Revenue Leakage & Cancellations
- Only **~55% of potential revenue** is realized
- **~25% leaks** through cancellations + returns
- Standout contrast:
  - ❌ **Cancellation rate ~15%** (industry: 5–10%)
  - ✅ **Return rate ~10%** (industry: 20–30%)
- Translation: **Products are good; pre-fulfillment experience is broken**
- Impact:
  - ~$900K/year lost to cancellations
  - ~$1.5M total annual leakage

---

### 🔁 Customer Retention & Cohorts
- Global repeat rate: **~29% across all major countries**
- No “star” market — loyalty is a **systemic problem**
- **Retention cliff:**
  - 95–97% churn within **30 days**
  - Only **2–4%** of customers active after 12 months
- Upside:
  - Improving month-1 retention from ~3% → ~15%  
    = **~$8.2M annual revenue lift**

---

### 🧥 Product Performance & Category Strategy
- **Stars (high revenue, high margin):**
  - Outerwear, sweaters, accessories (50%+ margins)
- **Drags:**
  - Socks, suits, intimates — low margin, low revenue
- Basket behavior:
  - **71% single-category orders** → AOV ~$60
  - **3+ category orders** → AOV $200+
- Clear cross-sell gap + **200+ dead SKUs** with no sales in 6 months

---

### 🌍 Geography & Market Insights
- Revenue share:
  - China ~34%
  - USA ~22%
  - Brazil ~15%
- All markets growing fast (35–75% YoY)
- Key twist: **Every country has the same loyalty problem**
- Conclusion: Retention should be **global**, not country-specific

---

## Key Product & Channel Performance

- **Hero products:** Premium outerwear (Canada Goose, Moncler, North Face)
- **Price tiers:** Budget dominates volume, premium dominates revenue
- **Seasonality:**
  - Q4 (Nov–Dec) ≈ **34% of annual revenue**
  - Q1 weakest (post-holiday slump)
- Insight: Strong holiday engine, weak off-season strategy

---

## Core KPIs — Dashboard Snapshot (Latest Period)

| KPI | Value | Status | Insight |
|---|---|---|---|
| Revenue | ~$132K (Dec) | 🟢 Excellent | 60%+ YoY growth |
| Orders | ~1.4K | 🟡 Flat | Volume plateau risk |
| AOV | ~$85 | 🔴 Needs Attention | Below $90 target |
| Cancellation Rate | ~15% | 🚨 Critical | 2× industry norm |
| Return Rate | ~10% | 🟢 Excellent | Best-in-class |
| Total Leakage | ~25% | 🚨 Critical | 1 in 4 dollars lost |
| Budget Item Share | ~62% | ⚠️ High | AOV drag |
| Top Market Share | China ~34% | 🟢 Strong | Growth engine |

---

## Recommendations & Roadmap (Prioritized)

1. **Cancel the Cancellations**  
   *Targets:* Cancellation rate, revenue leakage  
   *Actions:* Payment expansion, inventory checks, faster confirmations  
   *Upside:* **~$630K/year**

2. **Boost AOV with Bundles & Thresholds**  
   *Targets:* AOV, product mix  
   *Actions:* Bundles, “Complete the Look”, free shipping @ $100  
   *Upside:* **~$60K–$2.4M**

3. **Global Retention Program**  
   *Targets:* Repeat rate, LTV  
   *Actions:* 30-day post-purchase flows, loyalty rewards  
   *Upside:* **~$3.8M**

4. **Fix the Month-1 Retention Cliff**  
   *Targets:* Cohort churn  
   *Actions:* Email/SMS nudges (Days 3, 7, 14, 30)  
   *Upside:* **~$8.2M**

5. **Cross-Sell to Kill Single-Category Orders**  
   *Targets:* Basket size, AOV  
   *Actions:* Category recommendations, bundles  
   *Upside:* **~$4.2M**

6. **Cut Dead-Weight SKUs**  
   *Targets:* Margin, catalog efficiency  
   *Actions:* Remove unsold/low-price SKUs  
   *Upside:* Cost + focus gains

**➡️ Total identified opportunity: ~$23.1M annually**

---

## Tech Stack & Skills Demonstrated

- **SQL (Advanced):** multi-table joins, window functions, cohorts, funnel & leakage analysis
- **Data Validation:** null handling, anomaly detection, integrity checks
- **Analytics Thinking:** revenue drivers, margin logic, customer behavior
- **Storytelling:** translating metrics into executive-ready insights
- **BI-ready workflow:** SQL outputs designed for Tableau / Power BI dashboards

---

## How to Use This Repo

- `/sql/01_data_validation.sql` → data quality & integrity checks  
- `/sql/02_revenue_trends.sql` → growth, seasonality, leakage  
- `/sql/03_product_performance.sql` → AOV, mix, margins
- `/sql/04_geography.sql` → market & country insights  
- `/sql/05_retention_cohorts.sql` → churn & lifetime value  
  
 

Clone, run queries on TheLook dataset (or adapt to your own ecommerce data), and plug results into a BI tool.

---

## 📊 Executive Dashboards

### Executive Revenue Overview
**Purpose:** High-level view for leadership to track revenue health, leakage, and growth signals.

**Key questions answered:**
- How fast is the business Monthly Revenue Trend & MoM Growth
?
- Where is revenue leaking?
- Which KPIs require immediate action?
- Where is the money coming from?
- Top 5 Categories by Revenue


🔗 **Live Dashboard (Tableau Public):**  
👉 [View Executive Revenue Dashboard](https://public.tableau.com/app/profile/balaji.ajay.kumar.madana4033/viz/Project1_1_17688543645130/ExecutiveRevenue)

📸 **Preview:**  
<img width="1189" height="806" alt="image" src="https://github.com/user-attachments/assets/e9edca50-df5d-4b1d-be38-e1a7abdeed95" />



