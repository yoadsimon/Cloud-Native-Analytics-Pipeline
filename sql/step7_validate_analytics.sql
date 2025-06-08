-- Step 7.4: Validate Analytics Pipeline with Key Business Queries
-- Execute these queries to demonstrate our data capabilities

-- 1. Business Overview - Daily Performance
SELECT 
    pickup_date,
    day_type,
    total_trips,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(revenue_per_trip, 2) as revenue_per_trip,
    ROUND(credit_card_percentage, 1) as credit_card_pct
FROM analytics.daily_summary
ORDER BY pickup_date DESC
LIMIT 10;

-- 2. Peak Hours Analysis
SELECT 
    pickup_hour,
    time_of_day_category,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_fare,
    ROUND(AVG(avg_speed), 1) as avg_speed_mph
FROM analytics.hourly_patterns
GROUP BY pickup_hour, time_of_day_category
ORDER BY total_trips DESC
LIMIT 10;

-- 3. Payment Method Insights
SELECT 
    payment_method,
    SUM(trip_count) as total_trips,
    ROUND(SUM(total_revenue), 2) as total_revenue,
    ROUND(AVG(avg_tip_percentage), 1) as avg_tip_pct,
    ROUND(100.0 * SUM(trip_count) / SUM(SUM(trip_count)) OVER (), 1) as market_share_pct
FROM analytics.payment_analysis
GROUP BY payment_method
ORDER BY total_trips DESC;

-- 4. Trip Distance Efficiency
SELECT 
    distance_category,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_fare,
    ROUND(AVG(avg_speed), 1) as avg_speed_mph,
    ROUND(AVG(fare_efficiency), 2) as fare_efficiency
FROM analytics.distance_analysis
GROUP BY distance_category
ORDER BY total_trips DESC;

-- 5. Location Performance
SELECT 
    rate_code_desc,
    SUM(trip_count) as total_trips,
    ROUND(AVG(avg_fare), 2) as avg_fare,
    ROUND(AVG(avg_distance), 1) as avg_distance_miles
FROM analytics.location_analysis
GROUP BY rate_code_desc
ORDER BY total_trips DESC;

-- 6. Revenue Trends by Day Type
SELECT 
    day_type,
    COUNT(DISTINCT pickup_date) as days_analyzed,
    ROUND(AVG(total_trips), 0) as avg_daily_trips,
    ROUND(AVG(total_revenue), 2) as avg_daily_revenue,
    ROUND(MAX(total_revenue), 2) as peak_daily_revenue
FROM analytics.daily_summary
GROUP BY day_type
ORDER BY avg_daily_revenue DESC;

-- 7. Performance Summary
SELECT 
    'Analytics Pipeline Summary' as metric_type,
    'Total Tables: 5, Total Records: ' || 
    (SELECT SUM(cnt) FROM (
        SELECT COUNT(*) as cnt FROM analytics.daily_summary
        UNION ALL SELECT COUNT(*) FROM analytics.hourly_patterns
        UNION ALL SELECT COUNT(*) FROM analytics.payment_analysis
        UNION ALL SELECT COUNT(*) FROM analytics.distance_analysis
        UNION ALL SELECT COUNT(*) FROM analytics.location_analysis
    )) ||
    ', Data Period: ' ||
    (SELECT 
        TO_CHAR(MIN(pickup_date), 'Mon DD') || ' - ' || 
        TO_CHAR(MAX(pickup_date), 'Mon DD, YYYY')
     FROM analytics.daily_summary) as summary; 