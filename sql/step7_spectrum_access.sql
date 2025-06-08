-- Step 7 Alternative: Access Curated Data via Redshift Spectrum
-- This uses the Glue Data Catalog which knows the correct schemas

-- 1. Create external schema pointing to Glue Catalog
CREATE EXTERNAL SCHEMA IF NOT EXISTS glue_curated
FROM DATA CATALOG
DATABASE 'cloud-native-analytics-analytics-db'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1';

-- 2. List available tables in Glue catalog
SELECT schemaname, tablename, location 
FROM SVV_EXTERNAL_TABLES 
WHERE schemaname = 'glue_curated'
ORDER BY tablename;

-- 3. Test queries against external tables
-- Daily Summary Analysis
SELECT 
    pickup_date,
    total_trips,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(revenue_per_trip, 2) as revenue_per_trip,
    ROUND(credit_card_percentage, 1) as credit_card_pct
FROM glue_curated.daily_summary
ORDER BY pickup_date DESC
LIMIT 10;

-- Payment Analysis Summary
SELECT 
    COUNT(*) as total_records,
    SUM(trip_count) as total_trips,
    ROUND(SUM(total_revenue), 2) as total_revenue
FROM glue_curated.payment_analysis;

-- Hourly Patterns Summary  
SELECT 
    pickup_hour,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_fare
FROM glue_curated.hourly_patterns
GROUP BY pickup_hour
ORDER BY total_trips DESC
LIMIT 10;

-- Distance Analysis Summary
SELECT 
    COUNT(*) as total_records,
    SUM(trip_count) as total_trips  
FROM glue_curated.distance_analysis;

-- Location Analysis Summary
SELECT 
    COUNT(*) as total_records,
    SUM(trip_count) as total_trips
FROM glue_curated.location_analysis;

-- Overall Analytics Summary
SELECT 
    'Analytics Summary' as metric_type,
    'External tables via Spectrum working successfully!' as status,
    'Data accessible via: glue_curated.table_name' as access_method; 