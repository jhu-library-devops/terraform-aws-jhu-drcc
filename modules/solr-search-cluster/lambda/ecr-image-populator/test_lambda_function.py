"""
Unit tests for ECR Image Populator Lambda function helper functions.

Tests cover:
- image_exists_in_ecr with mocked ECR responses
- pull_image with valid and invalid images
- retag_image with various image formats
- push_to_ecr with mocked ECR client
- Retry logic with simulated failures
"""

import unittest
from unittest.mock import Mock, MagicMock, patch, call
import base64
import time
from botocore.exceptions import ClientError

# Import functions to test
from lambda_function import (
    image_exists_in_ecr,
    pull_image,
    retag_image,
    push_to_ecr
)


class TestImageExistsInECR(unittest.TestCase):
    """Test image_exists_in_ecr function with mocked ECR responses."""
    
    def test_image_exists_returns_true(self):
        """Test that function returns True when image exists in ECR."""
        # Arrange
        mock_ecr_client = Mock()
        mock_ecr_client.describe_images.return_value = {
            'imageDetails': [
                {
                    'imageDigest': 'sha256:abc123',
                    'imageTags': ['9.6.1']
                }
            ]
        }
        
        # Act
        result = image_exists_in_ecr(mock_ecr_client, 'jhu/solr', '9.6.1')
        
        # Assert
        self.assertTrue(result)
        mock_ecr_client.describe_images.assert_called_once_with(
            repositoryName='jhu/solr',
            imageIds=[{'imageTag': '9.6.1'}]
        )
    
    def test_image_not_exists_returns_false(self):
        """Test that function returns False when image does not exist."""
        # Arrange
        mock_ecr_client = Mock()
        mock_ecr_client.exceptions.ImageNotFoundException = type('ImageNotFoundException', (Exception,), {})
        mock_ecr_client.describe_images.side_effect = mock_ecr_client.exceptions.ImageNotFoundException()
        
        # Act
        result = image_exists_in_ecr(mock_ecr_client, 'jhu/solr', '9.6.1')
        
        # Assert
        self.assertFalse(result)
    
    def test_empty_image_details_returns_false(self):
        """Test that function returns False when imageDetails is empty."""
        # Arrange
        mock_ecr_client = Mock()
        mock_ecr_client.describe_images.return_value = {'imageDetails': []}
        
        # Act
        result = image_exists_in_ecr(mock_ecr_client, 'jhu/solr', '9.6.1')
        
        # Assert
        self.assertFalse(result)
    
    def test_generic_exception_returns_false(self):
        """Test that function returns False on generic exceptions."""
        # Arrange
        mock_ecr_client = Mock()
        # Create a proper exception class for ImageNotFoundException
        mock_ecr_client.exceptions = Mock()
        mock_ecr_client.exceptions.ImageNotFoundException = type('ImageNotFoundException', (Exception,), {})
        mock_ecr_client.describe_images.side_effect = ClientError(
            {'Error': {'Code': 'RepositoryNotFoundException', 'Message': 'Repository not found'}},
            'describe_images'
        )
        
        # Act
        result = image_exists_in_ecr(mock_ecr_client, 'jhu/solr', '9.6.1')
        
        # Assert
        self.assertFalse(result)


class TestPullImage(unittest.TestCase):
    """Test pull_image function with valid and invalid images."""
    
    def test_pull_image_success_first_attempt(self):
        """Test successful image pull on first attempt."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.return_value = Mock()
        
        # Act
        pull_image(mock_docker_client, 'solr:9.6.1')
        
        # Assert
        mock_docker_client.images.pull.assert_called_once_with('solr:9.6.1')
    
    def test_pull_image_success_after_retry(self):
        """Test successful image pull after one retry."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.side_effect = [
            Exception("Network timeout"),
            Mock()  # Success on second attempt
        ]
        
        # Act
        with patch('time.sleep'):  # Mock sleep to speed up test
            pull_image(mock_docker_client, 'solr:9.6.1')
        
        # Assert
        self.assertEqual(mock_docker_client.images.pull.call_count, 2)
    
    def test_pull_image_fails_after_max_retries(self):
        """Test that pull_image raises exception after max retries."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.side_effect = Exception("Image not found")
        
        # Act & Assert
        with patch('time.sleep'):  # Mock sleep to speed up test
            with self.assertRaises(Exception) as context:
                pull_image(mock_docker_client, 'invalid:latest', max_retries=3)
        
        self.assertEqual(mock_docker_client.images.pull.call_count, 3)
        self.assertIn("Image not found", str(context.exception))
    
    def test_pull_image_exponential_backoff(self):
        """Test that retry logic uses exponential backoff."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.side_effect = [
            Exception("Retry 1"),
            Exception("Retry 2"),
            Mock()  # Success on third attempt
        ]
        
        # Act
        with patch('time.sleep') as mock_sleep:
            pull_image(mock_docker_client, 'solr:9.6.1', max_retries=3)
        
        # Assert - exponential backoff: 2^0=1s, 2^1=2s
        expected_calls = [call(1), call(2)]
        mock_sleep.assert_has_calls(expected_calls)
    
    def test_pull_image_with_different_formats(self):
        """Test pull_image with various image name formats."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.return_value = Mock()
        
        test_images = [
            'solr:9.6.1',
            'zookeeper:3.9.3',
            'library/solr:latest',
            'docker.io/solr:9.6.1'
        ]
        
        # Act & Assert
        for image in test_images:
            mock_docker_client.reset_mock()
            pull_image(mock_docker_client, image)
            mock_docker_client.images.pull.assert_called_once_with(image)


class TestRetagImage(unittest.TestCase):
    """Test retag_image function with various image formats."""
    
    def test_retag_image_success(self):
        """Test successful image retagging."""
        # Arrange
        mock_docker_client = Mock()
        mock_image = Mock()
        mock_docker_client.images.get.return_value = mock_image
        
        source = 'solr:9.6.1'
        target = '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1'
        
        # Act
        retag_image(mock_docker_client, source, target)
        
        # Assert
        mock_docker_client.images.get.assert_called_once_with(source)
        mock_image.tag.assert_called_once_with(target)
    
    def test_retag_image_source_not_found(self):
        """Test retag_image raises exception when source image not found."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.get.side_effect = Exception("Image not found")
        
        # Act & Assert
        with self.assertRaises(Exception) as context:
            retag_image(mock_docker_client, 'nonexistent:latest', 'target:latest')
        
        self.assertIn("Image not found", str(context.exception))
    
    def test_retag_image_tag_operation_fails(self):
        """Test retag_image raises exception when tag operation fails."""
        # Arrange
        mock_docker_client = Mock()
        mock_image = Mock()
        mock_image.tag.side_effect = Exception("Tag operation failed")
        mock_docker_client.images.get.return_value = mock_image
        
        # Act & Assert
        with self.assertRaises(Exception) as context:
            retag_image(mock_docker_client, 'source:latest', 'target:latest')
        
        self.assertIn("Tag operation failed", str(context.exception))
    
    def test_retag_with_organization_prefix(self):
        """Test retagging preserves organization prefix in target."""
        # Arrange
        mock_docker_client = Mock()
        mock_image = Mock()
        mock_docker_client.images.get.return_value = mock_image
        
        test_cases = [
            ('solr:9.6.1', '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1'),
            ('zookeeper:3.9.3', '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/zookeeper:3.9.3'),
            ('solr:latest', '123456789012.dkr.ecr.us-east-1.amazonaws.com/org/solr:latest')
        ]
        
        # Act & Assert
        for source, target in test_cases:
            mock_docker_client.reset_mock()
            mock_image.reset_mock()
            retag_image(mock_docker_client, source, target)
            mock_image.tag.assert_called_once_with(target)
    
    def test_retag_preserves_original_tag(self):
        """Test that retagging preserves the original image tag."""
        # Arrange
        mock_docker_client = Mock()
        mock_image = Mock()
        mock_docker_client.images.get.return_value = mock_image
        
        # Act
        source = 'solr:9.6.1'
        target = '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1'
        retag_image(mock_docker_client, source, target)
        
        # Assert - verify tag is preserved in target
        self.assertTrue(target.endswith(':9.6.1'))
        mock_image.tag.assert_called_once_with(target)


class TestPushToECR(unittest.TestCase):
    """Test push_to_ecr function with mocked ECR client."""
    
    def setUp(self):
        """Set up common test fixtures."""
        self.mock_docker_client = Mock()
        self.mock_ecr_client = Mock()
        
        # Mock ECR authentication
        auth_token = base64.b64encode(b'AWS:mock-password').decode('utf-8')
        self.mock_ecr_client.get_authorization_token.return_value = {
            'authorizationData': [{
                'authorizationToken': auth_token,
                'proxyEndpoint': 'https://123456789012.dkr.ecr.us-east-1.amazonaws.com'
            }]
        }
        
        # Mock successful login
        self.mock_docker_client.login.return_value = {'Status': 'Login Succeeded'}
    
    def test_push_to_ecr_success(self):
        """Test successful push to ECR."""
        # Arrange
        self.mock_docker_client.images.push.return_value = [
            {'status': 'Pushing', 'progress': '1/10'},
            {'status': 'Pushed'}
        ]
        
        # Mock image_exists_in_ecr for verification
        with patch('lambda_function.image_exists_in_ecr', return_value=True):
            # Act
            push_to_ecr(
                self.mock_docker_client,
                self.mock_ecr_client,
                '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                'us-east-1'
            )
        
        # Assert
        self.mock_ecr_client.get_authorization_token.assert_called_once()
        self.mock_docker_client.login.assert_called_once()
        self.mock_docker_client.images.push.assert_called_once()
    
    def test_push_to_ecr_authentication_success(self):
        """Test ECR authentication is performed correctly."""
        # Arrange
        self.mock_docker_client.images.push.return_value = [{'status': 'Pushed'}]
        
        with patch('lambda_function.image_exists_in_ecr', return_value=True):
            # Act
            push_to_ecr(
                self.mock_docker_client,
                self.mock_ecr_client,
                '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                'us-east-1'
            )
        
        # Assert
        self.mock_docker_client.login.assert_called_once_with(
            username='AWS',
            password='mock-password',
            registry='https://123456789012.dkr.ecr.us-east-1.amazonaws.com'
        )
    
    def test_push_to_ecr_authentication_failure(self):
        """Test push_to_ecr raises exception on authentication failure."""
        # Arrange
        self.mock_ecr_client.get_authorization_token.side_effect = Exception("Auth failed")
        
        # Act & Assert
        with self.assertRaises(Exception) as context:
            push_to_ecr(
                self.mock_docker_client,
                self.mock_ecr_client,
                '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                'us-east-1'
            )
        
        self.assertIn("Auth failed", str(context.exception))
    
    def test_push_to_ecr_push_error_in_stream(self):
        """Test push_to_ecr raises exception when error in push stream."""
        # Arrange
        self.mock_docker_client.images.push.return_value = [
            {'status': 'Pushing'},
            {'error': 'denied: access forbidden'}
        ]
        
        # Act & Assert
        with patch('time.sleep'):
            with self.assertRaises(Exception) as context:
                push_to_ecr(
                    self.mock_docker_client,
                    self.mock_ecr_client,
                    '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                    'us-east-1',
                    max_retries=3
                )
        
        self.assertIn("denied: access forbidden", str(context.exception))
    
    def test_push_to_ecr_retry_on_failure(self):
        """Test push_to_ecr retries on failure."""
        # Arrange
        self.mock_docker_client.images.push.side_effect = [
            Exception("Network error"),
            [{'status': 'Pushed'}]  # Success on second attempt
        ]
        
        with patch('lambda_function.image_exists_in_ecr', return_value=True):
            with patch('time.sleep'):
                # Act
                push_to_ecr(
                    self.mock_docker_client,
                    self.mock_ecr_client,
                    '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                    'us-east-1',
                    max_retries=3
                )
        
        # Assert
        self.assertEqual(self.mock_docker_client.images.push.call_count, 2)
    
    def test_push_to_ecr_fails_after_max_retries(self):
        """Test push_to_ecr raises exception after max retries."""
        # Arrange
        self.mock_docker_client.images.push.side_effect = Exception("Push failed")
        
        # Act & Assert
        with patch('time.sleep'):
            with self.assertRaises(Exception) as context:
                push_to_ecr(
                    self.mock_docker_client,
                    self.mock_ecr_client,
                    '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                    'us-east-1',
                    max_retries=3
                )
        
        self.assertEqual(self.mock_docker_client.images.push.call_count, 3)
        self.assertIn("Push failed", str(context.exception))
    
    def test_push_to_ecr_exponential_backoff(self):
        """Test that push retry logic uses exponential backoff."""
        # Arrange
        self.mock_docker_client.images.push.side_effect = [
            Exception("Retry 1"),
            Exception("Retry 2"),
            [{'status': 'Pushed'}]  # Success on third attempt
        ]
        
        with patch('lambda_function.image_exists_in_ecr', return_value=True):
            with patch('time.sleep') as mock_sleep:
                # Act
                push_to_ecr(
                    self.mock_docker_client,
                    self.mock_ecr_client,
                    '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                    'us-east-1',
                    max_retries=3
                )
        
        # Assert - exponential backoff: 2^0=1s, 2^1=2s
        expected_calls = [call(1), call(2)]
        mock_sleep.assert_has_calls(expected_calls)
    
    def test_push_to_ecr_verifies_image_after_push(self):
        """Test that push_to_ecr verifies image exists after push."""
        # Arrange
        self.mock_docker_client.images.push.return_value = [{'status': 'Pushed'}]
        
        with patch('lambda_function.image_exists_in_ecr') as mock_exists:
            mock_exists.return_value = True
            
            # Act
            push_to_ecr(
                self.mock_docker_client,
                self.mock_ecr_client,
                '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                'us-east-1'
            )
            
            # Assert - repository name is "jhu/solr" (full path after registry)
            mock_exists.assert_called_once_with(self.mock_ecr_client, 'jhu/solr', '9.6.1')
    
    def test_push_to_ecr_fails_if_verification_fails(self):
        """Test push_to_ecr raises exception if image not found after push."""
        # Arrange
        self.mock_docker_client.images.push.return_value = [{'status': 'Pushed'}]
        
        with patch('lambda_function.image_exists_in_ecr', return_value=False):
            with patch('time.sleep'):
                # Act & Assert
                with self.assertRaises(Exception) as context:
                    push_to_ecr(
                        self.mock_docker_client,
                        self.mock_ecr_client,
                        '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/solr:9.6.1',
                        'us-east-1',
                        max_retries=3
                    )
        
        self.assertIn("not found in ECR after push", str(context.exception))


class TestRetryLogic(unittest.TestCase):
    """Test retry logic with simulated failures."""
    
    def test_pull_retry_count_matches_max_retries(self):
        """Test pull_image attempts exactly max_retries times."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.side_effect = Exception("Always fails")
        
        # Act & Assert
        with patch('time.sleep'):
            for max_retries in [1, 2, 3, 5]:
                mock_docker_client.reset_mock()
                with self.assertRaises(Exception):
                    pull_image(mock_docker_client, 'test:latest', max_retries=max_retries)
                self.assertEqual(mock_docker_client.images.pull.call_count, max_retries)
    
    def test_push_retry_count_matches_max_retries(self):
        """Test push_to_ecr attempts exactly max_retries times."""
        # Arrange
        mock_docker_client = Mock()
        mock_ecr_client = Mock()
        
        auth_token = base64.b64encode(b'AWS:password').decode('utf-8')
        mock_ecr_client.get_authorization_token.return_value = {
            'authorizationData': [{
                'authorizationToken': auth_token,
                'proxyEndpoint': 'https://123456789012.dkr.ecr.us-east-1.amazonaws.com'
            }]
        }
        mock_docker_client.login.return_value = {'Status': 'Login Succeeded'}
        mock_docker_client.images.push.side_effect = Exception("Always fails")
        
        # Act & Assert
        with patch('time.sleep'):
            for max_retries in [1, 2, 3, 5]:
                mock_docker_client.reset_mock()
                with self.assertRaises(Exception):
                    push_to_ecr(
                        mock_docker_client,
                        mock_ecr_client,
                        '123456789012.dkr.ecr.us-east-1.amazonaws.com/jhu/test:latest',
                        'us-east-1',
                        max_retries=max_retries
                    )
                self.assertEqual(mock_docker_client.images.push.call_count, max_retries)
    
    def test_retry_succeeds_on_last_attempt(self):
        """Test that retry logic succeeds on the last attempt."""
        # Arrange
        mock_docker_client = Mock()
        max_retries = 3
        
        # Fail first 2 attempts, succeed on 3rd
        mock_docker_client.images.pull.side_effect = [
            Exception("Fail 1"),
            Exception("Fail 2"),
            Mock()  # Success
        ]
        
        # Act
        with patch('time.sleep'):
            pull_image(mock_docker_client, 'test:latest', max_retries=max_retries)
        
        # Assert
        self.assertEqual(mock_docker_client.images.pull.call_count, 3)
    
    def test_no_retry_on_first_success(self):
        """Test that no retries occur when first attempt succeeds."""
        # Arrange
        mock_docker_client = Mock()
        mock_docker_client.images.pull.return_value = Mock()
        
        # Act
        pull_image(mock_docker_client, 'test:latest', max_retries=3)
        
        # Assert
        self.assertEqual(mock_docker_client.images.pull.call_count, 1)


if __name__ == '__main__':
    unittest.main()
