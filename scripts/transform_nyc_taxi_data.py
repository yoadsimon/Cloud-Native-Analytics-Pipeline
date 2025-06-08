#!/usr/bin/env python3
"""
NYC Taxi Data Transformation Pipeline
Production PySpark job for cleaning, enriching, and staging NYC taxi data.

This script demonstrates enterprise-level data engineering practices:
- S3 integration with AWS credentials
- Data quality validation and cleaning
- Business logic transformations
- Performance optimizations
- Proper error handling and logging
"""

import os
import sys
import logging
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, when, isnan, isnull, lit, round as spark_round,
    unix_timestamp, from_unixtime, hour, dayofweek, 
    date_format, regexp_replace, trim, upper,
    avg, min, max, count, stddev
)
from pyspark.sql.types import DoubleType, IntegerType, StringType

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class NYCTaxiTransformer:
    """Handles PySpark transformations for NYC Taxi data."""
    
    def __init__(self, aws_profile: str = 'cloud-native-analytics'):
        self.aws_profile = aws_profile
        self.spark = None
        self.bucket_name = "cloud-native-analytics-pipeline-d8e6ca17"
        
        # Data quality thresholds
        self.MAX_TRIP_DISTANCE = 100.0  # miles
        self.MAX_TRIP_DURATION = 3600   # seconds (1 hour)
        self.MIN_FARE_AMOUNT = 0.0      # USD
        self.MAX_FARE_AMOUNT = 500.0    # USD
        
    def create_spark_session(self) -> SparkSession:
        """Create optimized Spark session with S3 configuration."""
        try:
            # AWS credentials setup
            os.environ['AWS_PROFILE'] = self.aws_profile
            
            spark = SparkSession.builder \
                .appName("NYC-Taxi-Data-Transformation") \
                .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
                .config("spark.sql.adaptive.enabled", "true") \
                .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
                .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
                .config("spark.hadoop.fs.s3a.aws.credentials.provider", 
                       "com.amazonaws.auth.profile.ProfileCredentialsProvider") \
                .getOrCreate()
            
            # Set log level to reduce noise
            spark.sparkContext.setLogLevel("WARN")
            
            logger.info(f"✅ Spark session created successfully")
            logger.info(f"📊 Spark version: {spark.version}")
            logger.info(f"🖥️  Available cores: {spark.sparkContext.defaultParallelism}")
            
            self.spark = spark
            return spark
            
        except Exception as e:
            logger.error(f"❌ Failed to create Spark session: {e}")
            raise
    
    def read_raw_data(self, year: int = 2024, month: int = 2) -> 'DataFrame':
        """Read raw taxi data from S3."""
        s3_path = f"s3a://{self.bucket_name}/raw/dataset=nyc_taxi/year={year}/month={month:02d}/"
        
        logger.info(f"📖 Reading data from: {s3_path}")
        
        try:
            df = self.spark.read.parquet(s3_path)
            
            record_count = df.count()
            logger.info(f"📋 Loaded {record_count:,} records from raw data")
            
            return df
            
        except Exception as e:
            logger.error(f"❌ Failed to read data from {s3_path}: {e}")
            raise
    
    def clean_data(self, df: 'DataFrame') -> 'DataFrame':
        """Apply data cleaning and quality rules."""
        logger.info("🧹 Starting data cleaning...")
        
        original_count = df.count()
        
        # Remove records with null pickup/dropoff times
        df_clean = df.filter(
            col("tpep_pickup_datetime").isNotNull() & 
            col("tpep_dropoff_datetime").isNotNull()
        )
        
        # Remove invalid trip distances
        df_clean = df_clean.filter(
            (col("trip_distance") >= 0) & 
            (col("trip_distance") <= self.MAX_TRIP_DISTANCE)
        )
        
        # Remove invalid fare amounts
        df_clean = df_clean.filter(
            (col("fare_amount") >= self.MIN_FARE_AMOUNT) & 
            (col("fare_amount") <= self.MAX_FARE_AMOUNT)
        )
        
        # Remove negative total amounts
        df_clean = df_clean.filter(col("total_amount") >= 0)
        
        # Handle null passenger counts (fill with 1 as default)
        df_clean = df_clean.withColumn(
            "passenger_count",
            when(col("passenger_count").isNull() | (col("passenger_count") == 0), 1)
            .otherwise(col("passenger_count"))
        )
        
        # Validate pickup comes before dropoff
        df_clean = df_clean.filter(
            col("tpep_pickup_datetime") < col("tpep_dropoff_datetime")
        )
        
        final_count = df_clean.count()
        removed_count = original_count - final_count
        removal_pct = (removed_count / original_count) * 100
        
        logger.info(f"📊 Data cleaning results:")
        logger.info(f"   • Original records: {original_count:,}")
        logger.info(f"   • Clean records: {final_count:,}")
        logger.info(f"   • Removed: {removed_count:,} ({removal_pct:.2f}%)")
        
        return df_clean
    
    def add_derived_columns(self, df: 'DataFrame') -> 'DataFrame':
        """Add business logic and derived columns."""
        logger.info("⚙️ Adding derived columns...")
        
        df_enriched = df \
            .withColumn(
                "trip_duration_minutes",
                spark_round(
                    (unix_timestamp("tpep_dropoff_datetime") - 
                     unix_timestamp("tpep_pickup_datetime")) / 60, 2
                )
            ) \
            .withColumn(
                "pickup_hour", 
                hour("tpep_pickup_datetime")
            ) \
            .withColumn(
                "pickup_day_of_week",
                dayofweek("tpep_pickup_datetime")
            ) \
            .withColumn(
                "pickup_date",
                date_format("tpep_pickup_datetime", "yyyy-MM-dd")
            ) \
            .withColumn(
                "time_of_day_category",
                when(col("pickup_hour").between(6, 11), "Morning")
                .when(col("pickup_hour").between(12, 17), "Afternoon") 
                .when(col("pickup_hour").between(18, 22), "Evening")
                .otherwise("Night")
            ) \
            .withColumn(
                "day_type",
                when(col("pickup_day_of_week").isin([1, 7]), "Weekend")
                .otherwise("Weekday")
            ) \
            .withColumn(
                "speed_mph",
                when(col("trip_duration_minutes") > 0,
                     spark_round((col("trip_distance") / col("trip_duration_minutes")) * 60, 2))
                .otherwise(0)
            ) \
            .withColumn(
                "fare_per_mile",
                when(col("trip_distance") > 0,
                     spark_round(col("fare_amount") / col("trip_distance"), 2))
                .otherwise(0)
            ) \
            .withColumn(
                "tip_percentage",
                when(col("fare_amount") > 0,
                     spark_round((col("tip_amount") / col("fare_amount")) * 100, 2))
                .otherwise(0)
            ) \
            .withColumn(
                "payment_method",
                when(col("payment_type") == 1, "Credit Card")
                .when(col("payment_type") == 2, "Cash") 
                .when(col("payment_type") == 3, "No Charge")
                .when(col("payment_type") == 4, "Dispute")
                .otherwise("Unknown")
            ) \
            .withColumn(
                "trip_category",
                when(col("trip_distance") < 1, "Short")
                .when(col("trip_distance").between(1, 5), "Medium")
                .when(col("trip_distance").between(5, 15), "Long")
                .otherwise("Extra Long")
            )
        
        # Filter out unrealistic speeds (likely data quality issues)
        df_enriched = df_enriched.filter(col("speed_mph") <= 80)
        
        logger.info("✅ Derived columns added successfully")
        
        return df_enriched
    
    def add_data_quality_flags(self, df: 'DataFrame') -> 'DataFrame':
        """Add data quality flags for monitoring and analysis."""
        logger.info("🚩 Adding data quality flags...")
        
        df_flagged = df \
            .withColumn(
                "quality_flag_speed",
                when(col("speed_mph") > 50, "High Speed")
                .when(col("speed_mph") < 0.5, "Very Slow")
                .otherwise("Normal")
            ) \
            .withColumn(
                "quality_flag_fare",
                when(col("fare_per_mile") > 10, "High Fare Rate")
                .when(col("fare_per_mile") < 1, "Low Fare Rate") 
                .otherwise("Normal")
            ) \
            .withColumn(
                "quality_flag_duration",
                when(col("trip_duration_minutes") > 60, "Long Trip")
                .when(col("trip_duration_minutes") < 1, "Very Short")
                .otherwise("Normal")
            )
        
        return df_flagged
    
    def write_to_staging(self, df: 'DataFrame', year: int = 2024, month: int = 2):
        """Write transformed data to S3 staging layer."""
        s3_output_path = f"s3a://{self.bucket_name}/staging/dataset=nyc_taxi_processed/year={year}/month={month:02d}/"
        
        logger.info(f"💾 Writing to staging: {s3_output_path}")
        
        try:
            # Write with partitioning for query performance
            df.coalesce(4) \
              .write \
              .mode("overwrite") \
              .partitionBy("pickup_date", "time_of_day_category") \
              .parquet(s3_output_path)
            
            logger.info("✅ Data successfully written to staging")
            
        except Exception as e:
            logger.error(f"❌ Failed to write to staging: {e}")
            raise
    
    def print_summary_stats(self, df: 'DataFrame'):
        """Print summary statistics for validation."""
        logger.info("📊 Computing summary statistics...")
        
        summary = df.agg(
            count("*").alias("total_records"),
            avg("trip_distance").alias("avg_distance"),
            avg("trip_duration_minutes").alias("avg_duration"),
            avg("fare_amount").alias("avg_fare"),
            avg("tip_percentage").alias("avg_tip_pct"),
            avg("speed_mph").alias("avg_speed")
        ).collect()[0]
        
        logger.info("=" * 50)
        logger.info("📈 TRANSFORMATION SUMMARY STATISTICS")
        logger.info("=" * 50)
        logger.info(f"Total Records: {summary['total_records']:,}")
        logger.info(f"Average Distance: {summary['avg_distance']:.2f} miles")
        logger.info(f"Average Duration: {summary['avg_duration']:.2f} minutes") 
        logger.info(f"Average Fare: ${summary['avg_fare']:.2f}")
        logger.info(f"Average Tip %: {summary['avg_tip_pct']:.1f}%")
        logger.info(f"Average Speed: {summary['avg_speed']:.1f} mph")
        logger.info("=" * 50)
        
        # Show sample of transformed data
        logger.info("🔍 Sample of transformed data:")
        df.select(
            "pickup_date", "time_of_day_category", "trip_category",
            "trip_distance", "trip_duration_minutes", "fare_amount", 
            "payment_method", "tip_percentage"
        ).show(5, truncate=False)
    
    def run_transformation_pipeline(self, year: int = 2024, month: int = 2):
        """Execute the complete transformation pipeline."""
        logger.info("🚀 Starting NYC Taxi Data Transformation Pipeline")
        logger.info(f"📅 Processing data for {year}-{month:02d}")
        
        try:
            # Step 1: Create Spark session
            self.create_spark_session()
            
            # Step 2: Read raw data
            raw_df = self.read_raw_data(year, month)
            
            # Step 3: Clean data
            clean_df = self.clean_data(raw_df)
            
            # Step 4: Add derived columns
            enriched_df = self.add_derived_columns(clean_df)
            
            # Step 5: Add quality flags
            final_df = self.add_data_quality_flags(enriched_df)
            
            # Step 6: Cache for performance
            final_df.cache()
            
            # Step 7: Print summary statistics
            self.print_summary_stats(final_df)
            
            # Step 8: Write to staging
            self.write_to_staging(final_df, year, month)
            
            logger.info("🎉 Transformation pipeline completed successfully!")
            
        except Exception as e:
            logger.error(f"❌ Pipeline failed: {e}")
            raise
            
        finally:
            if self.spark:
                self.spark.stop()
                logger.info("🛑 Spark session terminated")

def main():
    """Main execution function."""
    transformer = NYCTaxiTransformer()
    
    # Run transformation for February 2024 data
    transformer.run_transformation_pipeline(year=2024, month=2)

if __name__ == "__main__":
    main() 