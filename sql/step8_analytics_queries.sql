-- Step 8: Advanced Analytics & Validation Queries
-- Comprehensive business intelligence and data validation

-- ==============================================
-- 8.1 KEY ANALYTIC QUERIES 
-- ==============================================

-- Daily Performance Metrics
-- Revenue trends and trip volume analysis
SELECT 
    'Daily Performance Overview' as metric_category,
    pickup_date,
    total_trips,
    ROUND(total_revenue, 2) as daily_revenue,
    ROUND(revenue_per_trip, 2) as avg_fare,
    ROUND(credit_card_percentage, 1) as credit_card_usage_pct,
    CASE 
        WHEN total_trips > 300000 THEN 'High Volume'
        WHEN total_trips > 200000 THEN 'Medium Volume' 
        ELSE 'Low Volume'
    END as volume_category
FROM glue_curated.daily_summary
ORDER BY pickup_date DESC;

-- Weekly Revenue Trends
SELECT 
    'Weekly Trends' as metric_category,
    DATE_TRUNC('week', pickup_date) as week_start,
    COUNT(*) as days_in_week,
    SUM(total_trips) as weekly_trips,
    ROUND(SUM(total_revenue), 2) as weekly_revenue,
    ROUND(AVG(revenue_per_trip), 2) as avg_weekly_fare,
    ROUND(AVG(credit_card_percentage), 1) as avg_credit_usage
FROM glue_curated.daily_summary
GROUP BY DATE_TRUNC('week', pickup_date)
ORDER BY week_start DESC;

-- ==============================================
-- 8.2 LOCATION INTELLIGENCE
-- ==============================================

-- Top Rate Code Performance Analysis
SELECT 
    'Location Performance' as metric_category,
    COUNT(*) as total_records,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as average_fare,
    ROUND(SUM(trip_count * avg_fare), 2) as estimated_total_revenue,
    ROUND(AVG(avg_distance), 2) as avg_distance_miles
FROM glue_curated.location_analysis;

-- ==============================================
-- 8.3 TIME-SERIES ANALYSIS
-- ==============================================

-- Peak Hours Analysis
SELECT 
    'Hourly Performance' as metric_category,
    pickup_hour,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_hourly_fare,
    ROUND(SUM(trip_count * avg_fare), 2) as estimated_revenue,
    ROUND(AVG(avg_distance), 2) as avg_hourly_distance,
    CASE 
        WHEN pickup_hour BETWEEN 7 AND 9 THEN 'Morning Rush'
        WHEN pickup_hour BETWEEN 17 AND 19 THEN 'Evening Rush'
        WHEN pickup_hour BETWEEN 22 AND 5 THEN 'Night Hours'
        ELSE 'Regular Hours'
    END as time_category
FROM glue_curated.hourly_patterns
GROUP BY pickup_hour
ORDER BY total_trips DESC;

-- Time of Day Distribution
SELECT 
    'Time Distribution' as metric_category,
    CASE 
        WHEN pickup_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN pickup_hour BETWEEN 12 AND 17 THEN 'Afternoon' 
        WHEN pickup_hour BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night'
    END as time_period,
    SUM(trip_count) as period_trips,
    ROUND(AVG(avg_fare), 2) as period_avg_fare,
    COUNT(DISTINCT pickup_hour) as hours_in_period
FROM glue_curated.hourly_patterns
GROUP BY 1
ORDER BY period_trips DESC;

-- ==============================================
-- 8.4 CUSTOMER BEHAVIOR ANALYSIS
-- ==============================================

-- Payment Method Intelligence
SELECT 
    'Payment Analysis' as metric_category,
    COUNT(*) as payment_type_records,
    SUM(trip_count) as total_trips,
    ROUND(SUM(total_revenue), 2) as total_revenue,
    ROUND(AVG(avg_fare), 2) as avg_fare_by_payment,
    ROUND(AVG(avg_tip), 2) as avg_tip_amount,
    ROUND(AVG(tip_percentage), 1) as avg_tip_percentage
FROM glue_curated.payment_analysis;

-- Distance Category Performance
SELECT 
    'Distance Analysis' as metric_category,
    COUNT(*) as distance_category_records,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_distance), 2) as overall_avg_distance,
    ROUND(AVG(avg_fare), 2) as overall_avg_fare,
    ROUND(AVG(fare_per_mile), 2) as avg_fare_per_mile
FROM glue_curated.distance_analysis;

-- ==============================================
-- 8.5 DATA INTEGRITY VALIDATION
-- ==============================================

-- Cross-Table Consistency Check
SELECT 
    'Data Consistency Check' as validation_type,
    (SELECT SUM(total_trips) FROM glue_curated.daily_summary) as daily_summary_trips,
    (SELECT SUM(trip_count) FROM glue_curated.hourly_patterns) as hourly_patterns_trips,
    (SELECT SUM(trip_count) FROM glue_curated.payment_analysis) as payment_analysis_trips,
    (SELECT SUM(trip_count) FROM glue_curated.distance_analysis) as distance_analysis_trips,
    (SELECT SUM(trip_count) FROM glue_curated.location_analysis) as location_analysis_trips;

-- Data Quality Metrics
SELECT 
    'Data Quality Summary' as validation_type,
    COUNT(DISTINCT pickup_date) as unique_dates,
    MIN(pickup_date) as earliest_date,
    MAX(pickup_date) as latest_date,
    SUM(total_trips) as total_processed_trips,
    ROUND(SUM(total_revenue), 2) as total_processed_revenue
FROM glue_curated.daily_summary;

-- Revenue Validation Check
SELECT 
    'Revenue Validation' as validation_type,
    ROUND(SUM(total_revenue), 2) as daily_summary_revenue,
    ROUND(SUM(total_revenue), 2) as payment_analysis_revenue,
    ROUND(ABS(
        (SELECT SUM(total_revenue) FROM glue_curated.daily_summary) - 
        (SELECT SUM(total_revenue) FROM glue_curated.payment_analysis)
    ), 2) as revenue_difference,
    CASE 
        WHEN ABS(
            (SELECT SUM(total_revenue) FROM glue_curated.daily_summary) - 
            (SELECT SUM(total_revenue) FROM glue_curated.payment_analysis)
        ) < 1000 THEN 'PASS'
        ELSE 'FAIL'
    END as validation_status
FROM glue_curated.daily_summary
CROSS JOIN glue_curated.payment_analysis
LIMIT 1;

-- ==============================================
-- 8.6 BUSINESS INSIGHTS SUMMARY
-- ==============================================

-- Executive Dashboard Summary
SELECT 
    'Executive Summary' as report_type,
    'NYC Taxi Analytics Pipeline' as dataset_name,
    (SELECT COUNT(DISTINCT pickup_date) FROM glue_curated.daily_summary) as days_analyzed,
    (SELECT SUM(total_trips) FROM glue_curated.daily_summary) as total_trips,
    (SELECT ROUND(SUM(total_revenue), 2) FROM glue_curated.daily_summary) as total_revenue,
    (SELECT ROUND(AVG(revenue_per_trip), 2) FROM glue_curated.daily_summary) as avg_fare_per_trip,
    (SELECT ROUND(AVG(credit_card_percentage), 1) FROM glue_curated.daily_summary) as avg_credit_usage,
    (SELECT pickup_hour FROM (
        SELECT pickup_hour, SUM(trip_count) as trips 
        FROM glue_curated.hourly_patterns 
        GROUP BY pickup_hour 
        ORDER BY trips DESC LIMIT 1
    )) as peak_hour;

-- Performance Benchmarks
SELECT 
    'Performance Benchmarks' as report_type,
    ROUND(AVG(total_trips), 0) as avg_daily_trips,
    ROUND(MAX(total_trips), 0) as peak_daily_trips,
    ROUND(MIN(total_trips), 0) as lowest_daily_trips,
    ROUND(STDDEV(total_trips), 0) as daily_trip_volatility,
    ROUND(AVG(total_revenue), 2) as avg_daily_revenue,
    ROUND(MAX(total_revenue), 2) as peak_daily_revenue
FROM glue_curated.daily_summary;

-- ==============================================
-- 8.7 QUERY PERFORMANCE MONITORING
-- ==============================================

-- Table Size and Performance Metrics
SELECT 
    'Table Performance' as metric_type,
    'External tables via Spectrum - No storage in Redshift' as storage_note,
    'Query performance optimized by Glue partitioning' as optimization_note,
    'Business intelligence ready for dashboard integration' as readiness_status; 