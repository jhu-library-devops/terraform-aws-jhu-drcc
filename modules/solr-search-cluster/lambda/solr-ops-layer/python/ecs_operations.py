import logging
import time

logger = logging.getLogger()

def wait_for_new_task(ecs, cluster_name, service_name, exclude_task_id):
    """Wait for new task to be running and healthy"""
    for i in range(30):
        response = ecs.list_tasks(cluster=cluster_name, serviceName=service_name, desiredStatus='RUNNING')
        for task_arn in response['taskArns']:
            task_id = task_arn.split('/')[-1]
            if task_id != exclude_task_id:
                task_response = ecs.describe_tasks(cluster=cluster_name, tasks=[task_id])
                task = task_response['tasks'][0]
                
                if (task['lastStatus'] == 'RUNNING' and 
                    task.get('healthStatus') in ['HEALTHY', 'UNKNOWN'] and
                    task.get('connectivity') == 'CONNECTED'):
                    logger.info(f"New task {task_id} is running and healthy")
                    return task_id
                    
        logger.info(f"Waiting for new task... attempt {i+1}/30")
        time.sleep(10)
    return None

def wait_for_scale_down(ecs, cluster_name, service_name, target_count):
    """Wait for service to scale down to target count"""
    for i in range(20):
        try:
            response = ecs.describe_services(cluster=cluster_name, services=[service_name])
            service = response['services'][0]
            running_count = service['runningCount']
            
            if running_count == target_count:
                logger.info(f"Service scaled down to {target_count} tasks")
                return True
                
            logger.info(f"Waiting for scale down... current: {running_count}, target: {target_count}")
            time.sleep(5)
        except Exception as e:
            logger.warning(f"Error checking scale down status: {e}")
            
    logger.warning("Scale down did not complete within timeout")
    return False

def get_node_from_task(ecs, cluster_name, task_id):
    """Get Solr node name from ECS task ID"""
    try:
        response = ecs.describe_tasks(cluster=cluster_name, tasks=[task_id])
        if not response['tasks']:
            return None
            
        task = response['tasks'][0]
        
        for attachment in task.get('attachments', []):
            for detail in attachment.get('details', []):
                if detail['name'] == 'privateIPv4Address':
                    ip = detail['value']
                    return f"{ip}:8983_solr"
        
        return None
    except Exception:
        return None
