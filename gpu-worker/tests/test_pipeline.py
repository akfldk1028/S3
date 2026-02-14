"""
Integration tests for full pipeline with all mocks

Tests verify:
- Full end-to-end flow from job spec to callbacks
- Two-stage pipeline: segment once, apply rules N times
- Per-item callbacks after each upload
- Error handling for partial job failures
- Protect mask functionality
- Batch concurrency processing
- R2 upload/download integration
"""

import os
import io
import pytest
import numpy as np
from unittest.mock import Mock, patch, MagicMock, call
from PIL import Image
import sys

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Mock torch and transformers before importing pipeline
sys.modules['torch'] = MagicMock()
sys.modules['transformers'] = MagicMock()

from engine.pipeline import process_job, _callback_failure


@pytest.fixture
def mock_env():
    """Set up environment variables for testing"""
    env_vars = {
        "HF_TOKEN": "test-hf-token",
        "R2_ACCOUNT_ID": "test-account",
        "R2_ACCESS_KEY_ID": "test-key",
        "R2_SECRET_ACCESS_KEY": "test-secret",
        "R2_BUCKET_NAME": "test-bucket",
        "GPU_CALLBACK_SECRET": "test-callback-secret",
        "CALLBACK_TIMEOUT_SEC": "10",
        "BATCH_CONCURRENCY": "2",
        "LOG_LEVEL": "ERROR"  # Reduce noise in test output
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield env_vars


@pytest.fixture
def test_image():
    """Create a test image for pipeline processing"""
    img_array = np.zeros((100, 100, 3), dtype=np.uint8)
    img_array[:, :] = [128, 128, 128]  # Gray
    return Image.fromarray(img_array, mode='RGB')


@pytest.fixture
def test_image_bytes(test_image):
    """Convert test image to bytes"""
    buffer = io.BytesIO()
    test_image.save(buffer, format='JPEG')
    return buffer.getvalue()


@pytest.fixture
def mock_sam3_segmenter():
    """Mock SAM3Segmenter to avoid model loading"""
    with patch('engine.pipeline.SAM3Segmenter') as mock_segmenter_class:
        mock_segmenter = MagicMock()

        # Mock segment() to return dummy masks and metadata
        def segment_side_effect(image, concept_text):
            # Return single instance mask for simplicity
            mask = np.ones((100, 100), dtype=np.uint8) * 255
            metadata = {
                "concept": concept_text,
                "instance_count": 1,
                "scores": [0.95]
            }
            return [mask], metadata

        mock_segmenter.segment.side_effect = segment_side_effect
        mock_segmenter_class.return_value = mock_segmenter

        yield mock_segmenter


@pytest.fixture
def mock_r2_client(test_image_bytes):
    """Mock R2Client to avoid actual R2 connections"""
    with patch('engine.pipeline.R2Client') as mock_client_class:
        mock_client = MagicMock()

        # Mock download to return test image bytes
        mock_client.download.return_value = test_image_bytes

        # Mock upload to succeed silently
        mock_client.upload.return_value = None

        mock_client_class.return_value = mock_client

        yield mock_client


@pytest.fixture
def mock_callback():
    """Mock callback report function"""
    with patch('engine.pipeline.report') as mock_report:
        mock_report.return_value = True  # Callback succeeds
        yield mock_report


@pytest.fixture
def basic_job_message():
    """Basic job message for testing"""
    return {
        "job_id": "job-test-123",
        "user_id": "user-abc",
        "preset": "interior",
        "concepts": {
            "Floor": {"action": "recolor", "value": "#FF5733"}
        },
        "protect": [],
        "items": [
            {
                "idx": 0,
                "input_key": "inputs/user-abc/job-test-123/0.jpg",
                "output_key": "outputs/user-abc/job-test-123/0_result.png",
                "preview_key": "previews/user-abc/job-test-123/0_preview.jpg"
            }
        ],
        "callback_url": "https://api.workers.dev/jobs/job-test-123/callback",
        "batch_concurrency": 2
    }


class TestPipelineBasicFlow:
    """Test basic pipeline flow with successful processing"""

    def test_process_job_basic(self, mock_env, mock_sam3_segmenter, mock_r2_client,
                                 mock_callback, basic_job_message):
        """Test basic end-to-end job processing"""
        result = process_job(basic_job_message)

        # Verify result summary
        assert result["total_items"] == 1
        assert result["successful_items"] == 1
        assert result["failed_items"] == 0
        assert len(result["errors"]) == 0

        # Verify segmenter was called
        assert mock_sam3_segmenter.segment.called

        # Verify R2 download was called
        mock_r2_client.download.assert_called()

        # Verify R2 upload was called for output and preview
        assert mock_r2_client.upload.call_count >= 2  # At least output + preview

        # Verify callback was called with correct status
        mock_callback.assert_called()
        callback_calls = [call for call in mock_callback.call_args_list
                          if call[1].get('status') == 'completed']
        assert len(callback_calls) == 1

    def test_process_job_multiple_items(self, mock_env, mock_sam3_segmenter,
                                        mock_r2_client, mock_callback):
        """Test processing multiple items in a single job"""
        job_message = {
            "job_id": "job-multi",
            "user_id": "user-123",
            "concepts": {
                "Wall": {"action": "recolor", "value": "#AABBCC"}
            },
            "protect": [],
            "items": [
                {
                    "idx": 0,
                    "input_key": "inputs/user-123/job-multi/0.jpg",
                    "output_key": "outputs/user-123/job-multi/0.png",
                    "preview_key": "previews/user-123/job-multi/0.jpg"
                },
                {
                    "idx": 1,
                    "input_key": "inputs/user-123/job-multi/1.jpg",
                    "output_key": "outputs/user-123/job-multi/1.png",
                    "preview_key": "previews/user-123/job-multi/1.jpg"
                },
                {
                    "idx": 2,
                    "input_key": "inputs/user-123/job-multi/2.jpg",
                    "output_key": "outputs/user-123/job-multi/2.png",
                    "preview_key": "previews/user-123/job-multi/2.jpg"
                }
            ],
            "callback_url": "https://api.workers.dev/jobs/job-multi/callback"
        }

        result = process_job(job_message)

        # Verify all items processed
        assert result["total_items"] == 3
        assert result["successful_items"] == 3
        assert result["failed_items"] == 0

        # Verify R2 downloads for each item
        assert mock_r2_client.download.call_count >= 3

        # Verify callbacks for each item
        completed_callbacks = [call for call in mock_callback.call_args_list
                               if call[1].get('status') == 'completed']
        assert len(completed_callbacks) == 3


class TestPipelineTwoStagePattern:
    """Test two-stage pipeline pattern: segment once, apply many"""

    def test_segment_called_once_per_concept(self, mock_env, mock_sam3_segmenter,
                                              mock_r2_client, mock_callback):
        """Test that segmentation happens once per concept, not per item"""
        job_message = {
            "job_id": "job-2stage",
            "user_id": "user-abc",
            "concepts": {
                "Floor": {"action": "recolor", "value": "#FF0000"},
                "Wall": {"action": "recolor", "value": "#00FF00"}
            },
            "protect": [],
            "items": [
                {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"},
                {"idx": 1, "input_key": "in/1.jpg", "output_key": "out/1.png", "preview_key": "prev/1.jpg"},
                {"idx": 2, "input_key": "in/2.jpg", "output_key": "out/2.png", "preview_key": "prev/2.jpg"}
            ],
            "callback_url": "https://api.workers.dev/jobs/job-2stage/callback"
        }

        result = process_job(job_message)

        # Verify segmenter.segment() was called exactly once per concept (2 concepts)
        # Not once per item (which would be 6 calls for 2 concepts * 3 items)
        segment_calls = mock_sam3_segmenter.segment.call_count
        assert segment_calls == 2  # Only 2 concepts, called once each

        # Verify all items still processed successfully
        assert result["successful_items"] == 3

    def test_masks_reused_across_items(self, mock_env, mock_sam3_segmenter,
                                       mock_r2_client, mock_callback, basic_job_message):
        """Test that masks from Stage 1 are reused in Stage 2 for all items"""
        # Add more items to basic job
        basic_job_message["items"].extend([
            {"idx": 1, "input_key": "in/1.jpg", "output_key": "out/1.png", "preview_key": "prev/1.jpg"},
            {"idx": 2, "input_key": "in/2.jpg", "output_key": "out/2.png", "preview_key": "prev/2.jpg"}
        ])

        # Track segment calls
        segment_calls_before = mock_sam3_segmenter.segment.call_count

        result = process_job(basic_job_message)

        # Segmentation should only happen once per concept (1 concept in basic job)
        segment_calls_after = mock_sam3_segmenter.segment.call_count
        new_segment_calls = segment_calls_after - segment_calls_before

        # Should be 1 call for 1 concept, not 3 calls for 3 items
        assert new_segment_calls == 1

        # But all 3 items should be processed
        assert result["successful_items"] == 3


class TestPipelineWithProtect:
    """Test pipeline with protect masks"""

    def test_process_job_with_protect(self, mock_env, mock_sam3_segmenter,
                                      mock_r2_client, mock_callback):
        """Test that protect concepts are segmented and combined"""
        job_message = {
            "job_id": "job-protect",
            "user_id": "user-xyz",
            "concepts": {
                "Floor": {"action": "recolor", "value": "#FF5733"}
            },
            "protect": ["Grout", "Trim"],  # Two protect concepts
            "items": [
                {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
            ],
            "callback_url": "https://api.workers.dev/jobs/job-protect/callback"
        }

        result = process_job(job_message)

        # Verify segmentation was called for main concepts + protect concepts
        segment_calls = mock_sam3_segmenter.segment.call_count
        assert segment_calls == 3  # 1 main concept + 2 protect concepts

        # Verify job succeeded
        assert result["successful_items"] == 1
        assert result["failed_items"] == 0

    def test_protect_concepts_in_segment_calls(self, mock_env, mock_sam3_segmenter,
                                                mock_r2_client, mock_callback):
        """Test that protect concept names are passed to segmenter"""
        job_message = {
            "job_id": "job-protect-names",
            "user_id": "user-test",
            "concepts": {
                "Wall": {"action": "recolor", "value": "#AABBCC"}
            },
            "protect": ["Window", "Door"],
            "items": [
                {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
            ],
            "callback_url": "https://api.workers.dev/callback"
        }

        process_job(job_message)

        # Extract all concept names passed to segment()
        segment_call_args = [call[0][1] for call in mock_sam3_segmenter.segment.call_args_list]

        # Should include main concept and protect concepts
        assert "Wall" in segment_call_args
        assert "Window" in segment_call_args
        assert "Door" in segment_call_args


class TestPipelineCallbacks:
    """Test per-item callback functionality"""

    def test_callback_per_item(self, mock_env, mock_sam3_segmenter,
                                mock_r2_client, mock_callback):
        """Test that callbacks are sent for each item individually"""
        job_message = {
            "job_id": "job-callbacks",
            "user_id": "user-123",
            "concepts": {
                "Floor": {"action": "recolor", "value": "#FF0000"}
            },
            "protect": [],
            "items": [
                {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"},
                {"idx": 1, "input_key": "in/1.jpg", "output_key": "out/1.png", "preview_key": "prev/1.jpg"},
                {"idx": 2, "input_key": "in/2.jpg", "output_key": "out/2.png", "preview_key": "prev/2.jpg"}
            ],
            "callback_url": "https://api.workers.dev/jobs/job-callbacks/callback"
        }

        result = process_job(job_message)

        # Verify callbacks called for each item
        assert mock_callback.call_count == 3

        # Verify callback includes correct idx values
        callback_indices = [call[1]['idx'] for call in mock_callback.call_args_list]
        assert set(callback_indices) == {0, 1, 2}

    def test_callback_includes_output_keys(self, mock_env, mock_sam3_segmenter,
                                           mock_r2_client, mock_callback, basic_job_message):
        """Test that callbacks include output_key and preview_key"""
        process_job(basic_job_message)

        # Get the callback call
        assert mock_callback.called
        callback_args = mock_callback.call_args[1]

        # Verify keys are included
        assert 'output_key' in callback_args
        assert 'preview_key' in callback_args
        assert callback_args['output_key'] == "outputs/user-abc/job-test-123/0_result.png"
        assert callback_args['preview_key'] == "previews/user-abc/job-test-123/0_preview.jpg"

    def test_callback_status_completed(self, mock_env, mock_sam3_segmenter,
                                       mock_r2_client, mock_callback, basic_job_message):
        """Test that successful items get status='completed' in callback"""
        process_job(basic_job_message)

        callback_args = mock_callback.call_args[1]
        assert callback_args['status'] == 'completed'

    def test_callback_failure_retry(self, mock_env, mock_sam3_segmenter,
                                    mock_r2_client, basic_job_message):
        """Test that job continues even if callback fails"""
        with patch('engine.pipeline.report') as mock_report:
            # Make callback fail
            mock_report.return_value = False

            result = process_job(basic_job_message)

            # Job should still succeed even if callback failed
            assert result["successful_items"] == 1
            assert result["failed_items"] == 0


class TestPipelineErrorHandling:
    """Test error handling for various failure scenarios"""

    def test_r2_download_failure(self, mock_env, mock_sam3_segmenter, mock_callback):
        """Test handling of R2 download failure"""
        with patch('engine.pipeline.R2Client') as mock_client_class:
            mock_client = MagicMock()
            # Make download fail
            mock_client.download.side_effect = RuntimeError("Failed to download from R2")
            mock_client_class.return_value = mock_client

            job_message = {
                "job_id": "job-fail",
                "user_id": "user-123",
                "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
                "protect": [],
                "items": [
                    {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
                ],
                "callback_url": "https://api.workers.dev/callback"
            }

            result = process_job(job_message)

            # All items should fail due to download failure
            assert result["failed_items"] == 1
            assert result["successful_items"] == 0
            assert len(result["errors"]) > 0

    def test_segmenter_initialization_failure(self, mock_env, mock_r2_client, mock_callback):
        """Test handling of segmenter initialization failure"""
        with patch('engine.pipeline.SAM3Segmenter') as mock_segmenter_class:
            # Make segmenter initialization fail
            mock_segmenter_class.side_effect = RuntimeError("Failed to load SAM3 model")

            job_message = {
                "job_id": "job-segmenter-fail",
                "user_id": "user-123",
                "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
                "protect": [],
                "items": [
                    {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
                ],
                "callback_url": "https://api.workers.dev/callback"
            }

            result = process_job(job_message)

            # All items should fail
            assert result["failed_items"] == 1
            assert result["successful_items"] == 0
            assert len(result["errors"]) > 0

            # Verify failure callback was sent
            failure_callbacks = [call for call in mock_callback.call_args_list
                                 if call[1].get('status') == 'failed']
            assert len(failure_callbacks) == 1

    def test_partial_job_success(self, mock_env, mock_sam3_segmenter, mock_callback):
        """Test that job continues when some items fail but others succeed"""
        with patch('engine.pipeline.R2Client') as mock_client_class:
            mock_client = MagicMock()

            # Make download succeed for some items, fail for others
            download_count = [0]  # Use list to allow modification in nested function

            def download_side_effect(key):
                download_count[0] += 1
                if download_count[0] == 2:  # Fail on second item
                    raise RuntimeError("Download failed for item 1")
                # Return test image bytes for others
                img_array = np.zeros((100, 100, 3), dtype=np.uint8)
                img = Image.fromarray(img_array)
                buffer = io.BytesIO()
                img.save(buffer, format='JPEG')
                return buffer.getvalue()

            mock_client.download.side_effect = download_side_effect
            mock_client.upload.return_value = None
            mock_client_class.return_value = mock_client

            job_message = {
                "job_id": "job-partial",
                "user_id": "user-123",
                "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
                "protect": [],
                "items": [
                    {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"},
                    {"idx": 1, "input_key": "in/1.jpg", "output_key": "out/1.png", "preview_key": "prev/1.jpg"},
                    {"idx": 2, "input_key": "in/2.jpg", "output_key": "out/2.png", "preview_key": "prev/2.jpg"}
                ],
                "callback_url": "https://api.workers.dev/callback"
            }

            result = process_job(job_message)

            # Should have partial success
            assert result["total_items"] == 3
            assert result["successful_items"] == 2
            assert result["failed_items"] == 1

            # Verify callbacks sent for both successful and failed items
            assert mock_callback.call_count == 3

            # Verify failed callback includes error
            failed_callbacks = [call for call in mock_callback.call_args_list
                                if call[1].get('status') == 'failed']
            assert len(failed_callbacks) == 1
            assert 'error' in failed_callbacks[0][1]

    def test_concept_segmentation_failure(self, mock_env, mock_r2_client, mock_callback):
        """Test that job continues if one concept fails to segment"""
        with patch('engine.pipeline.SAM3Segmenter') as mock_segmenter_class:
            mock_segmenter = MagicMock()

            # Make segment fail for specific concept
            def segment_side_effect(image, concept_text):
                if concept_text == "Floor":
                    raise RuntimeError("Failed to segment Floor")
                # Return dummy mask for other concepts
                mask = np.ones((100, 100), dtype=np.uint8) * 255
                metadata = {"concept": concept_text, "instance_count": 1, "scores": [0.95]}
                return [mask], metadata

            mock_segmenter.segment.side_effect = segment_side_effect
            mock_segmenter_class.return_value = mock_segmenter

            job_message = {
                "job_id": "job-concept-fail",
                "user_id": "user-123",
                "concepts": {
                    "Floor": {"action": "recolor", "value": "#FF0000"},
                    "Wall": {"action": "recolor", "value": "#00FF00"}
                },
                "protect": [],
                "items": [
                    {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
                ],
                "callback_url": "https://api.workers.dev/callback"
            }

            result = process_job(job_message)

            # Job should still succeed (Floor failed but Wall succeeded)
            assert result["successful_items"] == 1
            # But errors should be recorded
            assert len(result["errors"]) > 0
            assert any("Floor" in error for error in result["errors"])


class TestPipelineEdgeCases:
    """Test edge cases and boundary conditions"""

    def test_empty_items_list(self, mock_env, mock_sam3_segmenter,
                              mock_r2_client, mock_callback):
        """Test job with no items returns early"""
        job_message = {
            "job_id": "job-empty",
            "user_id": "user-123",
            "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
            "protect": [],
            "items": [],
            "callback_url": "https://api.workers.dev/callback"
        }

        result = process_job(job_message)

        assert result["total_items"] == 0
        assert result["successful_items"] == 0
        assert result["failed_items"] == 0

        # Segmenter should not be called
        assert not mock_sam3_segmenter.segment.called

    def test_no_protect_concepts(self, mock_env, mock_sam3_segmenter,
                                  mock_r2_client, mock_callback, basic_job_message):
        """Test job with empty protect list"""
        basic_job_message["protect"] = []

        result = process_job(basic_job_message)

        # Should succeed normally
        assert result["successful_items"] == 1
        assert result["failed_items"] == 0

    def test_no_preview_key(self, mock_env, mock_sam3_segmenter,
                            mock_r2_client, mock_callback):
        """Test item without preview_key"""
        job_message = {
            "job_id": "job-no-preview",
            "user_id": "user-123",
            "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
            "protect": [],
            "items": [
                {
                    "idx": 0,
                    "input_key": "in/0.jpg",
                    "output_key": "out/0.png"
                    # No preview_key
                }
            ],
            "callback_url": "https://api.workers.dev/callback"
        }

        result = process_job(job_message)

        # Should succeed
        assert result["successful_items"] == 1

        # Verify callback doesn't include preview_key or it's None
        callback_args = mock_callback.call_args[1]
        preview = callback_args.get('preview_key')
        assert preview is None or preview == ""

    def test_custom_batch_concurrency(self, mock_env, mock_sam3_segmenter,
                                      mock_r2_client, mock_callback):
        """Test that batch_concurrency from job message is respected"""
        job_message = {
            "job_id": "job-concurrency",
            "user_id": "user-123",
            "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
            "protect": [],
            "items": [
                {"idx": i, "input_key": f"in/{i}.jpg", "output_key": f"out/{i}.png", "preview_key": f"prev/{i}.jpg"}
                for i in range(5)
            ],
            "callback_url": "https://api.workers.dev/callback",
            "batch_concurrency": 8
        }

        result = process_job(job_message)

        # All items should be processed
        assert result["successful_items"] == 5
        assert result["failed_items"] == 0


class TestCallbackFailureHelper:
    """Test _callback_failure helper function"""

    def test_callback_failure_helper(self, mock_env):
        """Test _callback_failure sends correct callback"""
        with patch('engine.pipeline.report') as mock_report:
            callback_url = "https://api.workers.dev/jobs/test/callback"
            idx = 5
            error_msg = "Test error message"

            _callback_failure(callback_url, idx, error_msg)

            # Verify report was called with correct args
            mock_report.assert_called_once()
            call_args = mock_report.call_args[1]
            assert call_args['callback_url'] == callback_url
            assert call_args['idx'] == idx
            assert call_args['status'] == 'failed'
            assert call_args['error'] == error_msg

    def test_callback_failure_helper_empty_url(self, mock_env):
        """Test _callback_failure handles empty callback URL"""
        with patch('engine.pipeline.report') as mock_report:
            # Should not raise exception with empty URL
            _callback_failure("", 0, "error")

            # report should not be called if URL is empty
            assert not mock_report.called


class TestPipelineR2Integration:
    """Test R2 upload/download patterns"""

    def test_r2_upload_patterns(self, mock_env, mock_sam3_segmenter,
                                mock_callback, test_image_bytes):
        """Test that R2 uploads follow correct key patterns"""
        with patch('engine.pipeline.R2Client') as mock_client_class:
            mock_client = MagicMock()
            mock_client.download.return_value = test_image_bytes
            mock_client.upload.return_value = None
            mock_client_class.return_value = mock_client

            job_message = {
                "job_id": "job-r2",
                "user_id": "user-r2",
                "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
                "protect": [],
                "items": [
                    {
                        "idx": 0,
                        "input_key": "inputs/user-r2/job-r2/0.jpg",
                        "output_key": "outputs/user-r2/job-r2/result/0.png",
                        "preview_key": "previews/user-r2/job-r2/0_preview.jpg"
                    }
                ],
                "callback_url": "https://api.workers.dev/callback"
            }

            process_job(job_message)

            # Verify upload was called with output and preview keys
            upload_calls = mock_client.upload.call_args_list
            upload_keys = [call[0][0] for call in upload_calls]

            assert "outputs/user-r2/job-r2/result/0.png" in upload_keys
            assert "previews/user-r2/job-r2/0_preview.jpg" in upload_keys

    def test_preview_thumbnail_size(self, mock_env, mock_sam3_segmenter,
                                    mock_r2_client, mock_callback):
        """Test that preview images are thumbnailed to max 400px"""
        # Create a large test image
        large_image = Image.new('RGB', (800, 600), color='red')
        buffer = io.BytesIO()
        large_image.save(buffer, format='JPEG')
        large_image_bytes = buffer.getvalue()

        # Mock R2 to return large image
        mock_r2_client.download.return_value = large_image_bytes

        job_message = {
            "job_id": "job-thumb",
            "user_id": "user-123",
            "concepts": {"Floor": {"action": "recolor", "value": "#FF0000"}},
            "protect": [],
            "items": [
                {"idx": 0, "input_key": "in/0.jpg", "output_key": "out/0.png", "preview_key": "prev/0.jpg"}
            ],
            "callback_url": "https://api.workers.dev/callback"
        }

        process_job(job_message)

        # Verify upload was called for preview
        # Find the preview upload call
        preview_uploads = [call for call in mock_r2_client.upload.call_args_list
                           if 'prev/0.jpg' in call[0][0]]
        assert len(preview_uploads) == 1

        # Verify preview image bytes are smaller than original
        preview_bytes = preview_uploads[0][0][1]
        assert len(preview_bytes) < len(large_image_bytes)
