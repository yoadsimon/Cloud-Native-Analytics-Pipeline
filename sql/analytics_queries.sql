-- Analytics Queries for NYC Taxi Curated Data
-- Demonstrates key business insights and data capabilities
-- Use these queries to validate data quality and showcase analytics value

-- ==============================================================================
-- BUSINESS OVERVIEW METRICS
-- ==============================================================================

-- Daily business performance overview
SELECT 
    pickup_date,
    day_type,
    total_trips,
    total_revenue,
    revenue_per_trip,
    avg_fare,
    avg_distance,
    credit_card_percentage,
    anomaly_percentage
FROM analytics.daily_summary
ORDER BY pickup_date DESC;

-- Revenue trends by day type
SELECT 
    day_type,
    COUNT(DISTINCT pickup_date) as days_analyzed,
    AVG(total_trips) as avg_daily_trips,
    AVG(total_revenue) as avg_daily_revenue,
    AVG(revenue_per_trip) as avg_revenue_per_trip,
    MAX(total_revenue) as peak_daily_revenue,
    MIN(total_revenue) as lowest_daily_revenue
FROM analytics.daily_summary
GROUP BY day_type
ORDER BY avg_daily_revenue DESC;

-- ==============================================================================
-- TEMPORAL ANALYSIS - Peak Hours and Patterns
-- ==============================================================================

-- Hourly demand patterns
SELECT 
    pickup_hour,
    time_of_day_category,
    SUM(trip_count) as total_trips,
    AVG(avg_fare) as avg_fare,
    SUM(total_revenue) as total_revenue,
    AVG(avg_speed) as avg_speed_mph
FROM analytics.hourly_patterns
GROUP BY pickup_hour, time_of_day_category
ORDER BY pickup_hour;

-- Peak revenue hours
SELECT 
    pickup_hour,
    time_of_day_category,
    SUM(total_revenue) as hourly_revenue,
    RANK() OVER (ORDER BY SUM(total_revenue) DESC) as revenue_rank
FROM analytics.hourly_patterns
GROUP BY pickup_hour, time_of_day_category
ORDER BY hourly_revenue DESC
LIMIT 10;

-- Speed analysis by time of day (traffic patterns)
SELECT 
    time_of_day_category,
    COUNT(*) as data_points,
    AVG(avg_speed) as avg_speed_mph,
    MIN(avg_speed) as min_speed_mph,
    MAX(avg_speed) as max_speed_mph,
    STDDEV(avg_speed) as speed_variation
FROM analytics.hourly_patterns
GROUP BY time_of_day_category
ORDER BY avg_speed_mph DESC;

-- ==============================================================================
-- PAYMENT METHOD ANALYSIS
-- ==============================================================================

-- Payment preferences and tip analysis
SELECT 
    payment_method,
    SUM(trip_count) as total_trips,
    SUM(total_revenue) as total_revenue,
    AVG(avg_fare) as avg_fare,
    AVG(avg_tip) as avg_tip,
    AVG(avg_tip_percentage) as avg_tip_percentage,
    ROUND(100.0 * SUM(trip_count) / SUM(SUM(trip_count)) OVER (), 2) as market_share_pct
FROM analytics.payment_analysis
GROUP BY payment_method
ORDER BY total_trips DESC;

-- Payment method trends by day type
SELECT 
    payment_method,
    day_type,
    SUM(trip_count) as trips,
    AVG(avg_tip_percentage) as avg_tip_pct,
    AVG(avg_fare) as avg_fare
FROM analytics.payment_analysis
GROUP BY payment_method, day_type
ORDER BY payment_method, day_type;

-- ==============================================================================
-- DISTANCE AND EFFICIENCY ANALYSIS
-- ==============================================================================

-- Trip efficiency by distance category
SELECT 
    distance_category,
    SUM(trip_count) as total_trips,
    AVG(avg_fare) as avg_fare,
    AVG(avg_duration) as avg_duration_min,
    AVG(avg_speed) as avg_speed_mph,
    AVG(fare_efficiency) as fare_efficiency,
    ROUND(100.0 * SUM(trip_count) / SUM(SUM(trip_count)) OVER (), 2) as trip_share_pct
FROM analytics.distance_analysis
GROUP BY distance_category
ORDER BY total_trips DESC;

-- Distance efficiency by time of day
SELECT 
    time_of_day_category,
    COUNT(DISTINCT distance_category) as distance_categories,
    AVG(avg_speed) as avg_speed_mph,
    AVG(fare_efficiency) as avg_fare_efficiency,
    SUM(total_revenue) as total_revenue
FROM analytics.distance_analysis
GROUP BY time_of_day_category
ORDER BY avg_speed_mph DESC;

-- ==============================================================================
-- LOCATION AND RATE CODE ANALYSIS
-- ==============================================================================

-- Performance by rate code (location type)
SELECT 
    rate_code_desc,
    SUM(trip_count) as total_trips,
    AVG(avg_fare) as avg_fare,
    AVG(avg_distance) as avg_distance,
    AVG(avg_duration) as avg_duration,
    SUM(total_revenue) as total_revenue,
    AVG(market_share_rank) as avg_market_rank
FROM analytics.location_analysis
GROUP BY rate_code_desc
ORDER BY total_trips DESC;

-- Weekend vs Weekday location preferences
SELECT 
    rate_code_desc,
    day_type,
    SUM(trip_count) as trips,
    AVG(avg_fare) as avg_fare,
    RANK() OVER (PARTITION BY day_type ORDER BY SUM(trip_count) DESC) as popularity_rank
FROM analytics.location_analysis
GROUP BY rate_code_desc, day_type
ORDER BY rate_code_desc, day_type;

-- ==============================================================================
-- CROSS-TABLE INSIGHTS AND CORRELATIONS
-- ==============================================================================

-- Revenue correlation between payment methods and trip distances
SELECT 
    p.payment_method,
    d.distance_category,
    p.avg_fare as payment_avg_fare,
    d.avg_fare as distance_avg_fare,
    ABS(p.avg_fare - d.avg_fare) as fare_difference,
    CASE 
        WHEN p.avg_fare > d.avg_fare THEN 'Payment Premium'
        WHEN p.avg_fare < d.avg_fare THEN 'Distance Premium'
        ELSE 'Similar Pricing'
    END as pricing_pattern
FROM (
    SELECT payment_method, AVG(avg_fare) as avg_fare
    FROM analytics.payment_analysis 
    GROUP BY payment_method
) p
CROSS JOIN (
    SELECT distance_category, AVG(avg_fare) as avg_fare
    FROM analytics.distance_analysis
    GROUP BY distance_category
) d
ORDER BY fare_difference DESC;

-- Time-based demand patterns
SELECT 
    h.time_of_day_category,
    h.pickup_hour,
    SUM(h.trip_count) as hourly_trips,
    AVG(d.total_trips) as daily_trips,
    ROUND(100.0 * SUM(h.trip_count) / AVG(d.total_trips), 2) as hour_vs_day_pct
FROM analytics.hourly_patterns h
CROSS JOIN (
    SELECT AVG(total_trips) as total_trips
    FROM analytics.daily_summary
) d
GROUP BY h.time_of_day_category, h.pickup_hour
ORDER BY hourly_trips DESC
LIMIT 15;

-- ==============================================================================
-- BUSINESS RECOMMENDATIONS QUERIES
-- ==============================================================================

-- Peak demand hours for driver allocation
SELECT 
    'Peak Demand Hours' as insight_type,
    pickup_hour,
    time_of_day_category,
    SUM(trip_count) as trips,
    'Increase driver availability' as recommendation
FROM analytics.hourly_patterns
GROUP BY pickup_hour, time_of_day_category
HAVING SUM(trip_count) > (
    SELECT AVG(trip_count) * 1.5 
    FROM analytics.hourly_patterns
)
ORDER BY trips DESC;

-- Low-efficiency time slots for optimization
SELECT 
    'Low Efficiency Periods' as insight_type,
    time_of_day_category,
    AVG(avg_speed) as avg_speed_mph,
    'Optimize routing algorithms' as recommendation
FROM analytics.hourly_patterns
GROUP BY time_of_day_category
HAVING AVG(avg_speed) < (
    SELECT AVG(avg_speed) * 0.8
    FROM analytics.hourly_patterns
)
ORDER BY avg_speed_mph;

-- Payment method optimization opportunities
SELECT 
    'Payment Optimization' as insight_type,
    payment_method,
    AVG(avg_tip_percentage) as avg_tip_pct,
    CASE 
        WHEN AVG(avg_tip_percentage) > 15 THEN 'Promote this payment method'
        WHEN AVG(avg_tip_percentage) < 10 THEN 'Improve tip collection'
        ELSE 'Monitor performance'
    END as recommendation
FROM analytics.payment_analysis
GROUP BY payment_method
ORDER BY avg_tip_pct DESC;

-- ==============================================================================
-- DATA QUALITY AND SUMMARY STATISTICS
-- ==============================================================================

-- Overall data summary
SELECT 
    'Data Quality Summary' as report_type,
    (SELECT COUNT(*) FROM analytics.daily_summary) as daily_records,
    (SELECT COUNT(*) FROM analytics.hourly_patterns) as hourly_records,
    (SELECT COUNT(*) FROM analytics.payment_analysis) as payment_records,
    (SELECT COUNT(*) FROM analytics.distance_analysis) as distance_records,
    (SELECT COUNT(*) FROM analytics.location_analysis) as location_records,
    (SELECT SUM(total_trips) FROM analytics.daily_summary) as total_trips_processed,
    (SELECT SUM(total_revenue) FROM analytics.daily_summary) as total_revenue_analyzed;

/*
ANALYTICS INSIGHTS SUMMARY:
===========================

These queries provide:

1. BUSINESS METRICS:
   - Daily/weekly revenue trends
   - Trip volume patterns
   - Payment method preferences

2. OPERATIONAL INSIGHTS:
   - Peak demand hours
   - Traffic pattern analysis
   - Driver efficiency metrics

3. CUSTOMER BEHAVIOR:
   - Tip analysis by payment method
   - Distance preference patterns
   - Time-based usage trends

4. OPTIMIZATION OPPORTUNITIES:
   - Low-efficiency periods
   - Revenue maximization strategies
   - Resource allocation recommendations

5. DATA VALIDATION:
   - Cross-table consistency checks
   - Statistical summaries
   - Quality assurance metrics
*/ 