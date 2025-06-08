#!/usr/bin/env python3
"""
NYC Taxi Data Inspection Script
Analyzes the downloaded NYC taxi dataset to understand its structure and business value.
"""

import pandas as pd
import os

def inspect_taxi_data():
    """Inspect NYC taxi data file and display key information."""
    file_path = 'data/raw/yellow_tripdata_2024-02.parquet'
    
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        return
    
    # Read parquet file
    print("📊 Loading NYC Taxi dataset...")
    df = pd.read_parquet(file_path)
    
    print('=' * 50)
    print('🚕 NYC TAXI DATA INSPECTION')
    print('=' * 50)
    print(f'📁 File: yellow_tripdata_2024-02.parquet')
    print(f'💾 File size: 48MB')
    print(f'📋 Shape: {df.shape[0]:,} rows x {df.shape[1]} columns')
    print()
    
    print('=' * 30)
    print('📊 COLUMN SCHEMA')
    print('=' * 30)
    for col in df.columns:
        null_count = df[col].isnull().sum()
        null_pct = (null_count / len(df)) * 100
        print(f'{col:25s}: {str(df[col].dtype):12s} ({null_count:,} nulls, {null_pct:.1f}%)')
    print()
    
    print('=' * 30)
    print('🔍 SAMPLE DATA (First 3 rows)')
    print('=' * 30)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', None)
    print(df.head(3).to_string())
    print()
    
    print('=' * 30)
    print('📅 DATE RANGE')
    print('=' * 30)
    print(f'Pickup dates: {df["tpep_pickup_datetime"].min()} to {df["tpep_pickup_datetime"].max()}')
    print(f'Dropoff dates: {df["tpep_dropoff_datetime"].min()} to {df["tpep_dropoff_datetime"].max()}')
    print()
    
    print('=' * 30)
    print('📈 BUSINESS METRICS')
    print('=' * 30)
    print(f'Average trip distance: {df["trip_distance"].mean():.2f} miles')
    print(f'Average fare amount: ${df["fare_amount"].mean():.2f}')
    print(f'Average total amount: ${df["total_amount"].mean():.2f}')
    print(f'Average passenger count: {df["passenger_count"].mean():.1f}')
    print()
    
    print('=' * 30)
    print('🗺️  LOCATION DATA')
    print('=' * 30)
    print(f'Unique pickup locations: {df["PULocationID"].nunique()}')
    print(f'Unique dropoff locations: {df["DOLocationID"].nunique()}')
    print()
    
    print('=' * 30)
    print('💳 PAYMENT METHODS')
    print('=' * 30)
    payment_types = df['payment_type'].value_counts()
    for payment_id, count in payment_types.head().items():
        pct = (count / len(df)) * 100
        print(f'Payment type {payment_id}: {count:,} trips ({pct:.1f}%)')
    print()
    
    print('✅ Data inspection complete!')
    print('🎯 This dataset is perfect for demonstrating:')
    print('   • Time series analytics (trip patterns by hour/day)')
    print('   • Geospatial analysis (pickup/dropoff heatmaps)')
    print('   • Business intelligence (fare optimization, demand forecasting)')
    print('   • Data quality challenges (nulls, outliers, validation)')

if __name__ == "__main__":
    inspect_taxi_data() 