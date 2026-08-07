# JHUnet Foundation - Stage Environment
# Fill in actual values from existing AWS resources before running import

environment =  "stage"
project_name = "jhunet-internal"

# Existing JHUnet VPC and subnets — replace with actual IDs
vpc_id = "vpc-07f503e3b0f8d5f8a"
private_subnet_ids = [
  "subnet-00cbb11a099d54bbd"
]

# ECS Cluster
ecs_cluster_name             = "jhunet-internal-cluster"
container_insights_value     = "enhanced"
execute_command_logging       = "DEFAULT"
service_connect_namespace_arn = "arn:aws:servicediscovery:us-east-1:390157243417:namespace/ns-z72ldxjaid7fy5mu"



tags = {
  Team        = "DRCC"
  Environment = "LAG"
}
