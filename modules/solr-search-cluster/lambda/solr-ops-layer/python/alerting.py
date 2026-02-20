import boto3
import logging
import os

logger = logging.getLogger()

def send_sns_alert(message, old_task_id, new_task_id):
    """Send alert via CloudWatch Alarm for AWS Chatbot compatibility"""
    try:
        cloudwatch = boto3.client('cloudwatch')
        sns_topic_arn = os.environ.get('SNS_ALERT_TOPIC_ARN', '')
        
        # Update alarm description with task details
        alarm_description = f"Solr rollover failed | Old Task: {old_task_id} | New Task: {new_task_id} | Error: {message}"
        
        cloudwatch.put_metric_alarm(
            AlarmName='DSpace-Solr-Unhealthy-ECSRollover',
            AlarmDescription=alarm_description,
            ActionsEnabled=True,
            AlarmActions=[sns_topic_arn],
            MetricName='RolloverFailure',
            Namespace='DSpace/Solr',
            Statistic='Sum',
            Period=60,
            EvaluationPeriods=1,
            Threshold=0.0,
            ComparisonOperator='GreaterThanThreshold',
            TreatMissingData='notBreaching'
        )
        
        # Send metric to trigger alarm
        cloudwatch.put_metric_data(
            Namespace='DSpace/Solr',
            MetricData=[{
                'MetricName': 'RolloverFailure',
                'Value': 1,
                'Unit': 'Count'
            }]
        )
        
        logger.info(f"CloudWatch alarm updated and triggered for Old Task: {old_task_id}, New Task: {new_task_id}")
        
    except Exception as e:
        logger.error(f"Failed to send CloudWatch alert: {e}")
