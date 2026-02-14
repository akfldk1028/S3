"""
Unit tests for R2 I/O module with mocked boto3

Tests verify:
- R2Client initialization with environment variables
- download() calls boto3 with correct bucket/key patterns
- upload() calls boto3 with correct key patterns for outputs/masks/previews
- Error handling for ClientError exceptions
"""

import os
import pytest
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError

# Import the module under test
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from engine.r2_io import R2Client


@pytest.fixture
def mock_env():
    """Set up environment variables for testing"""
    env_vars = {
        "R2_ACCOUNT_ID": "test-account-id",
        "R2_ACCESS_KEY_ID": "test-access-key",
        "R2_SECRET_ACCESS_KEY": "test-secret-key",
        "R2_BUCKET_NAME": "test-bucket"
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield env_vars


@pytest.fixture
def mock_boto3_client():
    """Mock boto3.client to avoid actual AWS/R2 connections"""
    with patch('engine.r2_io.boto3.client') as mock_client:
        mock_s3 = MagicMock()
        mock_client.return_value = mock_s3
        yield mock_s3


class TestR2ClientInitialization:
    """Test R2Client initialization and configuration"""

    def test_init_with_env_vars(self, mock_env, mock_boto3_client):
        """Test R2Client initializes with environment variables"""
        client = R2Client()

        assert client.endpoint == "https://test-account-id.r2.cloudflarestorage.com"
        assert client.access_key == "test-access-key"
        assert client.secret_key == "test-secret-key"
        assert client.bucket == "test-bucket"

    def test_init_boto3_client_called_correctly(self, mock_env, mock_boto3_client):
        """Test boto3.client is called with correct R2 configuration"""
        with patch('engine.r2_io.boto3.client') as mock_client:
            client = R2Client()

            mock_client.assert_called_once_with(
                's3',
                endpoint_url="https://test-account-id.r2.cloudflarestorage.com",
                aws_access_key_id="test-access-key",
                aws_secret_access_key="test-secret-key",
                region_name='auto'
            )

    def test_init_without_account_id(self, mock_boto3_client):
        """Test R2Client handles missing R2_ACCOUNT_ID"""
        with patch.dict(os.environ, {
            "R2_ACCOUNT_ID": "",
            "R2_ACCESS_KEY_ID": "key",
            "R2_SECRET_ACCESS_KEY": "secret",
            "R2_BUCKET_NAME": "bucket"
        }, clear=False):
            client = R2Client()
            assert client.endpoint == ""

    def test_init_uses_default_bucket(self, mock_boto3_client):
        """Test R2Client uses default bucket name when not specified"""
        with patch.dict(os.environ, {
            "R2_ACCOUNT_ID": "test-id",
            "R2_ACCESS_KEY_ID": "key",
            "R2_SECRET_ACCESS_KEY": "secret"
        }, clear=False):
            # Remove R2_BUCKET_NAME if it exists
            os.environ.pop("R2_BUCKET_NAME", None)
            client = R2Client()
            assert client.bucket == "s3-storage"


class TestR2Download:
    """Test R2Client.download() method"""

    def test_download_success(self, mock_env, mock_boto3_client):
        """Test download() successfully retrieves file from R2"""
        # Mock successful S3 response
        mock_body = MagicMock()
        mock_body.read.return_value = b"test image data"
        mock_boto3_client.get_object.return_value = {
            'Body': mock_body,
            'ContentType': 'image/jpeg'
        }

        client = R2Client()
        result = client.download("inputs/user123/job456/0.jpg")

        # Verify boto3 get_object called with correct parameters
        mock_boto3_client.get_object.assert_called_once_with(
            Bucket="test-bucket",
            Key="inputs/user123/job456/0.jpg"
        )

        # Verify response body was read
        assert result == b"test image data"

    def test_download_input_key_pattern(self, mock_env, mock_boto3_client):
        """Test download() with input key pattern from spec"""
        mock_body = MagicMock()
        mock_body.read.return_value = b"input image"
        mock_boto3_client.get_object.return_value = {'Body': mock_body}

        client = R2Client()

        # Test input key pattern: inputs/{userId}/{jobId}/{idx}.jpg
        user_id = "user-abc-123"
        job_id = "job-xyz-789"
        idx = 5
        key = f"inputs/{user_id}/{job_id}/{idx}.jpg"

        result = client.download(key)

        mock_boto3_client.get_object.assert_called_once_with(
            Bucket="test-bucket",
            Key=key
        )
        assert result == b"input image"

    def test_download_client_error(self, mock_env, mock_boto3_client):
        """Test download() raises RuntimeError on ClientError"""
        # Mock boto3 ClientError
        error_response = {
            'Error': {
                'Code': 'NoSuchKey',
                'Message': 'The specified key does not exist'
            }
        }
        mock_boto3_client.get_object.side_effect = ClientError(
            error_response,
            'GetObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.download("inputs/user/job/missing.jpg")

        # Verify error message contains key and error code
        error_msg = str(exc_info.value)
        assert "Failed to download" in error_msg
        assert "inputs/user/job/missing.jpg" in error_msg
        assert "NoSuchKey" in error_msg

    def test_download_access_denied(self, mock_env, mock_boto3_client):
        """Test download() handles access denied error"""
        error_response = {
            'Error': {
                'Code': 'AccessDenied',
                'Message': 'Access Denied'
            }
        }
        mock_boto3_client.get_object.side_effect = ClientError(
            error_response,
            'GetObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.download("inputs/user/job/0.jpg")

        assert "AccessDenied" in str(exc_info.value)


class TestR2Upload:
    """Test R2Client.upload() method"""

    def test_upload_success(self, mock_env, mock_boto3_client):
        """Test upload() successfully uploads file to R2"""
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()
        test_data = b"test output image data"

        # Should not raise exception
        client.upload("outputs/user/job/0_result.png", test_data, "image/png")

        # Verify boto3 put_object called with correct parameters
        mock_boto3_client.put_object.assert_called_once_with(
            Bucket="test-bucket",
            Key="outputs/user/job/0_result.png",
            Body=test_data,
            ContentType="image/png"
        )

    def test_upload_output_key_pattern(self, mock_env, mock_boto3_client):
        """Test upload() with output key pattern from spec"""
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()

        # Test output key pattern: outputs/{userId}/{jobId}/{ruleId}/{idx}.jpg
        user_id = "user-123"
        job_id = "job-456"
        rule_id = "rule-recolor-wall"
        idx = 2
        key = f"outputs/{user_id}/{job_id}/{rule_id}/{idx}.jpg"

        client.upload(key, b"output data", "image/jpeg")

        mock_boto3_client.put_object.assert_called_once_with(
            Bucket="test-bucket",
            Key=key,
            Body=b"output data",
            ContentType="image/jpeg"
        )

    def test_upload_mask_key_pattern(self, mock_env, mock_boto3_client):
        """Test upload() with mask key pattern from spec"""
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()

        # Test mask key pattern: masks/{userId}/{jobId}/{concept}/{idx}_{instance_num}.png
        user_id = "user-abc"
        job_id = "job-xyz"
        concept = "wall"
        idx = 0
        instance_num = 1
        key = f"masks/{user_id}/{job_id}/{concept}/{idx}_{instance_num}.png"

        client.upload(key, b"mask data", "image/png")

        mock_boto3_client.put_object.assert_called_once_with(
            Bucket="test-bucket",
            Key=key,
            Body=b"mask data",
            ContentType="image/png"
        )

    def test_upload_preview_key_pattern(self, mock_env, mock_boto3_client):
        """Test upload() with preview key pattern from spec"""
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()

        # Test preview key pattern: previews/{userId}/{jobId}/{idx}_preview.jpg
        user_id = "user-test"
        job_id = "job-test"
        idx = 3
        key = f"previews/{user_id}/{job_id}/{idx}_preview.jpg"

        client.upload(key, b"preview thumbnail", "image/jpeg")

        mock_boto3_client.put_object.assert_called_once_with(
            Bucket="test-bucket",
            Key=key,
            Body=b"preview thumbnail",
            ContentType="image/jpeg"
        )

    def test_upload_default_content_type(self, mock_env, mock_boto3_client):
        """Test upload() uses default content type when not specified"""
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()

        # Upload without specifying content_type
        client.upload("test.png", b"data")

        # Should default to image/png
        call_args = mock_boto3_client.put_object.call_args
        assert call_args[1]['ContentType'] == "image/png"

    def test_upload_client_error(self, mock_env, mock_boto3_client):
        """Test upload() raises RuntimeError on ClientError"""
        error_response = {
            'Error': {
                'Code': 'InternalError',
                'Message': 'We encountered an internal error'
            }
        }
        mock_boto3_client.put_object.side_effect = ClientError(
            error_response,
            'PutObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.upload("outputs/user/job/0.png", b"data", "image/png")

        # Verify error message contains key and error code
        error_msg = str(exc_info.value)
        assert "Failed to upload" in error_msg
        assert "outputs/user/job/0.png" in error_msg
        assert "InternalError" in error_msg

    def test_upload_quota_exceeded(self, mock_env, mock_boto3_client):
        """Test upload() handles quota exceeded error"""
        error_response = {
            'Error': {
                'Code': 'QuotaExceeded',
                'Message': 'Storage quota exceeded'
            }
        }
        mock_boto3_client.put_object.side_effect = ClientError(
            error_response,
            'PutObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.upload("outputs/test.png", b"data")

        assert "QuotaExceeded" in str(exc_info.value)


class TestR2ErrorHandling:
    """Test error handling edge cases"""

    def test_download_unknown_error_code(self, mock_env, mock_boto3_client):
        """Test download() handles ClientError without error code"""
        error_response = {'Error': {}}  # No 'Code' field
        mock_boto3_client.get_object.side_effect = ClientError(
            error_response,
            'GetObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.download("test.jpg")

        # Should include 'Unknown' for missing error code
        assert "Unknown" in str(exc_info.value)

    def test_upload_unknown_error_code(self, mock_env, mock_boto3_client):
        """Test upload() handles ClientError without error code"""
        error_response = {'Error': {}}  # No 'Code' field
        mock_boto3_client.put_object.side_effect = ClientError(
            error_response,
            'PutObject'
        )

        client = R2Client()

        with pytest.raises(RuntimeError) as exc_info:
            client.upload("test.png", b"data")

        # Should include 'Unknown' for missing error code
        assert "Unknown" in str(exc_info.value)


class TestR2KeyPatterns:
    """Test that R2Client works with all key patterns from workflow.md"""

    def test_all_key_patterns_integration(self, mock_env, mock_boto3_client):
        """Integration test verifying all R2 key patterns from spec work correctly"""
        mock_body = MagicMock()
        mock_body.read.return_value = b"data"
        mock_boto3_client.get_object.return_value = {'Body': mock_body}
        mock_boto3_client.put_object.return_value = {}

        client = R2Client()

        # Test all key patterns from workflow.md section 8
        user_id = "user123"
        job_id = "job456"
        rule_id = "rule789"
        concept = "wall"
        idx = 0
        instance_num = 1

        # Input key
        input_key = f"inputs/{user_id}/{job_id}/{idx}.jpg"
        client.download(input_key)
        assert mock_boto3_client.get_object.call_count == 1

        # Output key
        output_key = f"outputs/{user_id}/{job_id}/{rule_id}/{idx}.jpg"
        client.upload(output_key, b"output", "image/jpeg")

        # Mask key
        mask_key = f"masks/{user_id}/{job_id}/{concept}/{idx}_{instance_num}.png"
        client.upload(mask_key, b"mask", "image/png")

        # Preview key
        preview_key = f"previews/{user_id}/{job_id}/{idx}_preview.jpg"
        client.upload(preview_key, b"preview", "image/jpeg")

        # Verify all uploads succeeded
        assert mock_boto3_client.put_object.call_count == 3
