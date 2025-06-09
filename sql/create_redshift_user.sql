-- Create new user for Redshift access
-- Run this if you can connect as admin

CREATE USER analytics_user WITH PASSWORD 'AnalyticsPass123!';

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO analytics_user;
GRANT USAGE ON SCHEMA glue_curated TO analytics_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;
GRANT SELECT ON ALL TABLES IN SCHEMA glue_curated TO analytics_user;

-- Show user creation confirmation
SELECT usename, usesysid, usecreatedb, usesuper 
FROM pg_user 
WHERE usename = 'analytics_user'; 