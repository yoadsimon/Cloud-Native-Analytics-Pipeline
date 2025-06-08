-- Redshift DDL for NYC Taxi Curated Analytics Tables
-- Optimized with distribution keys, sort keys, and appropriate data types
-- Run this in your Redshift cluster to create the analytics schema

-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- ==============================================================================
-- DAILY SUMMARY TABLE
-- Aggregated daily metrics partitioned by day type
-- ==============================================================================
CREATE TABLE IF NOT EXISTS analytics.daily_summary (
    pickup_date DATE NOT NULL,
    day_type VARCHAR(10) NOT NULL, -- 'Weekday' or 'Weekend'
    total_trips BIGINT NOT NULL,
    total_revenue DECIMAL(12,2) NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_distance DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    avg_speed DECIMAL(6,2),
    max_fare DECIMAL(10,2),
    min_fare DECIMAL(8,2),
    credit_card_trips BIGINT,
    cash_trips BIGINT,
    total_passengers BIGINT,
    anomaly_trips BIGINT,
    revenue_per_trip DECIMAL(8,2),
    credit_card_percentage DECIMAL(5,2),
    avg_passengers_per_trip DECIMAL(4,2),
    anomaly_percentage DECIMAL(5,2)
)
DISTSTYLE KEY 
DISTKEY (pickup_date)
SORTKEY (pickup_date, day_type);

-- ==============================================================================
-- HOURLY PATTERNS TABLE  
-- Hourly analysis by time of day and day type
-- ==============================================================================
CREATE TABLE IF NOT EXISTS analytics.hourly_patterns (
    pickup_hour INTEGER NOT NULL,
    time_of_day_category VARCHAR(10) NOT NULL, -- 'Morning', 'Afternoon', 'Evening', 'Night'
    day_type VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_distance DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    avg_speed DECIMAL(6,2),
    total_revenue DECIMAL(12,2),
    fare_stddev DECIMAL(8,2),
    revenue_per_hour DECIMAL(12,2),
    fare_coefficient_of_variation DECIMAL(6,3)
)
DISTSTYLE KEY
DISTKEY (pickup_hour)
SORTKEY (pickup_hour, time_of_day_category, day_type);

-- ==============================================================================
-- PAYMENT ANALYSIS TABLE
-- Payment method breakdown and tip analysis
-- ==============================================================================
CREATE TABLE IF NOT EXISTS analytics.payment_analysis (
    payment_method VARCHAR(20) NOT NULL,
    day_type VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    total_revenue DECIMAL(12,2) NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_distance DECIMAL(8,2),
    avg_tip DECIMAL(8,2),
    median_fare DECIMAL(8,2),
    median_tip DECIMAL(8,2),
    avg_tip_percentage DECIMAL(5,2)
)
DISTSTYLE KEY
DISTKEY (payment_method)
SORTKEY (payment_method, day_type);

-- ==============================================================================
-- DISTANCE ANALYSIS TABLE
-- Trip distance categories and efficiency metrics
-- ==============================================================================
CREATE TABLE IF NOT EXISTS analytics.distance_analysis (
    distance_category VARCHAR(25) NOT NULL, -- 'Short (≤1 mile)', etc.
    time_of_day_category VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    avg_speed DECIMAL(6,2),
    total_revenue DECIMAL(12,2),
    avg_fare_per_mile DECIMAL(8,2),
    fare_efficiency DECIMAL(8,2)
)
DISTSTYLE KEY
DISTKEY (distance_category)
SORTKEY (distance_category, time_of_day_category);

-- ==============================================================================
-- LOCATION ANALYSIS TABLE
-- Pickup/dropoff location performance
-- ==============================================================================
CREATE TABLE IF NOT EXISTS analytics.location_analysis (
    rate_code_desc VARCHAR(50) NOT NULL,
    day_type VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_distance DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    total_revenue DECIMAL(12,2),
    market_share_rank DECIMAL(10,0)
)
DISTSTYLE KEY
DISTKEY (rate_code_desc)
SORTKEY (rate_code_desc, day_type);

-- ==============================================================================
-- GRANTS AND PERMISSIONS
-- ==============================================================================
-- Grant permissions to analytics schema (adjust user as needed)
-- GRANT USAGE ON SCHEMA analytics TO analytics_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analytics_user;

-- ==============================================================================
-- TABLE INFORMATION AND OPTIMIZATION NOTES
-- ==============================================================================

-- View table information
SELECT 
    schemaname,
    tablename,
    column as column_name,
    type as data_type,
    distkey,
    sortkey
FROM pg_table_def 
WHERE schemaname = 'analytics'
ORDER BY tablename, ordinal_position;

-- Check table sizes after loading data
SELECT 
    trim(pgn.nspname) as schema_name,
    trim(a.name) as table_name,
    ((sum(a.rows) / 1000000.0)) as million_rows,
    sum(a.rows) as total_rows
FROM stv_tbl_perm a
JOIN pg_class pgc ON pgc.oid = a.id
JOIN pg_namespace pgn ON pgn.oid = pgc.relnamespace
WHERE pgn.nspname = 'analytics'
GROUP BY 1, 2
ORDER BY 3 DESC;

/*
OPTIMIZATION NOTES:
===================

1. DISTRIBUTION KEYS:
   - Each table uses DISTSTYLE KEY with the primary grouping column
   - This ensures related data is co-located for efficient joins
   - pickup_date, pickup_hour, payment_method, etc. are natural partition keys

2. SORT KEYS:
   - Sort keys follow query patterns (date ranges, categorical filters)
   - Compound sort keys prioritize most selective columns first
   - This enables zone maps and block skipping for faster queries

3. DATA TYPES:
   - DECIMAL for monetary values with appropriate precision
   - VARCHAR with realistic lengths to save storage
   - INTEGER for hour values, BIGINT for large counts
   - DATE type for date columns enabling date arithmetic

4. LOADING STRATEGY:
   - Use COPY command from S3 for bulk loading
   - Consider UPSERT pattern for incremental updates
   - Analyze tables after major loads for optimal query plans

5. MAINTENANCE:
   - Run VACUUM periodically to reclaim space
   - UPDATE statistics with ANALYZE after data loads
   - Monitor query performance and adjust sort/dist keys as needed
*/ 