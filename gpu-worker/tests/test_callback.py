"""
Unit tests for callback mechanism with mocked httpx

Tests verify:
- Authentication header (X-GPU-Callback-Secret) is included
- Idempotency key generation is deterministic
- Timeout configuration is correct
- Retry logic attempts 1 retry on failure
- Error handling returns False instead of raising exceptions
- Payload structure includes idx, status, and optional fields
- Job ID extraction from callback URL
"""

import os
import pytest
import time
from unittest.mock import Mock, patch, MagicMock
import httpx

# Import the module under test
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from engine.callback import report, _extract_job_id, _generate_idempotency_key


@pytest.fixture
def mock_env():
    """Set up environment variables for testing"""
    env_vars = {
        "GPU_CALLBACK_SECRET": "test-secret-key-12345",
        "CALLBACK_TIMEOUT_SEC": "10"
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield env_vars


@pytest.fixture
def mock_httpx_client():
    """Mock httpx.Client to avoid actual HTTP requests"""
    with patch('engine.callback.httpx.Client') as mock_client_class:
        mock_client = MagicMock()
        mock_client_class.return_value.__enter__ = Mock(return_value=mock_client)
        mock_client_class.return_value.__exit__ = Mock(return_value=None)
        yield mock_client


class TestJobIdExtraction:
    """Test _extract_job_id() helper function"""

    def test_extract_job_id_success(self):
        """Test job_id extraction from valid callback URL"""
        url = "https://api.workers.dev/jobs/job-abc-123/callback"
        job_id = _extract_job_id(url)
        assert job_id == "job-abc-123"

    def test_extract_job_id_with_query_params(self):
        """Test job_id extraction ignores query parameters"""
        url = "https://api.workers.dev/jobs/job-xyz-789/callback?foo=bar"
        job_id = _extract_job_id(url)
        assert job_id == "job-xyz-789"

    def test_extract_job_id_different_domain(self):
        """Test job_id extraction works with different domain"""
        url = "http://localhost:8000/jobs/test-job-id/callback"
        job_id = _extract_job_id(url)
        assert job_id == "test-job-id"

    def test_extract_job_id_invalid_url(self):
        """Test job_id extraction raises ValueError on invalid URL pattern"""
        invalid_url = "https://api.workers.dev/invalid/path"
        with pytest.raises(ValueError) as exc_info:
            _extract_job_id(invalid_url)
        assert "Cannot extract job_id" in str(exc_info.value)
        assert invalid_url in str(exc_info.value)

    def test_extract_job_id_missing_callback_path(self):
        """Test job_id extraction fails if /callback suffix is missing"""
        url = "https://api.workers.dev/jobs/job-123/other"
        with pytest.raises(ValueError):
            _extract_job_id(url)


class TestIdempotencyKeyGeneration:
    """Test _generate_idempotency_key() helper function"""

    def test_idempotency_key_deterministic(self):
        """Test idempotency key is deterministic for same inputs"""
        job_id = "job-123"
        idx = 5
        attempt = 1

        # Mock time.time() to return consistent value
        with patch('engine.callback.time') as mock_time:
            mock_time.time.return_value = 1234567890.0
            key1 = _generate_idempotency_key(job_id, idx, attempt)
            key2 = _generate_idempotency_key(job_id, idx, attempt)

        assert key1 == key2
        assert len(key1) == 16  # SHA256 hash truncated to 16 chars
        assert isinstance(key1, str)

    def test_idempotency_key_changes_with_job_id(self):
        """Test idempotency key changes when job_id differs"""
        with patch('engine.callback.time') as mock_time:
            mock_time.time.return_value = 1234567890.0
            key1 = _generate_idempotency_key("job-1", 0, 1)
            key2 = _generate_idempotency_key("job-2", 0, 1)

        assert key1 != key2

    def test_idempotency_key_changes_with_idx(self):
        """Test idempotency key changes when idx differs"""
        with patch('engine.callback.time') as mock_time:
            mock_time.time.return_value = 1234567890.0
            key1 = _generate_idempotency_key("job-123", 0, 1)
            key2 = _generate_idempotency_key("job-123", 1, 1)

        assert key1 != key2

    def test_idempotency_key_changes_with_attempt(self):
        """Test idempotency key changes when attempt differs"""
        with patch('engine.callback.time') as mock_time:
            mock_time.time.return_value = 1234567890.0
            key1 = _generate_idempotency_key("job-123", 0, 1)
            key2 = _generate_idempotency_key("job-123", 0, 2)

        assert key1 != key2

    def test_idempotency_key_time_window(self):
        """Test idempotency key uses 1-minute time window"""
        job_id = "job-test"
        idx = 0
        attempt = 1

        # Same minute (within 60 seconds) should produce same key
        # Use a base time that's evenly divisible by 60
        base_time = 1234567800.0  # This is at the start of a minute window
        with patch('engine.callback.time') as mock_time:
            # Test times within same 60-second window
            mock_time.time.return_value = base_time
            key1 = _generate_idempotency_key(job_id, idx, attempt)

            mock_time.time.return_value = base_time + 59
            key2 = _generate_idempotency_key(job_id, idx, attempt)

            assert key1 == key2

            # Different minute (60+ seconds) should produce different key
            mock_time.time.return_value = base_time + 60
            key3 = _generate_idempotency_key(job_id, idx, attempt)

            assert key1 != key3

    def test_idempotency_key_default_attempt(self):
        """Test idempotency key generation with default attempt=1"""
        with patch('engine.callback.time') as mock_time:
            mock_time.time.return_value = 1234567890.0
            key1 = _generate_idempotency_key("job-123", 0, 1)
            key2 = _generate_idempotency_key("job-123", 0)  # Default attempt=1

        assert key1 == key2


class TestCallbackReport:
    """Test report() function"""

    def test_report_success(self, mock_env, mock_httpx_client):
        """Test successful callback POST request"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        result = report(
            callback_url=callback_url,
            idx=0,
            status="completed",
            output_key="outputs/user/job/rule/0.jpg",
            preview_key="previews/user/job/0_preview.jpg"
        )

        assert result is True
        assert mock_httpx_client.post.call_count == 1

        # Verify POST was called with correct URL
        call_args = mock_httpx_client.post.call_args
        assert call_args[0][0] == callback_url

    def test_report_auth_header_present(self, mock_env, mock_httpx_client):
        """Test callback includes X-GPU-Callback-Secret header"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        report(callback_url=callback_url, idx=0, status="completed")

        # Verify headers include GPU callback secret
        call_args = mock_httpx_client.post.call_args
        headers = call_args[1]['headers']
        assert 'X-GPU-Callback-Secret' in headers
        assert headers['X-GPU-Callback-Secret'] == "test-secret-key-12345"

    def test_report_idempotency_header_present(self, mock_env, mock_httpx_client):
        """Test callback includes X-Idempotency-Key header"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        report(callback_url=callback_url, idx=0, status="completed")

        # Verify headers include idempotency key
        call_args = mock_httpx_client.post.call_args
        headers = call_args[1]['headers']
        assert 'X-Idempotency-Key' in headers
        assert len(headers['X-Idempotency-Key']) == 16

    def test_report_custom_idempotency_key(self, mock_env, mock_httpx_client):
        """Test callback accepts custom idempotency key"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        custom_key = "custom-key-12345"
        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        report(
            callback_url=callback_url,
            idx=0,
            status="completed",
            idempotency_key=custom_key
        )

        # Verify custom idempotency key is used
        call_args = mock_httpx_client.post.call_args
        headers = call_args[1]['headers']
        assert headers['X-Idempotency-Key'] == custom_key

    def test_report_content_type_header(self, mock_env, mock_httpx_client):
        """Test callback includes Content-Type: application/json header"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        report(callback_url=callback_url, idx=0, status="completed")

        # Verify Content-Type header
        call_args = mock_httpx_client.post.call_args
        headers = call_args[1]['headers']
        assert headers['Content-Type'] == "application/json"

    def test_report_payload_structure_completed(self, mock_env, mock_httpx_client):
        """Test callback payload structure for completed status"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-456/callback"
        report(
            callback_url=callback_url,
            idx=2,
            status="completed",
            output_key="outputs/user/job/rule/2.jpg",
            preview_key="previews/user/job/2_preview.jpg"
        )

        # Verify payload structure
        call_args = mock_httpx_client.post.call_args
        payload = call_args[1]['json']
        assert payload['idx'] == 2
        assert payload['status'] == "completed"
        assert payload['output_key'] == "outputs/user/job/rule/2.jpg"
        assert payload['preview_key'] == "previews/user/job/2_preview.jpg"
        assert 'error' not in payload  # Should not include error field for success

    def test_report_payload_structure_failed(self, mock_env, mock_httpx_client):
        """Test callback payload structure for failed status"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-789/callback"
        report(
            callback_url=callback_url,
            idx=1,
            status="failed",
            error="GPU out of memory"
        )

        # Verify payload structure for failed status
        call_args = mock_httpx_client.post.call_args
        payload = call_args[1]['json']
        assert payload['idx'] == 1
        assert payload['status'] == "failed"
        assert payload['error'] == "GPU out of memory"
        assert 'output_key' not in payload  # Should not include output keys for failure
        assert 'preview_key' not in payload

    def test_report_payload_optional_fields(self, mock_env, mock_httpx_client):
        """Test callback payload excludes None optional fields"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        report(
            callback_url=callback_url,
            idx=0,
            status="completed",
            output_key=None,
            preview_key=None,
            error=None
        )

        # Verify None fields are excluded from payload
        call_args = mock_httpx_client.post.call_args
        payload = call_args[1]['json']
        assert 'output_key' not in payload
        assert 'preview_key' not in payload
        assert 'error' not in payload

    def test_report_timeout_configuration(self, mock_env, mock_httpx_client):
        """Test callback uses configured timeout"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.CALLBACK_TIMEOUT', 10):
            report(callback_url=callback_url, idx=0, status="completed")

        # Verify httpx.Client was created with correct timeout
        with patch('engine.callback.httpx.Client') as mock_client_class:
            mock_client = MagicMock()
            mock_client_class.return_value.__enter__ = Mock(return_value=mock_client)
            mock_client_class.return_value.__exit__ = Mock(return_value=None)
            mock_response = Mock()
            mock_response.raise_for_status = Mock()
            mock_client.post.return_value = mock_response

            report(callback_url=callback_url, idx=0, status="completed")
            mock_client_class.assert_called_once_with(timeout=10)

    def test_report_retry_on_http_error(self, mock_env, mock_httpx_client):
        """Test callback retries once on HTTP error"""
        # First attempt fails, second attempt succeeds
        mock_response_fail = Mock()
        mock_response_fail.raise_for_status.side_effect = httpx.HTTPError("Connection error")

        mock_response_success = Mock()
        mock_response_success.raise_for_status = Mock()

        mock_httpx_client.post.side_effect = [mock_response_fail, mock_response_success]

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep') as mock_sleep:
            result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is True
        assert mock_httpx_client.post.call_count == 2  # Original + 1 retry
        mock_sleep.assert_called_once_with(1)  # Verify 1-second delay between retries

    def test_report_retry_exhaustion(self, mock_env, mock_httpx_client):
        """Test callback returns False after retry exhaustion"""
        # Both attempts fail
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = httpx.HTTPError("Connection error")
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep'):
            with patch('builtins.print') as mock_print:  # Capture warning log
                result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is False
        assert mock_httpx_client.post.call_count == 2  # Original + 1 retry
        # Verify warning was logged
        assert mock_print.called
        warning_msg = str(mock_print.call_args[0][0])
        assert "WARNING" in warning_msg
        assert "Callback failed" in warning_msg

    def test_report_no_exception_on_failure(self, mock_env, mock_httpx_client):
        """Test callback doesn't raise exception on failure (returns False instead)"""
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = httpx.HTTPError("Connection timeout")
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep'):
            with patch('builtins.print'):
                # Should not raise exception
                result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is False

    def test_report_handles_connection_error(self, mock_env, mock_httpx_client):
        """Test callback handles connection errors gracefully"""
        mock_httpx_client.post.side_effect = httpx.ConnectError("Cannot connect to host")

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep'):
            with patch('builtins.print'):
                result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is False
        assert mock_httpx_client.post.call_count == 2  # Original + 1 retry

    def test_report_handles_timeout_error(self, mock_env, mock_httpx_client):
        """Test callback handles timeout errors gracefully"""
        mock_httpx_client.post.side_effect = httpx.TimeoutException("Request timeout")

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep'):
            with patch('builtins.print'):
                result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is False

    def test_report_handles_http_status_error(self, mock_env, mock_httpx_client):
        """Test callback handles HTTP status errors (4xx, 5xx)"""
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "500 Internal Server Error",
            request=Mock(),
            response=Mock()
        )
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"

        with patch('engine.callback.time.sleep'):
            with patch('builtins.print'):
                result = report(callback_url=callback_url, idx=0, status="completed")

        assert result is False


class TestCallbackEnvironmentVariables:
    """Test callback behavior with different environment configurations"""

    def test_report_without_callback_secret(self, mock_httpx_client):
        """Test callback works even without GPU_CALLBACK_SECRET set"""
        with patch.dict(os.environ, {}, clear=False):
            # Remove GPU_CALLBACK_SECRET if it exists
            os.environ.pop("GPU_CALLBACK_SECRET", None)

            mock_response = Mock()
            mock_response.raise_for_status = Mock()
            mock_httpx_client.post.return_value = mock_response

            callback_url = "https://api.workers.dev/jobs/job-123/callback"
            result = report(callback_url=callback_url, idx=0, status="completed")

            assert result is True
            # Verify header is still included but empty
            call_args = mock_httpx_client.post.call_args
            headers = call_args[1]['headers']
            assert headers['X-GPU-Callback-Secret'] == ""

    def test_report_custom_timeout(self, mock_httpx_client):
        """Test callback respects custom CALLBACK_TIMEOUT_SEC"""
        with patch.dict(os.environ, {"CALLBACK_TIMEOUT_SEC": "30"}, clear=False):
            with patch('engine.callback.httpx.Client') as mock_client_class:
                mock_client = MagicMock()
                mock_client_class.return_value.__enter__ = Mock(return_value=mock_client)
                mock_client_class.return_value.__exit__ = Mock(return_value=None)
                mock_response = Mock()
                mock_response.raise_for_status = Mock()
                mock_client.post.return_value = mock_response

                # Reload module to pick up new env var
                import importlib
                import engine.callback as callback_module
                importlib.reload(callback_module)

                callback_url = "https://api.workers.dev/jobs/job-123/callback"
                callback_module.report(callback_url=callback_url, idx=0, status="completed")

                # Verify httpx.Client was created with custom timeout
                mock_client_class.assert_called_once_with(timeout=30)


class TestCallbackEdgeCases:
    """Test edge cases and boundary conditions"""

    def test_report_with_very_large_idx(self, mock_env, mock_httpx_client):
        """Test callback handles large idx values"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        result = report(callback_url=callback_url, idx=999999, status="completed")

        assert result is True
        call_args = mock_httpx_client.post.call_args
        payload = call_args[1]['json']
        assert payload['idx'] == 999999

    def test_report_with_special_characters_in_keys(self, mock_env, mock_httpx_client):
        """Test callback handles special characters in output keys"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        result = report(
            callback_url=callback_url,
            idx=0,
            status="completed",
            output_key="outputs/user@email.com/job-123/rule_name/0.jpg"
        )

        assert result is True

    def test_report_with_unicode_error_message(self, mock_env, mock_httpx_client):
        """Test callback handles unicode characters in error messages"""
        mock_response = Mock()
        mock_response.raise_for_status = Mock()
        mock_httpx_client.post.return_value = mock_response

        callback_url = "https://api.workers.dev/jobs/job-123/callback"
        result = report(
            callback_url=callback_url,
            idx=0,
            status="failed",
            error="Error: 파일을 찾을 수 없습니다 (File not found)"
        )

        assert result is True
        call_args = mock_httpx_client.post.call_args
        payload = call_args[1]['json']
        assert "파일을 찾을 수 없습니다" in payload['error']
