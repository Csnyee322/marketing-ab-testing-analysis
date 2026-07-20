-- ============================================================
-- Marketing A/B Test Analysis
-- SQL Analysis Queries
-- Data source: Kaggle "Marketing A/B Testing" dataset
-- Database: ab_test_analysis (PostgreSQL)
-- ============================================================

-- ------------------------------------------------------------
-- 1. Conversion rate comparison (cross-validates the Python results)
-- ------------------------------------------------------------
SELECT
    "test group",
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS converted_users,
    ROUND(
        CAST(SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS numeric) / COUNT(*) * 100, 
        4
    ) AS conversion_rate_pct
FROM ab_test_raw
GROUP BY "test group";


-- ------------------------------------------------------------
-- 2. Conversion rate by ad exposure bucket
-- Buckets exposure counts with CASE WHEN (SQL equivalent of Python's pd.cut), then compares conversion rate across buckets.
-- ------------------------------------------------------------
SELECT 
    CASE 
        WHEN "total ads" BETWEEN 1 AND 10 THEN '1-10'
        WHEN "total ads" BETWEEN 11 AND 50 THEN '11-50'
        WHEN "total ads" BETWEEN 51 AND 100 THEN '51-100'
        WHEN "total ads" BETWEEN 101 AND 200 THEN '101-200'
        WHEN "total ads" BETWEEN 201 AND 500 THEN '201-500'
        ELSE '500+'
    END AS ads_bucket,
    COUNT(*) AS num_users,
    ROUND(
        CAST(SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS numeric) / COUNT(*) * 100, 
        4
    ) AS conversion_rate_pct
FROM ab_test_raw
WHERE "test group" = 'ad'
GROUP BY ads_bucket
ORDER BY MIN("total ads");


-- ------------------------------------------------------------
-- 3. Best-performing hours by conversion rate
-- Real-world use case: "What time of day should we run ads?"
-- ------------------------------------------------------------
SELECT 
    "most ads hour",
    COUNT(*) AS num_users,
    ROUND(
        CAST(SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS numeric) / COUNT(*) * 100, 
        4
    ) AS conversion_rate_pct
FROM ab_test_raw
WHERE "test group" = 'ad'
GROUP BY "most ads hour"
ORDER BY conversion_rate_pct DESC;


-- ------------------------------------------------------------
-- 4. Conversion rate by day of week
-- Uses a CASE WHEN sort key so weekdays are ordered Monday-Sunday
-- instead of alphabetically.
-- ------------------------------------------------------------
SELECT 
    "most ads day",
    COUNT(*) AS num_users,
    ROUND(
        CAST(SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS numeric) / COUNT(*) * 100, 
        4
    ) AS conversion_rate_pct
FROM ab_test_raw
WHERE "test group" = 'ad'
GROUP BY "most ads day"
ORDER BY 
    CASE "most ads day"
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;


-- ------------------------------------------------------------
-- 5. Business-friendly framing of statistical confidence
-- (risk / performance tiering)
-- Flags small-sample buckets as lower-confidence, rather than
-- treating every conversion rate figure at face value.
-- ------------------------------------------------------------
SELECT 
    ads_bucket,
    num_users,
    conversion_rate_pct,
    CASE 
        WHEN num_users < 1000 THEN 'Low confidence (small sample)'
        WHEN conversion_rate_pct >= 15 THEN 'High performing'
        WHEN conversion_rate_pct >= 5 THEN 'Moderate performing'
        ELSE 'Low performing'
    END AS performance_tier
FROM (
    SELECT 
        CASE 
            WHEN "total ads" BETWEEN 1 AND 10 THEN '1-10'
            WHEN "total ads" BETWEEN 11 AND 50 THEN '11-50'
            WHEN "total ads" BETWEEN 51 AND 100 THEN '51-100'
            WHEN "total ads" BETWEEN 101 AND 200 THEN '101-200'
            WHEN "total ads" BETWEEN 201 AND 500 THEN '201-500'
            ELSE '500+'
        END AS ads_bucket,
        COUNT(*) AS num_users,
        ROUND(
            CAST(SUM(CASE WHEN converted THEN 1 ELSE 0 END) AS numeric) / COUNT(*) * 100, 
            4
        ) AS conversion_rate_pct
    FROM ab_test_raw
    WHERE "test group" = 'ad'
    GROUP BY ads_bucket
) sub
ORDER BY conversion_rate_pct DESC;