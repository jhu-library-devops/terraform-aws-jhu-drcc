import json
import urllib3
import time
import os

def handler(event, context):
    """
    Configure Solr auto-scaling policies and collection templates
    """
    solr_endpoint = os.environ['SOLR_ENDPOINT']
    cluster_policies = json.loads('${cluster_policies}')
    collection_templates = json.loads('${collection_templates}')
    
    http = urllib3.PoolManager()
    
    # Wait for Solr to be ready
    max_retries = 30
    for i in range(max_retries):
        try:
            response = http.request('GET', f'{solr_endpoint}/solr/admin/info/system')
            if response.status == 200:
                print("Solr is ready")
                break
        except Exception as e:
            print(f"Waiting for Solr... attempt {i+1}/{max_retries}: {e}")
            time.sleep(10)
    else:
        raise Exception("Solr not ready after maximum retries")
    
    # Set cluster policies
    try:
        policy_url = f'{solr_endpoint}/solr/admin/autoscaling'
        policy_data = {
            'set-cluster-policy': cluster_policies
        }
        
        response = http.request(
            'POST',
            policy_url,
            body=json.dumps(policy_data),
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status == 200:
            print("Cluster policies configured successfully")
        else:
            print(f"Failed to set cluster policies: {response.status} - {response.data}")
            
    except Exception as e:
        print(f"Error setting cluster policies: {e}")
    
    # Create collection templates
    for template_name, template_config in collection_templates.items():
        try:
            template_url = f'{solr_endpoint}/solr/admin/collections'
            template_data = {
                'action': 'CREATE',
                'name': f'{template_name}_template',
                **template_config
            }
            
            response = http.request(
                'POST',
                template_url,
                fields=template_data
            )
            
            if response.status == 200:
                print(f"Collection template '{template_name}' created successfully")
            else:
                print(f"Failed to create template '{template_name}': {response.status} - {response.data}")
                
        except Exception as e:
            print(f"Error creating template '{template_name}': {e}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Solr auto-scaling configuration completed')
    }
