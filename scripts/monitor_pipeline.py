#!/usr/bin/env python3
"""
Cloud-Native Analytics Pipeline Monitoring Script
Monitors Glue jobs, Redshift performance, and cost metrics
"""

import boto3
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PipelineMonitor:
    def __init__(self, region='us-east-1'):
        self.region = region
        self.glue_client = boto3.client('glue', region_name=region)
        self.cloudwatch_client = boto3.client('cloudwatch', region_name=region)
        self.redshift_client = boto3.client('redshift-serverless', region_name=region)
        self.budgets_client = boto3.client('budgets', region_name=region)
        
    def get_glue_job_status(self, job_name: str) -> Dict:
        """Get the status of a Glue job"""
        try:
            response = self.glue_client.get_job_runs(JobName=job_name, MaxResults=5)
            runs = response.get('JobRuns', [])
            
            if not runs:
                return {'status': 'NO_RUNS', 'message': f'No runs found for job {job_name}'}
            
            latest_run = runs[0]
            return {
                'job_name': job_name,
                'status': latest_run['JobRunState'],
                'started_on': latest_run.get('StartedOn'),
                'completed_on': latest_run.get('CompletedOn'),
                'execution_time': latest_run.get('ExecutionTime'),
                'error_message': latest_run.get('ErrorMessage')
            }
        except Exception as e:
            logger.error(f"Error getting job status for {job_name}: {str(e)}")
            return {'status': 'ERROR', 'message': str(e)}
    
    def get_redshift_workgroup_status(self, workgroup_name: str) -> Dict:
        """Get Redshift Serverless workgroup status"""
        try:
            response = self.redshift_client.get_workgroup(workgroupName=workgroup_name)
            workgroup = response['workgroup']
            
            return {
                'workgroup_name': workgroup_name,
                'status': workgroup['status'],
                'base_capacity': workgroup.get('baseCapacity'),
                'endpoint': workgroup.get('endpoint', {}).get('address'),
                'port': workgroup.get('endpoint', {}).get('port'),
                'creation_date': workgroup.get('creationDate')
            }
        except Exception as e:
            logger.error(f"Error getting workgroup status: {str(e)}")
            return {'status': 'ERROR', 'message': str(e)}
    
    def get_cloudwatch_metrics(self, metric_name: str, namespace: str, 
                              dimensions: Dict, hours_back: int = 1) -> List[Dict]:
        """Get CloudWatch metrics"""
        try:
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(hours=hours_back)
            
            response = self.cloudwatch_client.get_metric_statistics(
                Namespace=namespace,
                MetricName=metric_name,
                Dimensions=[{'Name': k, 'Value': v} for k, v in dimensions.items()],
                StartTime=start_time,
                EndTime=end_time,
                Period=300,  # 5 minutes
                Statistics=['Sum', 'Average', 'Maximum']
            )
            
            return response.get('Datapoints', [])
        except Exception as e:
            logger.error(f"Error getting CloudWatch metrics: {str(e)}")
            return []
    
    def get_cost_and_usage(self, days_back: int = 7) -> Dict:
        """Get cost and usage data"""
        try:
            ce_client = boto3.client('ce', region_name='us-east-1')  # Cost Explorer is only in us-east-1
            
            end_date = datetime.now().strftime('%Y-%m-%d')
            start_date = (datetime.now() - timedelta(days=days_back)).strftime('%Y-%m-%d')
            
            response = ce_client.get_cost_and_usage(
                TimePeriod={
                    'Start': start_date,
                    'End': end_date
                },
                Granularity='DAILY',
                Metrics=['BlendedCost'],
                GroupBy=[
                    {
                        'Type': 'DIMENSION',
                        'Key': 'SERVICE'
                    }
                ]
            )
            
            return response
        except Exception as e:
            logger.error(f"Error getting cost data: {str(e)}")
            return {}
    
    def monitor_pipeline_health(self) -> Dict:
        """Comprehensive pipeline health check"""
        logger.info("Starting pipeline health monitoring...")
        
        health_report = {
            'timestamp': datetime.utcnow().isoformat(),
            'overall_status': 'HEALTHY',
            'components': {}
        }
        
        # Monitor Glue Jobs
        glue_jobs = [
            'cloud-native-analytics-pipeline-nyc-taxi-etl',
            'cloud-native-analytics-pipeline-curated-aggregations'
        ]
        
        for job_name in glue_jobs:
            job_status = self.get_glue_job_status(job_name)
            health_report['components'][job_name] = job_status
            
            if job_status.get('status') in ['FAILED', 'ERROR', 'TIMEOUT']:
                health_report['overall_status'] = 'UNHEALTHY'
        
        # Monitor Redshift
        redshift_status = self.get_redshift_workgroup_status('cloud-native-analytics-workgroup')
        health_report['components']['redshift_workgroup'] = redshift_status
        
        if redshift_status.get('status') != 'AVAILABLE':
            health_report['overall_status'] = 'DEGRADED'
        
        # Get recent CloudWatch metrics
        glue_metrics = self.get_cloudwatch_metrics(
            'glue.driver.aggregate.numFailedTasks',
            'Glue',
            {'JobName': glue_jobs[0]}
        )
        health_report['components']['recent_glue_failures'] = len([
            m for m in glue_metrics if m.get('Sum', 0) > 0
        ])
        
        # Cost monitoring
        cost_data = self.get_cost_and_usage()
        if cost_data:
            total_cost = 0
            for result in cost_data.get('ResultsByTime', []):
                for group in result.get('Groups', []):
                    amount = float(group.get('Metrics', {}).get('BlendedCost', {}).get('Amount', 0))
                    total_cost += amount
            
            health_report['components']['weekly_cost_usd'] = round(total_cost, 2)
        
        return health_report
    
    def generate_monitoring_report(self) -> str:
        """Generate a formatted monitoring report"""
        health_data = self.monitor_pipeline_health()
        
        report = f"""
{'='*60}
CLOUD-NATIVE ANALYTICS PIPELINE MONITORING REPORT
{'='*60}
Generated: {health_data['timestamp']}
Overall Status: {health_data['overall_status']}

COMPONENT STATUS:
{'-'*40}
"""
        
        for component, status in health_data['components'].items():
            if isinstance(status, dict):
                if 'job_name' in status:
                    report += f"• {component}: {status.get('status', 'UNKNOWN')}\n"
                    if status.get('execution_time'):
                        report += f"  Last execution time: {status['execution_time']} seconds\n"
                    if status.get('error_message'):
                        report += f"  Error: {status['error_message']}\n"
                elif 'workgroup_name' in status:
                    report += f"• Redshift Workgroup: {status.get('status', 'UNKNOWN')}\n"
                    report += f"  Base Capacity: {status.get('base_capacity', 'N/A')} RPU\n"
                    report += f"  Endpoint: {status.get('endpoint', 'N/A')}\n"
            else:
                report += f"• {component}: {status}\n"
        
        report += f"\n{'='*60}\n"
        return report

def main():
    """Main monitoring function"""
    try:
        monitor = PipelineMonitor()
        report = monitor.generate_monitoring_report()
        print(report)
        
        # Log to CloudWatch (optional)
        logger.info("Pipeline monitoring completed successfully")
        
    except Exception as e:
        logger.error(f"Monitoring failed: {str(e)}")
        raise

if __name__ == "__main__":
    main() 