-- Step 7.3: Load Curated Data from S3 into Redshift
-- Execute this script after creating tables
-- This will load all 5 curated analytics tables

-- 1. Load daily_summary data
COPY analytics.daily_summary 
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/daily_summary/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- 2. Load hourly_patterns data
COPY analytics.hourly_patterns
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/hourly_patterns/' 
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- 3. Load payment_analysis data
COPY analytics.payment_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/payment_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- 4. Load distance_analysis data
COPY analytics.distance_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/distance_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- 5. Load location_analysis data
COPY analytics.location_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/location_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- 6. Validate data loading - Check row counts
SELECT 'daily_summary' as table_name, COUNT(*) as row_count FROM analytics.daily_summary
UNION ALL
SELECT 'hourly_patterns' as table_name, COUNT(*) as row_count FROM analytics.hourly_patterns
UNION ALL
SELECT 'payment_analysis' as table_name, COUNT(*) as row_count FROM analytics.payment_analysis
UNION ALL
SELECT 'distance_analysis' as table_name, COUNT(*) as row_count FROM analytics.distance_analysis
UNION ALL
SELECT 'location_analysis' as table_name, COUNT(*) as row_count FROM analytics.location_analysis
ORDER BY table_name;

-- 7. Analyze tables for optimal query performance
ANALYZE analytics.daily_summary;
ANALYZE analytics.hourly_patterns;
ANALYZE analytics.payment_analysis;
ANALYZE analytics.distance_analysis;
ANALYZE analytics.location_analysis;

-- 8. Check for any load errors
SELECT 
    query,
    filename,
    line_number,
    colname,
    err_reason
FROM stl_load_errors
WHERE userid = CURRENT_USER_ID
AND starttime > DATEADD(hour, -1, GETDATE())
ORDER BY starttime DESC;

-- 9. Quick data quality check
SELECT 'Data Quality Check' as check_type,
       'Total records loaded: ' || 
       (SELECT SUM(row_count) FROM (
           SELECT COUNT(*) as row_count FROM analytics.daily_summary
           UNION ALL SELECT COUNT(*) FROM analytics.hourly_patterns
           UNION ALL SELECT COUNT(*) FROM analytics.payment_analysis
           UNION ALL SELECT COUNT(*) FROM analytics.distance_analysis
           UNION ALL SELECT COUNT(*) FROM analytics.location_analysis
       )) as result; 