-- Step 7.2 CORRECTED: Create Analytics Tables Matching Actual Parquet Schema
-- The issue was that partition columns (day_type, etc.) are in directory structure, not in files

-- Drop existing tables and recreate with correct schema
DROP TABLE IF EXISTS analytics.daily_summary;
DROP TABLE IF EXISTS analytics.hourly_patterns;
DROP TABLE IF EXISTS analytics.payment_analysis;
DROP TABLE IF EXISTS analytics.distance_analysis;
DROP TABLE IF EXISTS analytics.location_analysis;

-- 1. Daily Summary Table (day_type is partition, not column)
CREATE TABLE analytics.daily_summary (
    pickup_date DATE NOT NULL,
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
DISTSTYLE KEY DISTKEY (pickup_date) SORTKEY (pickup_date);

-- 2. Hourly Patterns Table (day_type and time_of_day_category are partitions)
CREATE TABLE analytics.hourly_patterns (
    pickup_hour INTEGER NOT NULL,
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
DISTSTYLE KEY DISTKEY (pickup_hour) SORTKEY (pickup_hour);

-- 3. Payment Analysis Table (payment_method is partition)
CREATE TABLE analytics.payment_analysis (
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
DISTSTYLE EVEN SORTKEY (day_type);

-- 4. Distance Analysis Table (distance_category is partition)
CREATE TABLE analytics.distance_analysis (
    time_of_day_category VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    avg_speed DECIMAL(6,2),
    total_revenue DECIMAL(12,2),
    avg_fare_per_mile DECIMAL(8,2),
    fare_efficiency DECIMAL(8,2)
)
DISTSTYLE EVEN SORTKEY (time_of_day_category);

-- 5. Location Analysis Table (rate_code_desc is partition)
CREATE TABLE analytics.location_analysis (
    day_type VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_distance DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    total_revenue DECIMAL(12,2),
    market_share_rank DECIMAL(10,0)
)
DISTSTYLE EVEN SORTKEY (day_type);

-- Verify corrected tables
SELECT 
    schemaname,
    tablename,
    'Corrected table created' as status
FROM pg_table_def 
WHERE schemaname = 'analytics'
GROUP BY schemaname, tablename
ORDER BY tablename; 