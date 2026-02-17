# Solr Rollover Lambda Layer

This Lambda Layer contains shared modules for the Solr leader rollover Lambda function.

## Contents

- `ecs_operations.py` - ECS task management functions
- `solr_operations.py` - Solr cluster operations
- `alerting.py` - SNS alerting functionality

## Deployment

From the parent directory, run:

```bash
./deploy-solr-rollover-layer.sh
```

This will:
1. Package the modules into a ZIP file
2. Publish the layer to AWS Lambda
3. Output the Layer ARN

## Attaching to Lambda Function

After deployment, attach the layer to your Lambda function:

```bash
aws lambda update-function-configuration \
    --function-name solr-leader-rollover \
    --layers <layer-arn-from-output>
```

Or use Infrastructure as Code (Terraform, CloudFormation, etc.) to reference the layer.

## Updating

When you modify any of the Python modules, re-run the deployment script to publish a new layer version.
