-- Step 7.2: Create Analytics Tables in Redshift
-- Execute this script in AWS Query Editor v2
-- Copy and paste each section, execute one by one

-- 1. Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- 2. Create daily_summary table
CREATE TABLE IF NOT EXISTS analytics.daily_summary (
    pickup_date DATE NOT NULL,
    day_type VARCHAR(10) NOT NULL,
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
DISTSTYLE KEY DISTKEY (pickup_date) SORTKEY (pickup_date, day_type);

-- 3. Create hourly_patterns table
CREATE TABLE IF NOT EXISTS analytics.hourly_patterns (
    pickup_hour INTEGER NOT NULL,
    time_of_day_category VARCHAR(10) NOT NULL,
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
DISTSTYLE KEY DISTKEY (pickup_hour) SORTKEY (pickup_hour, time_of_day_category, day_type);

-- 4. Create payment_analysis table
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
DISTSTYLE KEY DISTKEY (payment_method) SORTKEY (payment_method, day_type);

-- 5. Create distance_analysis table
CREATE TABLE IF NOT EXISTS analytics.distance_analysis (
    distance_category VARCHAR(25) NOT NULL,
    time_of_day_category VARCHAR(10) NOT NULL,
    trip_count BIGINT NOT NULL,
    avg_fare DECIMAL(8,2),
    avg_duration DECIMAL(8,2),
    avg_speed DECIMAL(6,2),
    total_revenue DECIMAL(12,2),
    avg_fare_per_mile DECIMAL(8,2),
    fare_efficiency DECIMAL(8,2)
)
DISTSTYLE KEY DISTKEY (distance_category) SORTKEY (distance_category, time_of_day_category);

-- 6. Create location_analysis table
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
DISTSTYLE KEY DISTKEY (rate_code_desc) SORTKEY (rate_code_desc, day_type);

-- 7. Verify tables were created
SELECT 
    schemaname,
    tablename,
    'Table created successfully' as status
FROM pg_table_def 
WHERE schemaname = 'analytics'
GROUP BY schemaname, tablename
ORDER BY tablename; 