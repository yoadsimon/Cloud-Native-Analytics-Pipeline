"""
Configuration settings for the Cloud-Native Analytics Dashboard
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Redshift Connection Settings
REDSHIFT_CONFIG = {
    'host': 'cloud-native-analytics-workgroup.439530517237.us-east-1.redshift-serverless.amazonaws.com',
    'port': 5439,
    'database': 'analytics_db',
    'username': 'admin',
    'password': os.getenv('REDSHIFT_PASSWORD', 'TempPassword123!'),
    'schema': 'glue_curated'
}

# Dashboard Configuration
DASHBOARD_CONFIG = {
    'title': 'Cloud-Native Analytics Pipeline',
    'subtitle': 'NYC Taxi Data Intelligence Dashboard',
    'page_icon': '🚖',
    'layout': 'wide',
    'theme': 'light'
}

# Business Metrics Configuration
METRICS_CONFIG = {
    'kpis': [
        'Total Trips',
        'Total Revenue', 
        'Average Fare',
        'Top Rate Code',
        'Peak Hour'
    ],
    'charts': [
        'Daily Revenue Trends',
        'Hourly Demand Patterns', 
        'Payment Method Distribution',
        'Distance vs Fare Analysis',
        'Location Performance'
    ]
}

# Color Palette
COLORS = {
    'primary': '#1f77b4',
    'secondary': '#ff7f0e', 
    'success': '#2ca02c',
    'warning': '#d62728',
    'info': '#9467bd',
    'background': '#f8f9fa'
} 