"""
Cloud-Native Analytics Pipeline Dashboard
Interactive demo dashboard showcasing NYC Taxi data analytics
"""
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from datetime import datetime, timedelta
import numpy as np

from config import DASHBOARD_CONFIG, COLORS, METRICS_CONFIG
from database import RedshiftConnection, ANALYTICS_QUERIES

# Page configuration
st.set_page_config(
    page_title=DASHBOARD_CONFIG['title'],
    page_icon=DASHBOARD_CONFIG['page_icon'],
    layout=DASHBOARD_CONFIG['layout'],
    initial_sidebar_state="expanded"
)

# Initialize database connection
@st.cache_resource
def init_database():
    return RedshiftConnection()

def format_number(num, format_type='number'):
    """Format numbers for display"""
    if pd.isna(num):
        return "N/A"
    
    if format_type == 'currency':
        return f"${num:,.2f}"
    elif format_type == 'percentage':
        return f"{num:.1f}%"
    elif format_type == 'integer':
        return f"{num:,.0f}"
    else:
        return f"{num:,.2f}"

def create_kpi_card(title, value, format_type='number', delta=None):
    """Create a KPI display card"""
    formatted_value = format_number(value, format_type)
    
    if delta:
        delta_color = "normal" if delta >= 0 else "inverse"
        st.metric(title, formatted_value, delta=f"{delta:+.1f}%", delta_color=delta_color)
    else:
        st.metric(title, formatted_value)

def plot_daily_trends(df):
    """Create daily trends visualization"""
    fig = make_subplots(
        rows=2, cols=1,
        subplot_titles=('Daily Trip Volume', 'Daily Revenue'),
        vertical_spacing=0.1,
        specs=[[{"secondary_y": False}], [{"secondary_y": False}]]
    )
    
    # Trip volume
    fig.add_trace(
        go.Scatter(
            x=df['trip_date'], 
            y=df['total_trips'],
            mode='lines+markers',
            name='Total Trips',
            line=dict(color=COLORS['primary'], width=3),
            marker=dict(size=6)
        ),
        row=1, col=1
    )
    
    # Revenue
    fig.add_trace(
        go.Scatter(
            x=df['trip_date'], 
            y=df['total_revenue'],
            mode='lines+markers',
            name='Total Revenue',
            line=dict(color=COLORS['success'], width=3),
            marker=dict(size=6)
        ),
        row=2, col=1
    )
    
    fig.update_layout(
        height=500,
        title_text="Daily Performance Trends",
        showlegend=False
    )
    
    fig.update_xaxes(title_text="Date")
    fig.update_yaxes(title_text="Number of Trips", row=1, col=1)
    fig.update_yaxes(title_text="Revenue ($)", row=2, col=1)
    
    return fig

def plot_hourly_patterns(df):
    """Create hourly demand patterns visualization"""
    fig = px.bar(
        df, 
        x='hour_of_day', 
        y='total_trips',
        color='time_of_day_category',
        title='Hourly Demand Patterns',
        labels={'hour_of_day': 'Hour of Day', 'total_trips': 'Total Trips'},
        color_discrete_sequence=px.colors.qualitative.Set3
    )
    
    fig.update_layout(height=400)
    return fig

def plot_payment_distribution(df):
    """Create payment method distribution pie chart"""
    fig = px.pie(
        df, 
        values='market_share_percent', 
        names='payment_method',
        title='Payment Method Distribution',
        color_discrete_sequence=px.colors.qualitative.Pastel
    )
    
    fig.update_traces(textposition='inside', textinfo='percent+label')
    fig.update_layout(height=400)
    return fig

def plot_distance_vs_fare(df):
    """Create distance vs fare analysis"""
    fig = go.Figure()
    
    # Add bar chart for trips
    fig.add_trace(go.Bar(
        x=df['distance_category'],
        y=df['total_trips'],
        name='Total Trips',
        yaxis='y',
        marker_color=COLORS['primary']
    ))
    
    # Add line chart for fare per mile
    fig.add_trace(go.Scatter(
        x=df['distance_category'],
        y=df['fare_per_mile'],
        mode='lines+markers',
        name='Fare per Mile',
        yaxis='y2',
        line=dict(color=COLORS['warning'], width=3),
        marker=dict(size=8)
    ))
    
    # Create axis objects
    fig.update_layout(
        title='Distance Categories: Volume vs Efficiency',
        xaxis=dict(title='Distance Category'),
        yaxis=dict(title='Total Trips', side='left'),
        yaxis2=dict(title='Fare per Mile ($)', side='right', overlaying='y'),
        legend=dict(x=0.7, y=1),
        height=400
    )
    
    return fig

def plot_location_performance(df):
    """Create location performance chart"""
    df_top = df.head(5)  # Top 5 rate codes
    
    fig = px.bar(
        df_top,
        x='rate_code_desc',
        y='total_revenue',
        color='avg_fare_per_trip',
        title='Top 5 Rate Codes by Revenue',
        labels={'rate_code_desc': 'Rate Code', 'total_revenue': 'Total Revenue ($)'},
        color_continuous_scale='viridis'
    )
    
    fig.update_layout(height=400)
    return fig

def main():
    """Main dashboard application"""
    
    # Header
    st.title(f"{DASHBOARD_CONFIG['page_icon']} {DASHBOARD_CONFIG['title']}")
    st.subheader(DASHBOARD_CONFIG['subtitle'])
    
    # Initialize database
    db = init_database()
    
    # Sidebar
    st.sidebar.title("🔧 Dashboard Controls")
    
    # Connection status
    with st.sidebar:
        st.subheader("📊 Connection Status")
        if db.test_connection():
            st.success("✅ Connected to Redshift")
        else:
            st.error("❌ Connection Failed")
            st.stop()
    
    # Refresh button
    if st.sidebar.button("🔄 Refresh Data"):
        st.cache_data.clear()
        st.experimental_rerun()
    
    # Data info
    with st.sidebar:
        st.subheader("📈 Data Summary")
        kpi_data = db.query_data(ANALYTICS_QUERIES['kpi_summary'])
        if not kpi_data.empty:
            st.write(f"**Total Records:** {format_number(kpi_data.iloc[0]['total_trips'], 'integer')}")
            st.write(f"**Date Range:** {kpi_data.iloc[0]['days_analyzed']} days")
            st.write(f"**Latest Data:** {kpi_data.iloc[0]['latest_date']}")
    
    # Main dashboard content
    st.markdown("---")
    
    # KPI Section
    st.header("📊 Key Performance Indicators")
    
    kpi_data = db.query_data(ANALYTICS_QUERIES['kpi_summary'])
    
    if not kpi_data.empty:
        row = kpi_data.iloc[0]
        
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            create_kpi_card("Total Trips", row['total_trips'], 'integer')
        
        with col2:
            create_kpi_card("Total Revenue", row['total_revenue'], 'currency')
        
        with col3:
            create_kpi_card("Average Fare", row['avg_fare'], 'currency')
        
        with col4:
            create_kpi_card("Analysis Period", row['days_analyzed'], 'integer')
        
        with col5:
            # Calculate data freshness
            latest_date = pd.to_datetime(row['latest_date'])
            days_old = (datetime.now() - latest_date).days
            create_kpi_card("Data Freshness", days_old, 'integer')
    
    st.markdown("---")
    
    # Charts Section
    st.header("📈 Business Analytics")
    
    # Row 1: Daily trends and hourly patterns
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📅 Daily Trends")
        daily_data = db.query_data(ANALYTICS_QUERIES['daily_trends'])
        if not daily_data.empty:
            fig = plot_daily_trends(daily_data)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No daily trends data available")
    
    with col2:
        st.subheader("🕐 Hourly Demand Patterns")
        hourly_data = db.query_data(ANALYTICS_QUERIES['hourly_patterns'])
        if not hourly_data.empty:
            fig = plot_hourly_patterns(hourly_data)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No hourly patterns data available")
    
    # Row 2: Payment analysis and distance analysis
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("💳 Payment Method Distribution")
        payment_data = db.query_data(ANALYTICS_QUERIES['payment_analysis'])
        if not payment_data.empty:
            fig = plot_payment_distribution(payment_data)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No payment analysis data available")
    
    with col2:
        st.subheader("📏 Distance vs Fare Analysis")
        distance_data = db.query_data(ANALYTICS_QUERIES['distance_analysis'])
        if not distance_data.empty:
            fig = plot_distance_vs_fare(distance_data)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No distance analysis data available")
    
    # Row 3: Location performance (full width)
    st.subheader("🗺️ Location Performance Analysis")
    location_data = db.query_data(ANALYTICS_QUERIES['location_performance'])
    if not location_data.empty:
        fig = plot_location_performance(location_data)
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("No location performance data available")
    
    # Data Tables Section
    st.markdown("---")
    st.header("📋 Detailed Data Views")
    
    tab1, tab2, tab3, tab4 = st.tabs(["Daily Metrics", "Payment Analysis", "Location Analytics", "Distance Summary"])
    
    with tab1:
        if not daily_data.empty:
            st.dataframe(daily_data, use_container_width=True)
        else:
            st.warning("No data available")
    
    with tab2:
        if not payment_data.empty:
            st.dataframe(payment_data, use_container_width=True)
        else:
            st.warning("No data available")
    
    with tab3:
        if not location_data.empty:
            st.dataframe(location_data, use_container_width=True)
        else:
            st.warning("No data available")
    
    with tab4:
        if not distance_data.empty:
            st.dataframe(distance_data, use_container_width=True)
        else:
            st.warning("No data available")
    
    # Footer
    st.markdown("---")
    st.markdown("""
    **🚀 Cloud-Native Analytics Pipeline Dashboard**
    
    This dashboard demonstrates enterprise-grade data engineering capabilities including:
    - **Real-time data processing** with AWS Glue ETL jobs
    - **Scalable storage** with partitioned Parquet in S3
    - **High-performance analytics** with Redshift Serverless
    - **Interactive visualization** with Streamlit and Plotly
    - **Production monitoring** with CloudWatch and SNS alerts
    
    *Built for Similarweb Data Engineer Interview - Portfolio Showcase*
    """)

if __name__ == "__main__":
    main() 