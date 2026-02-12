import json
import boto3
import docker
import base64
import time
import logging
from typing import Dict, List, Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for ECR image population.
    
    Args:
        event: {
            "images": [
                {
                    "upstream_image": "solr:9.8.1",
                    "ecr_repository": "jhu/solr",
                    "tag": "9.8.1"
                },
                {
                    "upstream_image": "zookeeper:3.9.3",
                    "ecr_repository": "jhu/zookeeper",
                    "tag": "3.9.3"
                }
            ],
            "aws_region": "us-east-1",
            "aws_account_id": "123456789012"
        }
        context: Lambda context object
    
    Returns:
        {
            "statusCode": 200 or 500,
            "body": {
                "successful": ["jhu/solr:9.8.1"],
                "failed": [],
                "skipped": ["jhu/zookeeper:3.9.3"]
            }
        }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    images = event.get('images', [])
    aws_region = event.get('aws_region')
    aws_account_id = event.get('aws_account_id')
    
    if not images:
        logger.error("No images specified in event")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'No images specified'})
        }
    
    results = {
        'successful': [],
        'failed': [],
        'skipped': []
    }
    
    # Initialize Docker client
    try:
        docker_client = docker.from_env()
    except Exception as e:
        logger.error(f"Failed to initialize Docker client: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Docker initialization failed: {str(e)}'})
        }
    
    # Initialize ECR client
    ecr_client = boto3.client('ecr', region_name=aws_region)
    
    # Process each image
    for image_spec in images:
        upstream_image = image_spec['upstream_image']
        ecr_repository = image_spec['ecr_repository']
        tag = image_spec['tag']
        
        ecr_image_uri = f"{aws_account_id}.dkr.ecr.{aws_region}.amazonaws.com/{ecr_repository}:{tag}"
        
        try:
            # Check if image already exists in ECR
            if image_exists_in_ecr(ecr_client, ecr_repository, tag):
                logger.info(f"Image {ecr_image_uri} already exists, skipping")
                results['skipped'].append(ecr_image_uri)
                continue
            
            # Pull upstream image
            logger.info(f"Pulling upstream image: {upstream_image}")
            pull_image(docker_client, upstream_image)
            
            # Retag for ECR
            logger.info(f"Retagging {upstream_image} as {ecr_image_uri}")
            retag_image(docker_client, upstream_image, ecr_image_uri)
            
            # Push to ECR
            logger.info(f"Pushing {ecr_image_uri} to ECR")
            push_to_ecr(docker_client, ecr_client, ecr_image_uri, aws_region)
            
            logger.info(f"Successfully processed {ecr_image_uri}")
            results['successful'].append(ecr_image_uri)
            
        except Exception as e:
            error_context = {
                'image': upstream_image,
                'ecr_repository': ecr_repository,
                'tag': tag,
                'error': str(e),
                'error_type': type(e).__name__
            }
            logger.error(f"Failed to process image - Context: {json.dumps(error_context)}")
            results['failed'].append({
                'image': upstream_image,
                'error': str(e)
            })
    
    # Determine overall status
    status_code = 200 if not results['failed'] else 500
    
    # Log execution summary with counts
    summary = {
        'total_images': len(images),
        'successful_count': len(results['successful']),
        'failed_count': len(results['failed']),
        'skipped_count': len(results['skipped']),
        'successful': results['successful'],
        'failed': results['failed'],
        'skipped': results['skipped']
    }
    logger.info(f"Execution summary: {json.dumps(summary)}")
    
    return {
        'statusCode': status_code,
        'body': json.dumps(results)
    }


def image_exists_in_ecr(ecr_client, repository: str, tag: str) -> bool:
    """
    Check if an image with the specified tag exists in ECR.
    
    Args:
        ecr_client: Boto3 ECR client
        repository: ECR repository name
        tag: Image tag to check
    
    Returns:
        True if image exists, False otherwise
    """
    try:
        response = ecr_client.describe_images(
            repositoryName=repository,
            imageIds=[{'imageTag': tag}]
        )
        return len(response.get('imageDetails', [])) > 0
    except ecr_client.exceptions.ImageNotFoundException:
        return False
    except Exception as e:
        logger.warning(f"Error checking image existence: {str(e)}")
        return False


def pull_image(docker_client, image: str, max_retries: int = 3) -> None:
    """
    Pull an image from Docker Hub with retry logic.
    
    Args:
        docker_client: Docker client instance
        image: Image name with tag (e.g., "solr:9.8.1")
        max_retries: Maximum number of retry attempts
    
    Raises:
        Exception: If pull fails after all retries
    """
    for attempt in range(max_retries):
        try:
            docker_client.images.pull(image)
            logger.info(f"Successfully pulled {image}")
            return
        except Exception as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff: 1s, 2s, 4s
                logger.warning(f"Pull attempt {attempt + 1} failed - Image: {image}, Error: {str(e)}, Retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                logger.error(f"Pull operation failed - Image: {image}, Attempts: {max_retries}, Error: {str(e)}")
                raise


def retag_image(docker_client, source_image: str, target_image: str) -> None:
    """
    Retag a Docker image.
    
    Args:
        docker_client: Docker client instance
        source_image: Source image name with tag
        target_image: Target image name with tag
    
    Raises:
        Exception: If retagging fails
    """
    try:
        image = docker_client.images.get(source_image)
        image.tag(target_image)
        logger.info(f"Successfully retagged {source_image} as {target_image}")
    except Exception as e:
        logger.error(f"Retag operation failed - Source: {source_image}, Target: {target_image}, Error: {str(e)}")
        raise


def push_to_ecr(docker_client, ecr_client, image: str, region: str, max_retries: int = 3) -> None:
    """
    Push an image to ECR with authentication and retry logic.
    
    Args:
        docker_client: Docker client instance
        ecr_client: Boto3 ECR client
        image: Full ECR image URI
        region: AWS region
        max_retries: Maximum number of retry attempts
    
    Raises:
        Exception: If push fails after all retries
    """
    # Get ECR authentication token
    try:
        auth_response = ecr_client.get_authorization_token()
        auth_token = auth_response['authorizationData'][0]['authorizationToken']
        registry_url = auth_response['authorizationData'][0]['proxyEndpoint']
        
        # Decode auth token
        username, password = base64.b64decode(auth_token).decode('utf-8').split(':')
        
        # Login to ECR
        docker_client.login(username=username, password=password, registry=registry_url)
        logger.info(f"Successfully authenticated with ECR - Registry: {registry_url}")
        
    except Exception as e:
        logger.error(f"ECR authentication failed - Region: {region}, Error: {str(e)}")
        raise
    
    # Push image with retries
    for attempt in range(max_retries):
        try:
            response = docker_client.images.push(image, stream=True, decode=True)
            
            # Check for errors in push response
            for line in response:
                if 'error' in line:
                    raise Exception(f"Push error: {line['error']}")
                if 'status' in line:
                    logger.debug(f"Push status: {line['status']}")
            
            logger.info(f"Successfully pushed {image} to ECR")
            
            # Verify image exists in ECR after push
            # Extract repository name: everything between registry URL and tag
            # Format: registry.com/repo/name:tag -> repo/name
            image_without_registry = '/'.join(image.split('/')[1:])  # Remove registry
            repository_name = image_without_registry.split(':')[0]  # Remove tag
            tag = image.split(':')[-1]  # Get tag (last part after :)
            if image_exists_in_ecr(ecr_client, repository_name, tag):
                logger.info(f"Verified {image} exists in ECR")
            else:
                raise Exception(f"Image {image} not found in ECR after push")
            
            return
            
        except Exception as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff: 1s, 2s, 4s
                # Extract repository name for logging
                image_without_registry = '/'.join(image.split('/')[1:])
                repository_name = image_without_registry.split(':')[0]
                tag = image.split(':')[-1]
                logger.warning(f"Push attempt {attempt + 1} failed - Image: {image}, Repository: {repository_name}, Tag: {tag}, Error: {str(e)}, Retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                # Extract repository name for logging
                image_without_registry = '/'.join(image.split('/')[1:])
                repository_name = image_without_registry.split(':')[0]
                tag = image.split(':')[-1]
                logger.error(f"Push operation failed - Image: {image}, Repository: {repository_name}, Tag: {tag}, Attempts: {max_retries}, Error: {str(e)}")
                raise
