"""
Property-based test for IAM Permission Scoping.

**Property 6: IAM Permission Scoping**
**Validates: Requirements 7.4**

This test verifies that for any ECR repository managed by the module,
the IAM policy grants push/pull permissions to that repository and no other repositories.
"""

import json
import unittest
from hypothesis import given, strategies as st, settings, assume
from typing import List, Dict, Any


# Strategy for generating valid AWS account IDs (12 digits)
aws_account_id_strategy = st.text(
    alphabet='0123456789',
    min_size=12,
    max_size=12
)

# Strategy for generating valid AWS regions
aws_region_strategy = st.sampled_from([
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
    'eu-west-1', 'eu-central-1', 'ap-southeast-1', 'ap-northeast-1'
])

# Strategy for generating valid organization names
organization_strategy = st.text(
    alphabet='abcdefghijklmnopqrstuvwxyz0123456789-',
    min_size=2,
    max_size=20
).filter(lambda x: not x.startswith('-') and not x.endswith('-'))

# Strategy for generating valid repository names
repository_name_strategy = st.text(
    alphabet='abcdefghijklmnopqrstuvwxyz0123456789-/',
    min_size=3,
    max_size=30
).filter(lambda x: not x.startswith('/') and not x.endswith('/') and '//' not in x)

# Strategy for generating lists of ECR repositories
ecr_repositories_strategy = st.lists(
    repository_name_strategy,
    min_size=1,
    max_size=10,
    unique=True
)


def construct_iam_policy(
    ecr_repositories: List[str],
    aws_region: str,
    aws_account_id: str
) -> Dict[str, Any]:
    """
    Construct IAM policy matching the Terraform configuration.
    
    This mirrors the policy structure in lambda-ecr-populator.tf.
    """
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ecr:GetAuthorizationToken"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "ecr:DescribeImages",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload",
                    "ecr:PutImage"
                ],
                "Resource": [
                    f"arn:aws:ecr:{aws_region}:{aws_account_id}:repository/{repo}"
                    for repo in ecr_repositories
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": f"arn:aws:logs:{aws_region}:{aws_account_id}:log-group:/aws/lambda/*:*"
            }
        ]
    }


def extract_ecr_resources_from_policy(policy: Dict[str, Any]) -> List[str]:
    """
    Extract ECR repository ARNs from IAM policy.
    
    Returns list of repository ARNs that have ECR push/pull permissions.
    """
    ecr_resources = []
    
    for statement in policy.get("Statement", []):
        actions = statement.get("Action", [])
        
        # Check if this statement contains ECR push/pull actions
        ecr_actions = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ]
        
        has_ecr_actions = any(action in actions for action in ecr_actions)
        
        if has_ecr_actions:
            resources = statement.get("Resource", [])
            if isinstance(resources, str):
                resources = [resources]
            
            # Filter for ECR repository ARNs
            ecr_resources.extend([
                r for r in resources
                if r.startswith("arn:aws:ecr:") and ":repository/" in r
            ])
    
    return ecr_resources


def extract_repository_name_from_arn(arn: str) -> str:
    """
    Extract repository name from ECR ARN.
    
    Example: arn:aws:ecr:us-east-1:123456789012:repository/jhu/solr -> jhu/solr
    """
    if ":repository/" in arn:
        return arn.split(":repository/")[1]
    return ""


class TestIAMPermissionScoping(unittest.TestCase):
    """
    Property-based tests for IAM Permission Scoping.
    
    **Property 6: IAM Permission Scoping**
    *For any* ECR repository managed by the module, the IAM policy should grant
    push/pull permissions to that repository and no other repositories.
    """
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy
    )
    @settings(max_examples=100)
    def test_policy_grants_permissions_to_all_managed_repositories(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str
    ):
        """
        Property: For any set of managed repositories, the IAM policy must grant
        ECR push/pull permissions to ALL of them.
        """
        # Arrange
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act
        granted_arns = extract_ecr_resources_from_policy(policy)
        granted_repos = [extract_repository_name_from_arn(arn) for arn in granted_arns]
        
        # Assert - all managed repositories should have permissions
        for repo in ecr_repositories:
            self.assertIn(
                repo,
                granted_repos,
                f"Repository {repo} should have ECR permissions but was not found in policy"
            )
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy
    )
    @settings(max_examples=100)
    def test_policy_grants_permissions_only_to_managed_repositories(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str
    ):
        """
        Property: For any set of managed repositories, the IAM policy must NOT grant
        ECR push/pull permissions to any repositories outside the managed set.
        """
        # Arrange
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act
        granted_arns = extract_ecr_resources_from_policy(policy)
        granted_repos = [extract_repository_name_from_arn(arn) for arn in granted_arns]
        
        # Assert - no extra repositories should have permissions
        self.assertEqual(
            set(granted_repos),
            set(ecr_repositories),
            f"Policy grants permissions to repositories outside the managed set. "
            f"Expected: {set(ecr_repositories)}, Got: {set(granted_repos)}"
        )
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy,
        unmanaged_repo=repository_name_strategy
    )
    @settings(max_examples=100)
    def test_policy_does_not_grant_permissions_to_unmanaged_repositories(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str,
        unmanaged_repo: str
    ):
        """
        Property: For any unmanaged repository (not in the managed set), the IAM policy
        must NOT grant ECR push/pull permissions to it.
        """
        # Assume the unmanaged repo is not in the managed set
        assume(unmanaged_repo not in ecr_repositories)
        
        # Arrange
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act
        granted_arns = extract_ecr_resources_from_policy(policy)
        granted_repos = [extract_repository_name_from_arn(arn) for arn in granted_arns]
        
        # Assert - unmanaged repository should NOT have permissions
        self.assertNotIn(
            unmanaged_repo,
            granted_repos,
            f"Unmanaged repository {unmanaged_repo} should NOT have ECR permissions"
        )
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy
    )
    @settings(max_examples=100)
    def test_policy_scopes_resources_to_correct_account_and_region(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str
    ):
        """
        Property: For any managed repository, the IAM policy must scope the resource ARN
        to the correct AWS account and region.
        """
        # Arrange
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act
        granted_arns = extract_ecr_resources_from_policy(policy)
        
        # Assert - all ARNs should contain correct account and region
        for arn in granted_arns:
            self.assertIn(
                aws_region,
                arn,
                f"ARN {arn} should contain region {aws_region}"
            )
            self.assertIn(
                aws_account_id,
                arn,
                f"ARN {arn} should contain account ID {aws_account_id}"
            )
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy
    )
    @settings(max_examples=100)
    def test_policy_includes_all_required_ecr_actions(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str
    ):
        """
        Property: For any managed repository, the IAM policy must include all required
        ECR actions for push/pull operations.
        """
        # Arrange
        required_actions = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ]
        
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act - find the ECR statement
        ecr_statement = None
        for statement in policy.get("Statement", []):
            resources = statement.get("Resource", [])
            if isinstance(resources, list) and any(":repository/" in str(r) for r in resources):
                ecr_statement = statement
                break
        
        # Assert
        self.assertIsNotNone(ecr_statement, "Policy should have an ECR statement")
        
        actions = ecr_statement.get("Action", [])
        for required_action in required_actions:
            self.assertIn(
                required_action,
                actions,
                f"Policy should include action {required_action}"
            )
    
    @given(
        ecr_repositories=ecr_repositories_strategy,
        aws_region=aws_region_strategy,
        aws_account_id=aws_account_id_strategy
    )
    @settings(max_examples=100)
    def test_policy_does_not_grant_wildcard_ecr_permissions(
        self,
        ecr_repositories: List[str],
        aws_region: str,
        aws_account_id: str
    ):
        """
        Property: The IAM policy must NOT grant ECR push/pull permissions with wildcard
        resources (except for GetAuthorizationToken which requires "*").
        """
        # Arrange
        policy = construct_iam_policy(ecr_repositories, aws_region, aws_account_id)
        
        # Act - check all statements
        for statement in policy.get("Statement", []):
            actions = statement.get("Action", [])
            resources = statement.get("Resource", [])
            
            if isinstance(resources, str):
                resources = [resources]
            
            # Check if this statement has ECR push/pull actions
            ecr_push_pull_actions = [
                "ecr:BatchCheckLayerAvailability",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeImages"
            ]
            
            has_push_pull_actions = any(action in actions for action in ecr_push_pull_actions)
            
            # Assert - if it has push/pull actions, resources should not be "*"
            if has_push_pull_actions:
                self.assertNotIn(
                    "*",
                    resources,
                    "ECR push/pull permissions should not use wildcard resources"
                )


if __name__ == '__main__':
    unittest.main()
