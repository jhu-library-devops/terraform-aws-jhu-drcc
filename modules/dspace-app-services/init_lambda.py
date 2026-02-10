import json
import boto3
import time
import os

ecs = boto3.client('ecs')

def handler(event, context):
    """
    Lambda function to run DSpace initialization tasks sequentially.
    1. Database migration and admin user creation
    2. Solr collection import
    """
    
    cluster_arn = os.environ['CLUSTER_ARN']
    db_init_task_def = os.environ['DB_INIT_TASK_DEF']
    solr_init_task_def = os.environ['SOLR_INIT_TASK_DEF']
    subnet_ids = json.loads(os.environ['SUBNET_IDS'])
    security_group_id = os.environ['SECURITY_GROUP_ID']
    enable_public_ip = os.environ.get('ENABLE_PUBLIC_IP', 'false').lower() == 'true'
    
    network_config = {
        'awsvpcConfiguration': {
            'subnets': subnet_ids,
            'securityGroups': [security_group_id],
            'assignPublicIp': 'ENABLED' if enable_public_ip else 'DISABLED'
        }
    }
    
    results = {}
    
    # Step 1: Run database initialization
    print("Starting database initialization...")
    db_task = run_task_and_wait(
        cluster_arn,
        db_init_task_def,
        network_config,
        'db-init'
    )
    results['database_init'] = db_task
    
    if db_task['status'] != 'SUCCESS':
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Database initialization failed',
                'results': results
            })
        }
    
    # Step 2: Run Solr initialization
    print("Starting Solr initialization...")
    solr_task = run_task_and_wait(
        cluster_arn,
        solr_init_task_def,
        network_config,
        'solr-init'
    )
    results['solr_init'] = solr_task
    
    if solr_task['status'] != 'SUCCESS':
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Solr initialization failed',
                'results': results
            })
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'All initialization tasks completed successfully',
            'results': results
        })
    }

def run_task_and_wait(cluster_arn, task_definition, network_config, task_name):
    """Run an ECS task and wait for it to complete."""
    
    try:
        # Start the task
        response = ecs.run_task(
            cluster=cluster_arn,
            taskDefinition=task_definition,
            launchType='FARGATE',
            networkConfiguration=network_config,
            startedBy='initialization-lambda'
        )
        
        if not response['tasks']:
            return {
                'status': 'FAILED',
                'message': 'Failed to start task',
                'task_name': task_name
            }
        
        task_arn = response['tasks'][0]['taskArn']
        print(f"Started task {task_name}: {task_arn}")
        
        # Wait for task to complete (max 15 minutes)
        max_wait = 900  # 15 minutes
        wait_interval = 10  # 10 seconds
        elapsed = 0
        
        while elapsed < max_wait:
            time.sleep(wait_interval)
            elapsed += wait_interval
            
            # Check task status
            describe_response = ecs.describe_tasks(
                cluster=cluster_arn,
                tasks=[task_arn]
            )
            
            if not describe_response['tasks']:
                return {
                    'status': 'FAILED',
                    'message': 'Task disappeared',
                    'task_name': task_name,
                    'task_arn': task_arn
                }
            
            task = describe_response['tasks'][0]
            last_status = task['lastStatus']
            
            print(f"Task {task_name} status: {last_status}")
            
            if last_status == 'STOPPED':
                # Check exit code
                containers = task.get('containers', [])
                if containers:
                    exit_code = containers[0].get('exitCode', 1)
                    if exit_code == 0:
                        return {
                            'status': 'SUCCESS',
                            'message': 'Task completed successfully',
                            'task_name': task_name,
                            'task_arn': task_arn,
                            'exit_code': exit_code
                        }
                    else:
                        return {
                            'status': 'FAILED',
                            'message': f'Task exited with code {exit_code}',
                            'task_name': task_name,
                            'task_arn': task_arn,
                            'exit_code': exit_code
                        }
                else:
                    return {
                        'status': 'FAILED',
                        'message': 'No container information available',
                        'task_name': task_name,
                        'task_arn': task_arn
                    }
        
        # Timeout
        return {
            'status': 'TIMEOUT',
            'message': f'Task did not complete within {max_wait} seconds',
            'task_name': task_name,
            'task_arn': task_arn
        }
        
    except Exception as e:
        return {
            'status': 'ERROR',
            'message': str(e),
            'task_name': task_name
        }
