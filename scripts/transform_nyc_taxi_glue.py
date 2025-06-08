#!/usr/bin/env python3
"""
NYC Taxi Data Transformation Pipeline for AWS Glue
Production PySpark job optimized for AWS Glue serverless environment.

This script demonstrates enterprise-level data engineering practices:
- AWS Glue job parameter handling
- Glue Data Catalog integration
- CloudWatch logging
- Optimized for serverless execution
"""

import sys
import logging
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, when, isnan, isnull, lit, round as spark_round,
    unix_timestamp, from_unixtime, hour, dayofweek, 
    date_format, regexp_replace, trim, upper,
    avg, min, max, count, stddev, year, month, dayofmonth
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
logger.info("Starting NYC Taxi ETL job")

class NYCTaxiGlueETL:
    """AWS Glue ETL job for NYC taxi data transformation."""
    
    def __init__(self, glue_context, input_path, output_path, database_name):
        self.glue_context = glue_context
        self.spark = glue_context.spark_session
        self.input_path = input_path
        self.output_path = output_path
        self.database_name = database_name
        self.logger = glue_context.get_logger()
        
    def read_raw_data(self):
        """Read raw NYC taxi data from S3."""
        self.logger.info(f"Reading raw data from: {self.input_path}")
        
        # Use Spark directly to read the specific Parquet file to avoid DynamicFrame directory scanning
        exact_file_path = f"{self.input_path}dataset=nyc_taxi/year=2024/month=02/yellow_tripdata_2024-02.parquet"
        self.logger.info(f"Reading exact file: {exact_file_path}")
        
        df = self.spark.read.parquet(exact_file_path)
        self.logger.info(f"Raw data loaded: {df.count()} records")
        return df
    
    def clean_and_validate_data(self, df):
        """Apply comprehensive data cleaning and validation."""
        self.logger.info("Starting data cleaning and validation")
        
        initial_count = df.count()
        
        # Remove rows with critical null values
        df_clean = df.filter(
            col("tpep_pickup_datetime").isNotNull() &
            col("tpep_dropoff_datetime").isNotNull() &
            col("passenger_count").isNotNull() &
            col("trip_distance").isNotNull() &
            col("total_amount").isNotNull()
        )
        
        # Data quality filters
        df_clean = df_clean.filter(
            (col("passenger_count") >= 1) & (col("passenger_count") <= 8) &
            (col("trip_distance") >= 0.1) & (col("trip_distance") <= 100) &
            (col("total_amount") >= 0) & (col("total_amount") <= 1000) &
            (col("tpep_pickup_datetime") < col("tpep_dropoff_datetime"))
        )
        
        # Calculate trip duration in minutes
        df_clean = df_clean.withColumn(
            "trip_duration_minutes",
            (unix_timestamp("tpep_dropoff_datetime") - 
             unix_timestamp("tpep_pickup_datetime")) / 60
        )
        
        # Filter reasonable trip durations (1 minute to 8 hours)
        df_clean = df_clean.filter(
            (col("trip_duration_minutes") >= 1) & 
            (col("trip_duration_minutes") <= 480)
        )
        
        final_count = df_clean.count()
        removed_count = initial_count - final_count
        removal_rate = (removed_count / initial_count) * 100
        
        self.logger.info(f"Data cleaning completed:")
        self.logger.info(f"  Initial records: {initial_count:,}")
        self.logger.info(f"  Final records: {final_count:,}")
        self.logger.info(f"  Removed: {removed_count:,} ({removal_rate:.2f}%)")
        
        return df_clean
    
    def add_business_transformations(self, df):
        """Add business logic transformations and derived columns."""
        self.logger.info("Adding business transformations")
        
        # Time-based features
        df_transformed = df.withColumn(
            "pickup_hour", hour("tpep_pickup_datetime")
        ).withColumn(
            "pickup_day_of_week", dayofweek("tpep_pickup_datetime")
        ).withColumn(
            "pickup_date", col("tpep_pickup_datetime").cast("date")
        )
        
        # Time of day categorization
        df_transformed = df_transformed.withColumn(
            "time_of_day_category",
            when((col("pickup_hour") >= 6) & (col("pickup_hour") < 12), "Morning")
            .when((col("pickup_hour") >= 12) & (col("pickup_hour") < 18), "Afternoon")
            .when((col("pickup_hour") >= 18) & (col("pickup_hour") < 22), "Evening")
            .otherwise("Night")
        )
        
        # Day type categorization
        df_transformed = df_transformed.withColumn(
            "day_type",
            when(col("pickup_day_of_week").isin([1, 7]), "Weekend")
            .otherwise("Weekday")
        )
        
        # Speed calculation (mph)
        df_transformed = df_transformed.withColumn(
            "average_speed_mph",
            spark_round(
                (col("trip_distance") / (col("trip_duration_minutes") / 60)), 2
            )
        )
        
        # Payment method categorization
        df_transformed = df_transformed.withColumn(
            "payment_method",
            when(col("payment_type") == 1, "Credit Card")
            .when(col("payment_type") == 2, "Cash")
            .when(col("payment_type") == 3, "No Charge")
            .when(col("payment_type") == 4, "Dispute")
            .when(col("payment_type") == 5, "Unknown")
            .when(col("payment_type") == 6, "Voided Trip")
            .otherwise("Other")
        )
        
        # Rate code description
        df_transformed = df_transformed.withColumn(
            "rate_code_desc",
            when(col("RatecodeID") == 1, "Standard Rate")
            .when(col("RatecodeID") == 2, "JFK")
            .when(col("RatecodeID") == 3, "Newark")
            .when(col("RatecodeID") == 4, "Nassau or Westchester")
            .when(col("RatecodeID") == 5, "Negotiated Fare")
            .when(col("RatecodeID") == 6, "Group Ride")
            .otherwise("Unknown")
        )
        
        # Fare per mile
        df_transformed = df_transformed.withColumn(
            "fare_per_mile",
            spark_round(col("fare_amount") / col("trip_distance"), 2)
        )
        
        # Data quality flags
        df_transformed = df_transformed.withColumn(
            "data_quality_flag",
            when(col("average_speed_mph") > 60, "High Speed")
            .when(col("fare_per_mile") > 10, "High Fare Rate")
            .when(col("trip_distance") > 50, "Long Distance")
            .otherwise("Normal")
        )
        
        return df_transformed
    
    def write_to_staging(self, df):
        """Write transformed data to S3 staging layer with partitioning."""
        self.logger.info(f"Writing transformed data to: {self.output_path}")
        
        # Convert back to DynamicFrame for Glue catalog integration
        dynamic_frame = DynamicFrame.fromDF(df, self.glue_context, "transformed_data")
        
        # Write to S3 with partitioning
        self.glue_context.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="glueparquet",
            connection_options={
                "path": f"{self.output_path}dataset=nyc_taxi_processed/",
                "partitionKeys": ["pickup_date", "time_of_day_category"]
            },
            format_options={
                "compression": "snappy"
            },
            transformation_ctx="write_staging"
        )
        
        self.logger.info("Data successfully written to staging layer")
    
    def run_etl_pipeline(self):
        """Execute the complete ETL pipeline."""
        try:
            # Step 1: Read raw data
            raw_df = self.read_raw_data()
            
            # Step 2: Clean and validate
            clean_df = self.clean_and_validate_data(raw_df)
            
            # Step 3: Apply business transformations
            transformed_df = self.add_business_transformations(clean_df)
            
            # Step 4: Write to staging
            self.write_to_staging(transformed_df)
            
            # Log final statistics
            final_count = transformed_df.count()
            self.logger.info(f"ETL pipeline completed successfully")
            self.logger.info(f"Final record count: {final_count:,}")
            
            # Generate summary statistics
            stats = transformed_df.agg(
                avg("total_amount").alias("avg_fare"),
                avg("trip_distance").alias("avg_distance"),
                avg("trip_duration_minutes").alias("avg_duration"),
                count("*").alias("total_trips")
            ).collect()[0]
            
            self.logger.info(f"Summary Statistics:")
            self.logger.info(f"  Average Fare: ${stats['avg_fare']:.2f}")
            self.logger.info(f"  Average Distance: {stats['avg_distance']:.2f} miles")
            self.logger.info(f"  Average Duration: {stats['avg_duration']:.1f} minutes")
            self.logger.info(f"  Total Trips: {stats['total_trips']:,}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"ETL pipeline failed: {str(e)}")
            raise e

# Execute ETL pipeline
def main():
    """Main execution function."""
    etl = NYCTaxiGlueETL(
        glue_context=glueContext,
        input_path=args['INPUT_S3_PATH'],
        output_path=args['OUTPUT_S3_PATH'],
        database_name=args['DATABASE_NAME']
    )
    
    success = etl.run_etl_pipeline()
    
    if success:
        logger.info("NYC Taxi ETL job completed successfully")
        job.commit()
    else:
        logger.error("NYC Taxi ETL job failed")
        sys.exit(1)

if __name__ == "__main__":
    main() 