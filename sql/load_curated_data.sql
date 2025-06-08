-- COPY commands to load curated Parquet data from S3 into Redshift
-- Replace placeholders with actual values from your Terraform outputs
-- Run these after creating the tables with create_curated_tables.sql

-- Variables (Replace with actual values)
-- S3_BUCKET: cloud-native-analytics-pipeline-d8e6ca17
-- IAM_ROLE: arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role
-- REGION: us-east-1

-- ==============================================================================
-- LOAD DAILY SUMMARY DATA
-- ==============================================================================
COPY analytics.daily_summary 
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/daily_summary/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- ==============================================================================
-- LOAD HOURLY PATTERNS DATA  
-- ==============================================================================
COPY analytics.hourly_patterns
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/hourly_patterns/' 
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- ==============================================================================
-- LOAD PAYMENT ANALYSIS DATA
-- ==============================================================================
COPY analytics.payment_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/payment_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- ==============================================================================
-- LOAD DISTANCE ANALYSIS DATA
-- ==============================================================================
COPY analytics.distance_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/distance_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- ==============================================================================
-- LOAD LOCATION ANALYSIS DATA
-- ==============================================================================
COPY analytics.location_analysis
FROM 's3://cloud-native-analytics-pipeline-d8e6ca17/curated/location_analysis/'
IAM_ROLE 'arn:aws:iam::439530517237:role/cloud-native-analytics-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET
ACCEPTINVCHARS;

-- ==============================================================================
-- POST-LOAD VALIDATION AND OPTIMIZATION
-- ==============================================================================

-- Check row counts for each table
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

-- Analyze tables to update statistics for optimal query plans
ANALYZE analytics.daily_summary;
ANALYZE analytics.hourly_patterns;
ANALYZE analytics.payment_analysis;
ANALYZE analytics.distance_analysis;
ANALYZE analytics.location_analysis;

-- Check for load errors (run if any COPY commands fail)
SELECT 
    query,
    filename,
    line_number,
    colname,
    type,
    position,
    raw_line,
    raw_field_value,
    err_reason
FROM stl_load_errors
WHERE userid = USER_ID
ORDER BY starttime DESC
LIMIT 20;

-- View table distribution and sort key efficiency
SELECT 
    trim(t.name) as table_name,
    trim(c.name) as column_name,
    c.distkey,
    c.sortkey
FROM stv_tbl_perm t
JOIN pg_class pgc ON pgc.oid = t.id
JOIN pg_namespace pgn ON pgn.oid = pgc.relnamespace  
JOIN pg_attribute c ON c.attrelid = pgc.oid
WHERE pgn.nspname = 'analytics'
AND c.attnum > 0
AND NOT c.attisdropped
ORDER BY t.name, c.attnum;

/*
LOADING BEST PRACTICES:
=======================

1. COPY PERFORMANCE:
   - COPY is the fastest way to load data into Redshift
   - Parallel loading from multiple S3 files for better throughput
   - PARQUET format provides excellent compression and performance

2. ERROR HANDLING:
   - ACCEPTINVCHARS handles character encoding issues
   - Check stl_load_errors for any data quality issues
   - Consider MAXERROR parameter for fault tolerance

3. POST-LOAD OPTIMIZATION:
   - Always run ANALYZE after bulk loads
   - Monitor VACUUM usage and run as needed
   - Update table statistics for optimal query plans

4. INCREMENTAL LOADING:
   - Use UPSERT pattern for daily increments
   - Consider using staging tables for complex transformations
   - Implement data quality checks before final load

5. MONITORING:
   - Track load times and row counts
   - Monitor query performance after loads
   - Set up alerts for load failures
*/ 