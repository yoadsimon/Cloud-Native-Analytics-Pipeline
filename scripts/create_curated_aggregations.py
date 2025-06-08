#!/usr/bin/env python3
"""
NYC Taxi Curated Layer Aggregation Pipeline for AWS Glue
Creates business-ready aggregated tables from staging data.

This script demonstrates advanced data engineering practices:
- Multi-dimensional aggregations for analytics
- Business intelligence ready datasets
- Optimized Parquet storage for Redshift loading
- Data quality metrics and validation
"""

import sys
import logging
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, when, sum as spark_sum, avg, min, max, count, 
    round as spark_round, stddev, percentile_approx,
    date_format, year, month, dayofmonth, dayofweek,
    lit, desc, asc
)
from pyspark.sql.types import DoubleType, IntegerType, StringType

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'INPUT_S3_PATH',
    'OUTPUT_S3_PATH', 
    'DATABASE_NAME'
])

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configure logging
logger = glueContext.get_logger()
logger.info("Starting NYC Taxi Curated Aggregation job")

class NYCTaxiCuratedETL:
    """AWS Glue ETL job for creating curated aggregated datasets."""
    
    def __init__(self, glue_context, input_path, output_path, database_name):
        self.glue_context = glue_context
        self.spark = glue_context.spark_session
        self.input_path = input_path
        self.output_path = output_path
        self.database_name = database_name
        self.logger = glue_context.get_logger()
        
    def read_staging_data(self):
        """Read processed data from staging layer."""
        self.logger.info(f"Reading staging data from: {self.input_path}")
        
        # Create DynamicFrame from staging S3
        staging_data = self.glue_context.create_dynamic_frame.from_options(
            format_options={"multiline": False},
            connection_type="s3",
            format="parquet",
            connection_options={
                "paths": [f"{self.input_path}dataset=nyc_taxi_processed/"],
                "recurse": True
            },
            transformation_ctx="staging_data"
        )
        
        # Convert to DataFrame for aggregations
        df = staging_data.toDF()
        
        # Handle timestamp compatibility issues
        # Convert any TimestampNTZ columns to regular timestamps
        for field in df.schema.fields:
            if "TimestampNTZ" in str(field.dataType):
                df = df.withColumn(field.name, col(field.name).cast("timestamp"))
        
        self.logger.info(f"Staging data loaded: {df.count()} records")
        return df
    
    def create_daily_summary(self, df):
        """Create daily aggregated summary table."""
        self.logger.info("Creating daily summary aggregations")
        
        daily_summary = df.groupBy(
            "pickup_date",
            "day_type"  # Weekend vs Weekday
        ).agg(
            count("*").alias("total_trips"),
            spark_sum("total_amount").alias("total_revenue"),
            avg("total_amount").alias("avg_fare"),
            avg("trip_distance").alias("avg_distance"),
            avg("trip_duration_minutes").alias("avg_duration"),
            avg("average_speed_mph").alias("avg_speed"),
            max("total_amount").alias("max_fare"),
            min("total_amount").alias("min_fare"),
            count(when(col("payment_method") == "Credit Card", 1)).alias("credit_card_trips"),
            count(when(col("payment_method") == "Cash", 1)).alias("cash_trips"),
            spark_sum("passenger_count").alias("total_passengers"),
            count(when(col("data_quality_flag") != "Normal", 1)).alias("anomaly_trips")
        ).withColumn(
            "revenue_per_trip", spark_round(col("total_revenue") / col("total_trips"), 2)
        ).withColumn(
            "credit_card_percentage", spark_round((col("credit_card_trips") / col("total_trips")) * 100, 1)
        ).withColumn(
            "avg_passengers_per_trip", spark_round(col("total_passengers") / col("total_trips"), 1)
        ).withColumn(
            "anomaly_percentage", spark_round((col("anomaly_trips") / col("total_trips")) * 100, 2)
        )
        
        return daily_summary
    
    def create_hourly_patterns(self, df):
        """Create hourly pattern analysis table."""
        self.logger.info("Creating hourly pattern aggregations")
        
        hourly_patterns = df.groupBy(
            "pickup_hour",
            "time_of_day_category",
            "day_type"
        ).agg(
            count("*").alias("trip_count"),
            avg("total_amount").alias("avg_fare"),
            avg("trip_distance").alias("avg_distance"),
            avg("trip_duration_minutes").alias("avg_duration"),
            avg("average_speed_mph").alias("avg_speed"),
            spark_sum("total_amount").alias("total_revenue"),
            stddev("total_amount").alias("fare_stddev")
        ).withColumn(
            "revenue_per_hour", spark_round(col("total_revenue"), 2)
        ).withColumn(
            "fare_coefficient_of_variation", 
            spark_round(col("fare_stddev") / col("avg_fare"), 3)
        )
        
        return hourly_patterns
    
    def create_payment_analysis(self, df):
        """Create payment method analysis table."""
        self.logger.info("Creating payment method analysis")
        
        payment_analysis = df.groupBy(
            "payment_method",
            "day_type"
        ).agg(
            count("*").alias("trip_count"),
            spark_sum("total_amount").alias("total_revenue"),
            avg("total_amount").alias("avg_fare"),
            avg("trip_distance").alias("avg_distance"),
            avg("tip_amount").alias("avg_tip"),
            percentile_approx("total_amount", 0.5).alias("median_fare"),
            percentile_approx("tip_amount", 0.5).alias("median_tip")
        ).withColumn(
            "avg_tip_percentage", 
            spark_round((col("avg_tip") / (col("avg_fare") - col("avg_tip"))) * 100, 1)
        )
        
        return payment_analysis
    
    def create_trip_distance_analysis(self, df):
        """Create trip distance category analysis."""
        self.logger.info("Creating trip distance analysis")
        
        # Categorize trips by distance
        df_with_distance_category = df.withColumn(
            "distance_category",
            when(col("trip_distance") <= 1, "Short (≤1 mile)")
            .when((col("trip_distance") > 1) & (col("trip_distance") <= 5), "Medium (1-5 miles)")
            .when((col("trip_distance") > 5) & (col("trip_distance") <= 10), "Long (5-10 miles)")
            .otherwise("Very Long (>10 miles)")
        )
        
        distance_analysis = df_with_distance_category.groupBy(
            "distance_category",
            "time_of_day_category"
        ).agg(
            count("*").alias("trip_count"),
            avg("total_amount").alias("avg_fare"),
            avg("trip_duration_minutes").alias("avg_duration"),
            avg("average_speed_mph").alias("avg_speed"),
            spark_sum("total_amount").alias("total_revenue"),
            avg("fare_per_mile").alias("avg_fare_per_mile")
        ).withColumn(
            "fare_efficiency", spark_round(col("total_revenue") / col("trip_count"), 2)
        )
        
        return distance_analysis
    
    def create_location_analysis(self, df):
        """Create pickup/dropoff location analysis."""
        self.logger.info("Creating location analysis")
        
        # Analyze by location zones (using RatecodeID as proxy for location)
        location_analysis = df.groupBy(
            "rate_code_desc",
            "day_type"
        ).agg(
            count("*").alias("trip_count"),
            avg("total_amount").alias("avg_fare"),
            avg("trip_distance").alias("avg_distance"),
            avg("trip_duration_minutes").alias("avg_duration"),
            spark_sum("total_amount").alias("total_revenue")
        ).withColumn(
            "market_share_rank", 
            spark_round(col("trip_count"), 0)
        )
        
        return location_analysis
    
    def write_curated_table(self, df, table_name, partition_keys=None):
        """Write aggregated data to curated S3 layer."""
        self.logger.info(f"Writing {table_name} to curated layer")
        
        # Convert to DynamicFrame
        dynamic_frame = DynamicFrame.fromDF(df, self.glue_context, f"{table_name}_frame")
        
        # Write options
        write_options = {
            "path": f"{self.output_path}{table_name}/",
            "compression": "snappy"
        }
        
        if partition_keys:
            write_options["partitionKeys"] = partition_keys
        
        self.glue_context.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="glueparquet",
            connection_options=write_options,
            transformation_ctx=f"write_{table_name}"
        )
        
        record_count = df.count()
        self.logger.info(f"{table_name} written successfully: {record_count:,} records")
        return record_count
    
    def run_aggregation_pipeline(self):
        """Execute the complete curated layer creation pipeline."""
        try:
            # Step 1: Read staging data
            staging_df = self.read_staging_data()
            
            # Step 2: Create daily summary table
            daily_summary = self.create_daily_summary(staging_df)
            daily_count = self.write_curated_table(
                daily_summary, 
                "daily_summary", 
                ["day_type"]
            )
            
            # Step 3: Create hourly patterns table
            hourly_patterns = self.create_hourly_patterns(staging_df)
            hourly_count = self.write_curated_table(
                hourly_patterns, 
                "hourly_patterns", 
                ["day_type", "time_of_day_category"]
            )
            
            # Step 4: Create payment analysis table
            payment_analysis = self.create_payment_analysis(staging_df)
            payment_count = self.write_curated_table(
                payment_analysis, 
                "payment_analysis", 
                ["payment_method"]
            )
            
            # Step 5: Create distance analysis table
            distance_analysis = self.create_trip_distance_analysis(staging_df)
            distance_count = self.write_curated_table(
                distance_analysis, 
                "distance_analysis", 
                ["distance_category"]
            )
            
            # Step 6: Create location analysis table
            location_analysis = self.create_location_analysis(staging_df)
            location_count = self.write_curated_table(
                location_analysis, 
                "location_analysis", 
                ["rate_code_desc"]
            )
            
            # Log summary
            total_curated_records = (daily_count + hourly_count + payment_count + 
                                   distance_count + location_count)
            
            self.logger.info("🎉 Curated aggregation pipeline completed successfully!")
            self.logger.info(f"📊 Curated Tables Created:")
            self.logger.info(f"  • daily_summary: {daily_count:,} records")
            self.logger.info(f"  • hourly_patterns: {hourly_count:,} records") 
            self.logger.info(f"  • payment_analysis: {payment_count:,} records")
            self.logger.info(f"  • distance_analysis: {distance_count:,} records")
            self.logger.info(f"  • location_analysis: {location_count:,} records")
            self.logger.info(f"📈 Total curated records: {total_curated_records:,}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Curated aggregation pipeline failed: {str(e)}")
            raise e

# Execute aggregation pipeline
def main():
    """Main execution function."""
    etl = NYCTaxiCuratedETL(
        glue_context=glueContext,
        input_path=args['INPUT_S3_PATH'],
        output_path=args['OUTPUT_S3_PATH'],
        database_name=args['DATABASE_NAME']
    )
    
    success = etl.run_aggregation_pipeline()
    
    if success:
        logger.info("NYC Taxi Curated Aggregation job completed successfully")
        job.commit()
    else:
        logger.error("NYC Taxi Curated Aggregation job failed")
        sys.exit(1)

if __name__ == "__main__":
    main() 