# Marketing A/B Test Analysis: Does Advertising Increase Conversion?

An end-to-end analysis of a large-scale marketing A/B test, examining whether showing users a product advertisement increases conversion compared to a public service announcement (PSA) control group. Built with a **Python → PostgreSQL → Tableau** pipeline, with a strong emphasis on statistical rigor: hypothesis testing, effect size, and power analysis — not just p-values.

**[View the interactive Tableau Story →](https://public.tableau.com/views/ABTestingAnalysis_17845301173950/ABTestingAnalysis?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**
---

## Project Overview

Marketing teams routinely run A/B tests to justify ad spend, but a statistically significant result doesn't always mean a practically meaningful one — especially at scale, where even tiny differences become "significant." This project goes beyond a simple p-value check to answer three questions:

1. **Does the ad actually work**, and is the effect large enough to matter?
2. **Was the experiment well-designed** — did it collect the right amount of data?
3. **What secondary patterns** (ad exposure frequency, day, hour) are worth acting on — and which are just correlation, not causation?

**Data source:** [Marketing A/B Testing dataset](https://www.kaggle.com/datasets/faviovaz/marketing-ab-testing) (Kaggle)
**Sample size:** 588,101 users
**Groups:** `ad` (treatment — shown a product advertisement) vs. `psa` (control — shown a public service announcement)

---

## Key Findings

- **The ad group converted at 2.55% vs. 1.79% for the PSA control group — a 43% relative lift**, and the difference is statistically significant (Z = 7.37, p < 0.0001; 95% confidence intervals do not overlap).
- **The observed effect size is small (Cohen's h = 0.053)**, but because the sample size was so large, the experiment had **100% statistical power** to detect it — a reminder that statistical significance and practical significance are not the same thing.
- **The experiment was substantially over-powered**: only ~5,588 users per group were needed to reach 80% power for this effect size, versus the ~588,000 actually used — suggesting future tests could reach reliable conclusions with a smaller (and cheaper) control group.
- **Conversion rate rises sharply with ad exposure**, from 0.33% (1–10 ads seen) to 17.68% (101–200 ads seen), though this is a **correlational pattern, not a causal one** — users already inclined to convert may simply view more ads.
- **Conversion is highest in the afternoon/evening (2–9 PM)** and on **Mondays**, useful signals for ad scheduling — though, again, these are observational patterns rather than tested causal effects.

---

## Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| **Analysis** | Python (`pandas`, `statsmodels`) | Hypothesis testing (proportions Z-test), confidence intervals, effect size (Cohen's h), power analysis, sample size calculation |
| **Storage** | PostgreSQL (via `SQLAlchemy` / `psycopg2`) | Persist raw and summarized datasets for SQL-based analysis |
| **Querying** | SQL | Conversion rate breakdowns, exposure-based segmentation with risk/confidence tiering, time-based aggregation |
| **Visualization** | Tableau Public (Story) | Multi-page interactive dashboard combining overview and time-based findings |

---

## Pipeline

```
Kaggle dataset (marketing_AB.csv, 588,101 rows)
      │
      ▼
Python / pandas (data cleaning, conversion rates)
      │
      ▼
Python / statsmodels (Z-test, confidence intervals, Cohen's h, power analysis)
      │
      ▼
PostgreSQL (structured storage: ab_test_raw, ab_test_summary)
      │
      ▼
SQL (conversion breakdowns, exposure bucket + confidence tiering, time-based trends)
      │
      ▼
CSV export → Tableau Public Story (final 2-page dashboard)
```

> **Note:** Tableau Public (free tier) does not support live database connections, so query outputs were exported to CSV as the final hand-off step. All underlying statistical and SQL logic lives in the Notebook and SQL file, not in Tableau itself.

---

## Repository Structure

```
marketing-ab-testing-analysis/
├── ab_test_analysis.ipynb        # Main analysis notebook (cleaning → hypothesis testing → power analysis → DB write)
├── data/
│   └── marketing_AB.csv          # Raw dataset (Kaggle)
├── sql/
│   └── analysis_queries.sql      # Conversion breakdowns, exposure tiering, time-based queries
└── README.md
```

---

## Methodology

### 1. Data Cleaning
Loaded 588,101 rows with no missing values; dropped a redundant index column carried over from the CSV export.

### 2. Hypothesis Testing
- **Test used:** Two-proportion Z-test (`statsmodels.stats.proportion.proportions_ztest`), appropriate for comparing binary conversion outcomes between two independent groups
- **Result:** Z = 7.37, p ≈ 1.71 × 10⁻¹³ — the difference in conversion rates is extremely unlikely to be due to chance

### 3. Effect Size & Confidence Intervals
- Calculated the **absolute difference** (0.77 percentage points) and **relative lift** (43.09%) between groups, since p-values alone don't convey practical magnitude
- Computed 95% confidence intervals for both groups' conversion rates, confirming no overlap

### 4. Power Analysis
- Calculated **Cohen's h** (standardized effect size for two proportions): 0.053 (a small effect by conventional benchmarks)
- Calculated **achieved statistical power** given the actual sample sizes: 100%
- Calculated the **minimum sample size** needed for 80% power at this effect size (~5,588 per group) and compared it to the actual sample collected, to evaluate whether the experiment was efficiently designed

### 5. Exploratory Analysis (Secondary Patterns)
- Segmented conversion rate by **total ad exposure**, **day of week**, and **hour of day**
- Explicitly flagged that exposure-frequency findings are **observational, not causal** — a dedicated randomized experiment on ad frequency would be needed to confirm causality

### 6. SQL Analysis
Rebuilt the core findings in SQL to cross-validate the Python results, plus additional queries styled after real analyst workflows:
- Conversion rate summary by test group
- Exposure-bucket segmentation with a `CASE WHEN`-based **confidence/performance tier** (flagging small-sample buckets as lower confidence)
- Top-performing ad hours by conversion rate
- Day-of-week ordering using a custom `CASE WHEN` sort (to avoid alphabetical sorting of weekday names)

### 7. Visualization
Built as a 2-page **Tableau Story**:
- **Page 1 — Overview & Key Findings:** conversion rate comparison, exposure bucket analysis with performance tiering
- **Page 2 — Time-Based Patterns:** conversion rate by hour of day, conversion rate by day of week

---

## Possible Extensions

- Apply **CUPED (variance reduction)** using pre-experiment covariates to increase sensitivity without collecting more data
- Run a **dedicated randomized experiment** on ad frequency to test the exposure–conversion relationship causally
- Apply **multiple comparison correction** if testing several secondary metrics simultaneously
- Explore **sequential testing** methods to allow valid early stopping in future experiments
