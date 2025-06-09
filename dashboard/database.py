"""
Database connection utilities for Redshift
"""
import pandas as pd
import psycopg2
from sqlalchemy import create_engine
import streamlit as st
from config import REDSHIFT_CONFIG

class RedshiftConnection:
    """Handles Redshift database connections and queries"""
    
    def __init__(self):
        self.config = REDSHIFT_CONFIG
        self.connection_string = self._build_connection_string()
        self.engine = None
    
    def _build_connection_string(self):
        """Build SQLAlchemy connection string"""
        return (
            f"postgresql://{self.config['username']}:{self.config['password']}"
            f"@{self.config['host']}:{self.config['port']}/{self.config['database']}"
        )
    
    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def query_data(_self, query, params=None):
        """Execute query and return DataFrame"""
        try:
            if _self.engine is None:
                _self.engine = create_engine(_self.connection_string)
            
            df = pd.read_sql_query(query, _self.engine, params=params)
            return df
        except Exception as e:
            st.error(f"Database query failed: {str(e)}")
            return pd.DataFrame()
    
    def test_connection(self):
        """Test database connectivity"""
        try:
            test_query = "SELECT 1 as test"
            result = self.query_data(test_query)
            return not result.empty
        except:
            return False
    
    def get_table_info(self):
        """Get information about available tables"""
        query = f"""
        SELECT 
            table_name,
            column_name,
            data_type
        FROM information_schema.columns 
        WHERE table_schema = '{self.config['schema']}'
        ORDER BY table_name, ordinal_position
        """
        return self.query_data(query)

# Pre-defined analytical queries
ANALYTICS_QUERIES = {
    'kpi_summary': """
        SELECT 
            SUM(total_trips) as total_trips,
            SUM(total_revenue) as total_revenue,
            AVG(avg_fare_per_trip) as avg_fare,
            COUNT(DISTINCT trip_date) as days_analyzed,
            MAX(trip_date) as latest_date,
            MIN(trip_date) as earliest_date
        FROM glue_curated.daily_metrics
    """,
    
    'daily_trends': """
        SELECT 
            trip_date,
            day_type,
            total_trips,
            total_revenue,
            avg_fare_per_trip,
            avg_distance_per_trip
        FROM glue_curated.daily_metrics
        ORDER BY trip_date
    """,
    
    'hourly_patterns': """
        SELECT 
            hour_of_day,
            time_of_day_category,
            SUM(total_trips) as total_trips,
            AVG(avg_fare_amount) as avg_fare,
            AVG(avg_trip_distance) as avg_distance
        FROM glue_curated.time_series_analysis
        GROUP BY hour_of_day, time_of_day_category
        ORDER BY hour_of_day
    """,
    
    'payment_analysis': """
        SELECT 
            payment_method,
            total_trips,
            total_fare_amount,
            avg_fare_per_trip,
            avg_tip_percentage,
            market_share_percent
        FROM glue_curated.customer_behavior
        ORDER BY market_share_percent DESC
    """,
    
    'location_performance': """
        SELECT 
            rate_code_desc,
            total_trips,
            total_revenue,
            avg_fare_per_trip,
            avg_distance_per_trip,
            market_share_percent
        FROM glue_curated.location_analytics
        ORDER BY market_share_percent DESC
        LIMIT 10
    """,
    
    'distance_analysis': """
        SELECT 
            distance_category,
            total_trips,
            avg_fare_amount,
            avg_trip_distance,
            fare_per_mile
        FROM glue_curated.performance_summary
        ORDER BY 
            CASE distance_category
                WHEN 'Short (0-2 miles)' THEN 1
                WHEN 'Medium (2-5 miles)' THEN 2
                WHEN 'Long (5-10 miles)' THEN 3
                WHEN 'Very Long (10+ miles)' THEN 4
                ELSE 5
            END
    """
} 