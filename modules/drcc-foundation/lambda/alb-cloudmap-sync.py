import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

elbv2 = boto3.client('elbv2')
ec2 = boto3.client('ec2')
servicediscovery = boto3.client('servicediscovery')

ALB_NAME = os.environ['ALB_NAME']
SERVICE_ID = os.environ['SERVICE_ID']
INSTANCE_ID = os.environ['INSTANCE_ID']

def lambda_handler(event, context):
    try:
        # Get ALB network interfaces
        response = elbv2.describe_load_balancers(Names=[ALB_NAME])
        alb_arn = response['LoadBalancers'][0]['LoadBalancerArn']
        alb_id = alb_arn.split('/')[-1]
        
        enis = ec2.describe_network_interfaces(
            Filters=[
                {'Name': 'description', 'Values': [f'*{alb_id}*']},
                {'Name': 'status', 'Values': ['in-use']}
            ]
        )
        
        alb_ips = [eni['PrivateIpAddress'] for eni in enis['NetworkInterfaces']]
        logger.info(f"Found ALB IPs: {alb_ips}")
        
        if not alb_ips:
            logger.error("No IPs found for ALB")
            return {'statusCode': 500, 'body': 'No IPs found'}
        
        # Get current Cloud Map instance
        instances = servicediscovery.list_instances(ServiceId=SERVICE_ID)
        current_ip = None
        for inst in instances['Instances']:
            if inst['Id'] == INSTANCE_ID:
                current_ip = inst['Attributes'].get('AWS_INSTANCE_IPV4')
                break
        
        new_ip = alb_ips[0]
        
        if current_ip == new_ip:
            logger.info(f"IP unchanged: {current_ip}")
            return {'statusCode': 200, 'body': 'No update needed'}
        
        logger.info(f"Updating IP from {current_ip} to {new_ip}")
        
        # Deregister old instance
        if current_ip:
            servicediscovery.deregister_instance(
                ServiceId=SERVICE_ID,
                InstanceId=INSTANCE_ID
            )
        
        # Register with new IP
        servicediscovery.register_instance(
            ServiceId=SERVICE_ID,
            InstanceId=INSTANCE_ID,
            Attributes={'AWS_INSTANCE_IPV4': new_ip}
        )
        
        logger.info(f"Successfully updated Cloud Map to {new_ip}")
        return {'statusCode': 200, 'body': f'Updated to {new_ip}'}
        
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise
