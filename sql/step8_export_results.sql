-- Step 8: Export Analytics Results to S3
-- Save query results for further analysis and reporting

-- ==============================================
-- EXPORT DAILY PERFORMANCE ANALYSIS
-- ==============================================

UNLOAD ('
SELECT 
    pickup_date,
    total_trips,
    ROUND(total_revenue, 2) as daily_revenue,
    ROUND(revenue_per_trip, 2) as avg_fare,
    ROUND(credit_card_percentage, 1) as credit_card_usage_pct,
    CASE 
        WHEN total_trips > 300000 THEN ''High Volume''
        WHEN total_trips > 200000 THEN ''Medium Volume'' 
        ELSE ''Low Volume''
    END as volume_category
FROM glue_curated.daily_summary
ORDER BY pickup_date DESC
')
TO 's3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/daily_performance_'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
CSV
HEADER
PARALLEL OFF;

-- ==============================================
-- EXPORT PEAK HOURS ANALYSIS
-- ==============================================

UNLOAD ('
SELECT 
    pickup_hour,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_hourly_fare,
    ROUND(SUM(trip_count * avg_fare), 2) as estimated_revenue,
    ROUND(AVG(avg_distance), 2) as avg_hourly_distance,
    CASE 
        WHEN pickup_hour BETWEEN 7 AND 9 THEN ''Morning Rush''
        WHEN pickup_hour BETWEEN 17 AND 19 THEN ''Evening Rush''
        WHEN pickup_hour BETWEEN 22 AND 5 THEN ''Night Hours''
        ELSE ''Regular Hours''
    END as time_category
FROM glue_curated.hourly_patterns
GROUP BY pickup_hour
ORDER BY total_trips DESC
')
TO 's3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/peak_hours_analysis_'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
CSV
HEADER
PARALLEL OFF;

-- ==============================================
-- EXPORT EXECUTIVE SUMMARY
-- ==============================================

UNLOAD ('
SELECT 
    ''Executive Summary'' as report_type,
    ''NYC Taxi Analytics Pipeline'' as dataset_name,
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
    )) as peak_hour
')
TO 's3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/executive_summary_'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
CSV
HEADER
PARALLEL OFF;

-- ==============================================
-- EXPORT DATA VALIDATION RESULTS
-- ==============================================

UNLOAD ('
SELECT 
    ''Data Consistency Check'' as validation_type,
    (SELECT SUM(total_trips) FROM glue_curated.daily_summary) as daily_summary_trips,
    (SELECT SUM(trip_count) FROM glue_curated.hourly_patterns) as hourly_patterns_trips,
    (SELECT SUM(trip_count) FROM glue_curated.payment_analysis) as payment_analysis_trips,
    (SELECT SUM(trip_count) FROM glue_curated.distance_analysis) as distance_analysis_trips,
    (SELECT SUM(trip_count) FROM glue_curated.location_analysis) as location_analysis_trips
')
TO 's3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/data_validation_'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
CSV
HEADER
PARALLEL OFF;

-- ==============================================
-- EXPORT PAYMENT ANALYSIS
-- ==============================================

UNLOAD ('
SELECT 
    COUNT(*) as payment_type_records,
    SUM(trip_count) as total_trips,
    ROUND(SUM(total_revenue), 2) as total_revenue,
    ROUND(AVG(avg_fare), 2) as avg_fare_by_payment,
    ROUND(AVG(avg_tip), 2) as avg_tip_amount,
    ROUND(AVG(tip_percentage), 1) as avg_tip_percentage
FROM glue_curated.payment_analysis
')
TO 's3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/payment_analysis_'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
CSV
HEADER
PARALLEL OFF;

-- ==============================================
-- CREATE ANALYTICS RESULTS FOLDER
-- ==============================================

-- Note: Run this first to create the analytics-results folder structure
-- You can verify the exports by checking S3:
-- s3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/

-- After running the UNLOAD commands above, you can download the CSV files from S3
-- or access them programmatically for dashboard creation. 