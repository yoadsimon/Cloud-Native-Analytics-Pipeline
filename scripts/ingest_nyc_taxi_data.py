#!/usr/bin/env python3
"""
NYC Taxi Data Ingestion Script
Automates the download and upload of NYC taxi data to S3 with proper partitioning.
"""

import os
import sys
import boto3
import requests
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/data_ingestion.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class NYCTaxiDataIngester:
    """Handles downloading and uploading NYC Taxi data to S3."""
    
    def __init__(self, bucket_name: str, aws_profile: str = 'cloud-native-analytics'):
        self.bucket_name = bucket_name
        self.aws_profile = aws_profile
        self.session = boto3.Session(profile_name=aws_profile)
        self.s3_client = self.session.client('s3')
        
        # Create local directories
        self.data_dir = Path('data/raw')
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # NYC TLC data base URL
        self.base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data"
        
    def download_file(self, url: str, local_path: Path) -> bool:
        """Download a file from URL to local path."""
        try:
            logger.info(f"Downloading {url} to {local_path}")
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            with open(local_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            file_size_mb = local_path.stat().st_size / (1024 * 1024)
            logger.info(f"Downloaded {local_path.name}: {file_size_mb:.1f}MB")
            return True
            
        except requests.RequestException as e:
            logger.error(f"Failed to download {url}: {e}")
            return False
    
    def upload_to_s3(self, local_path: Path, s3_key: str) -> bool:
        """Upload file to S3."""
        try:
            logger.info(f"Uploading {local_path} to s3://{self.bucket_name}/{s3_key}")
            self.s3_client.upload_file(str(local_path), self.bucket_name, s3_key)
            logger.info(f"Successfully uploaded to S3: {s3_key}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to upload to S3: {e}")
            return False
    
    def ingest_monthly_data(self, year: int, month: int, dataset_type: str = 'yellow') -> bool:
        """Ingest a specific month of taxi data."""
        # Format month with leading zero
        month_str = f"{month:02d}"
        
        # Construct filename and URLs
        filename = f"{dataset_type}_tripdata_{year}-{month_str}.parquet"
        url = f"{self.base_url}/{filename}"
        local_path = self.data_dir / filename
        
        # S3 key with partitioning
        s3_key = f"raw/dataset=nyc_taxi/year={year}/month={month_str}/{filename}"
        
        # Download file
        if not self.download_file(url, local_path):
            return False
        
        # Upload to S3
        if not self.upload_to_s3(local_path, s3_key):
            return False
        
        # Clean up local file (optional)
        # local_path.unlink()
        
        return True
    
    def ingest_latest_available(self, dataset_type: str = 'yellow') -> bool:
        """Ingest the latest available data (typically 2 months behind current)."""
        # NYC data is typically published with a 2-month delay
        target_date = datetime.now() - timedelta(days=60)
        
        logger.info(f"Attempting to ingest {dataset_type} taxi data for {target_date.strftime('%Y-%m')}")
        
        return self.ingest_monthly_data(
            year=target_date.year,
            month=target_date.month,
            dataset_type=dataset_type
        )
    
    def verify_s3_upload(self, s3_key: str) -> bool:
        """Verify that a file exists in S3."""
        try:
            self.s3_client.head_object(Bucket=self.bucket_name, Key=s3_key)
            logger.info(f"Verified S3 object exists: {s3_key}")
            return True
        except Exception as e:
            logger.error(f"S3 verification failed for {s3_key}: {e}")
            return False

def main():
    """Main execution function."""
    # Configuration
    BUCKET_NAME = "cloud-native-analytics-pipeline-d8e6ca17"
    
    # Create ingester
    ingester = NYCTaxiDataIngester(bucket_name=BUCKET_NAME)
    
    # Example usage - ingest latest data
    try:
        # Ingest yellow taxi data
        success = ingester.ingest_latest_available('yellow')
        
        if success:
            logger.info("✅ Data ingestion completed successfully!")
        else:
            logger.error("❌ Data ingestion failed!")
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Unexpected error during ingestion: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 