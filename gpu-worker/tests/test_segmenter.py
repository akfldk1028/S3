"""
Unit tests for SAM3 Segmenter with mocked transformers

Tests verify:
- SAM3Segmenter initializes with HuggingFace token
- Model loading with cache directory configuration
- Device auto-detection (CUDA if available, CPU fallback)
- segment() returns correct structure (masks + metadata)
- Error handling for missing HF_TOKEN
- Multi-instance segmentation support
"""

import os
import pytest
import numpy as np
from unittest.mock import Mock, patch, MagicMock
import sys

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Mock torch and transformers before importing segmenter
# This prevents ModuleNotFoundError when torch is not installed
sys.modules['torch'] = MagicMock()
sys.modules['transformers'] = MagicMock()

# Import the module under test
from engine.segmenter import SAM3Segmenter


@pytest.fixture
def mock_env():
    """Set up environment variables for testing"""
    env_vars = {
        "HF_TOKEN": "test-hf-token-12345",
        "MODEL_CACHE_DIR": "/tmp/test-models"
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield env_vars


@pytest.fixture
def mock_torch():
    """Mock torch to avoid GPU dependency in tests"""
    with patch('engine.segmenter.torch') as mock_torch_module:
        # Mock CUDA availability (can be overridden in individual tests)
        mock_torch_module.cuda.is_available.return_value = False
        mock_torch_module.no_grad = lambda: MagicMock(__enter__=Mock(), __exit__=Mock())
        yield mock_torch_module


@pytest.fixture
def mock_transformers():
    """Mock transformers library to avoid 3.4GB model download"""
    with patch('engine.segmenter.Sam3Processor') as mock_processor_class, \
         patch('engine.segmenter.Sam3Model') as mock_model_class:

        # Mock processor instance
        mock_processor = MagicMock()
        mock_processor_class.from_pretrained.return_value = mock_processor

        # Mock model instance
        mock_model = MagicMock()
        mock_model.to.return_value = mock_model  # to() returns self
        mock_model_class.from_pretrained.return_value = mock_model

        yield {
            'processor_class': mock_processor_class,
            'model_class': mock_model_class,
            'processor': mock_processor,
            'model': mock_model
        }


class TestSAM3SegmenterInitialization:
    """Test SAM3Segmenter.__init__() method"""

    def test_init_with_env_vars(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter initializes with environment variables"""
        segmenter = SAM3Segmenter()

        # Verify HF_TOKEN was used
        mock_transformers['processor_class'].from_pretrained.assert_called_once_with(
            "facebook/sam3",
            token="test-hf-token-12345",
            cache_dir="/tmp/test-models"
        )

        mock_transformers['model_class'].from_pretrained.assert_called_once_with(
            "facebook/sam3",
            token="test-hf-token-12345",
            cache_dir="/tmp/test-models"
        )

    def test_init_uses_cache_dir_env(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter uses MODEL_CACHE_DIR environment variable"""
        segmenter = SAM3Segmenter()

        # Verify cache_dir from environment variable was used
        call_args = mock_transformers['processor_class'].from_pretrained.call_args
        assert call_args[1]['cache_dir'] == "/tmp/test-models"

    def test_init_uses_model_path_parameter(self, mock_torch, mock_transformers):
        """Test segmenter uses model_path parameter when env var not set"""
        with patch.dict(os.environ, {"HF_TOKEN": "test-token"}, clear=False):
            # Remove MODEL_CACHE_DIR if it exists
            os.environ.pop("MODEL_CACHE_DIR", None)

            segmenter = SAM3Segmenter(model_path="/custom/model/path")

            # Verify custom model_path was used as cache_dir
            call_args = mock_transformers['processor_class'].from_pretrained.call_args
            assert call_args[1]['cache_dir'] == "/custom/model/path"

    def test_init_default_model_path(self, mock_torch, mock_transformers):
        """Test segmenter uses default /models/sam3 when no env var or parameter"""
        with patch.dict(os.environ, {"HF_TOKEN": "test-token"}, clear=False):
            os.environ.pop("MODEL_CACHE_DIR", None)

            segmenter = SAM3Segmenter()

            # Verify default cache_dir was used
            call_args = mock_transformers['processor_class'].from_pretrained.call_args
            assert call_args[1]['cache_dir'] == "/models/sam3"

    def test_init_device_auto_detection_cuda(self, mock_env, mock_transformers):
        """Test device auto-detection selects CUDA when available"""
        with patch('engine.segmenter.torch') as mock_torch_module:
            mock_torch_module.cuda.is_available.return_value = True
            mock_torch_module.no_grad = lambda: MagicMock(__enter__=Mock(), __exit__=Mock())

            segmenter = SAM3Segmenter()

            assert segmenter.device == "cuda"

    def test_init_device_auto_detection_cpu(self, mock_env, mock_torch, mock_transformers):
        """Test device auto-detection falls back to CPU when CUDA unavailable"""
        segmenter = SAM3Segmenter()

        assert segmenter.device == "cpu"

    def test_init_model_moved_to_device(self, mock_env, mock_torch, mock_transformers):
        """Test model is moved to correct device via .to()"""
        segmenter = SAM3Segmenter()

        # Verify model.to(device) was called
        mock_transformers['model'].to.assert_called_once_with("cpu")

    def test_init_without_hf_token(self, mock_torch, mock_transformers):
        """Test segmenter raises ValueError when HF_TOKEN is missing"""
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("HF_TOKEN", None)

            with pytest.raises(ValueError) as exc_info:
                segmenter = SAM3Segmenter()

            error_msg = str(exc_info.value)
            assert "HF_TOKEN" in error_msg
            assert "environment variable is required" in error_msg
            assert "facebook/sam3" in error_msg

    def test_init_with_empty_hf_token(self, mock_torch, mock_transformers):
        """Test segmenter raises ValueError when HF_TOKEN is empty string"""
        with patch.dict(os.environ, {"HF_TOKEN": ""}, clear=False):

            with pytest.raises(ValueError) as exc_info:
                segmenter = SAM3Segmenter()

            assert "HF_TOKEN" in str(exc_info.value)

    def test_init_model_loading_failure(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter raises RuntimeError when model loading fails"""
        # Simulate model loading failure
        mock_transformers['model_class'].from_pretrained.side_effect = Exception(
            "Model not found or access denied"
        )

        with pytest.raises(RuntimeError) as exc_info:
            segmenter = SAM3Segmenter()

        error_msg = str(exc_info.value)
        assert "Failed to load SAM3 model" in error_msg
        assert "HF_TOKEN is valid" in error_msg
        assert "access to facebook/sam3" in error_msg

    def test_init_processor_loading_failure(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter raises RuntimeError when processor loading fails"""
        # Simulate processor loading failure
        mock_transformers['processor_class'].from_pretrained.side_effect = Exception(
            "Processor loading error"
        )

        with pytest.raises(RuntimeError) as exc_info:
            segmenter = SAM3Segmenter()

        assert "Failed to load SAM3 model" in str(exc_info.value)

    def test_init_stores_processor_and_model(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter stores processor and model as instance attributes"""
        segmenter = SAM3Segmenter()

        assert segmenter.processor is not None
        assert segmenter.model is not None
        assert segmenter.processor == mock_transformers['processor']
        assert segmenter.model == mock_transformers['model']


class TestSAM3SegmenterSegment:
    """Test SAM3Segmenter.segment() method"""

    @pytest.fixture
    def initialized_segmenter(self, mock_env, mock_torch, mock_transformers):
        """Create initialized segmenter for testing segment()"""
        segmenter = SAM3Segmenter()

        # Set up mock processor behavior
        mock_inputs = MagicMock()
        mock_inputs.to.return_value = mock_inputs
        segmenter.processor.return_value = mock_inputs

        # Set up mock model output
        mock_output = MagicMock()

        yield segmenter, mock_output, mock_inputs

    def test_segment_single_concept(self, initialized_segmenter):
        """Test segment() with single concept returns masks and metadata"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Mock single instance segmentation result
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256), dtype=np.float32)
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        # Create mock image
        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Run segmentation
        masks, metadata = segmenter.segment(test_image, "wall")

        # Verify return type
        assert isinstance(masks, np.ndarray)
        assert isinstance(metadata, dict)

        # Verify masks shape (1 instance, 256x256)
        assert masks.shape == (1, 256, 256)

        # Verify metadata structure
        assert metadata['concept'] == "wall"
        assert metadata['instance_count'] == 1
        assert metadata['scores'] == [0.95]

    def test_segment_multi_instance(self, initialized_segmenter):
        """Test segment() with multi-instance concept (e.g., multiple windows)"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Mock multi-instance segmentation result (3 instances)
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((3, 256, 256), dtype=np.float32)
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95, 0.89, 0.87]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Run segmentation
        masks, metadata = segmenter.segment(test_image, "window")

        # Verify 3 instances detected
        assert masks.shape == (3, 256, 256)
        assert metadata['concept'] == "window"
        assert metadata['instance_count'] == 3
        assert len(metadata['scores']) == 3

    def test_segment_processor_called_correctly(self, initialized_segmenter):
        """Test segment() calls processor with correct parameters"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))
        concept_text = "door"

        # Run segmentation
        segmenter.segment(test_image, concept_text)

        # Verify processor was called with correct arguments
        segmenter.processor.assert_called_once_with(
            images=test_image,
            text=concept_text,
            return_tensors="pt"
        )

        # Verify inputs were moved to device
        mock_inputs.to.assert_called_once_with(segmenter.device)

    def test_segment_model_inference_no_grad(self, initialized_segmenter):
        """Test segment() runs model inference without gradient computation"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Mock torch.no_grad() to verify it's used
        with patch('engine.segmenter.torch.no_grad') as mock_no_grad:
            mock_no_grad.return_value.__enter__ = Mock()
            mock_no_grad.return_value.__exit__ = Mock()

            segmenter.segment(test_image, "floor")

            # Verify no_grad() was called
            mock_no_grad.assert_called_once()

    def test_segment_masks_moved_to_cpu(self, initialized_segmenter):
        """Test segment() moves masks to CPU before converting to numpy"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output with chained calls
        mock_pred_masks = MagicMock()
        mock_cpu_masks = MagicMock()
        mock_cpu_masks.numpy.return_value = np.ones((1, 256, 256))
        mock_pred_masks.cpu.return_value = mock_cpu_masks
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_cpu_scores = MagicMock()
        mock_numpy_scores = MagicMock()
        mock_numpy_scores.tolist.return_value = [0.95]
        mock_cpu_scores.numpy.return_value = mock_numpy_scores
        mock_iou_scores.cpu.return_value = mock_cpu_scores
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Run segmentation
        masks, metadata = segmenter.segment(test_image, "ceiling")

        # Verify .cpu() was called on masks and scores
        mock_pred_masks.cpu.assert_called_once()
        mock_iou_scores.cpu.assert_called_once()

    def test_segment_metadata_structure(self, initialized_segmenter):
        """Test segment() returns metadata with all required fields"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((2, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.92, 0.88]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Run segmentation
        masks, metadata = segmenter.segment(test_image, "furniture")

        # Verify metadata has all required fields
        assert 'concept' in metadata
        assert 'instance_count' in metadata
        assert 'scores' in metadata

        # Verify field types
        assert isinstance(metadata['concept'], str)
        assert isinstance(metadata['instance_count'], int)
        assert isinstance(metadata['scores'], list)

    def test_segment_zero_instances(self, initialized_segmenter):
        """Test segment() handles case where no instances are found"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Mock zero instances found
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.array([])  # Empty array
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = []
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Run segmentation
        masks, metadata = segmenter.segment(test_image, "nonexistent-object")

        # Verify zero instances reported
        assert metadata['instance_count'] == 0
        assert len(metadata['scores']) == 0

    def test_segment_concept_text_preserved(self, initialized_segmenter):
        """Test segment() preserves exact concept text in metadata"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Test with various concept texts
        test_concepts = [
            "wall",
            "Window Frame",
            "kitchen cabinet",
            "Product (main item)"
        ]

        for concept in test_concepts:
            masks, metadata = segmenter.segment(test_image, concept)
            assert metadata['concept'] == concept

    def test_segment_different_resolutions(self, initialized_segmenter):
        """Test segment() works with different image resolutions"""
        segmenter, mock_output, mock_inputs = initialized_segmenter

        # Set up mock output
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        segmenter.model.return_value = mock_output

        from PIL import Image

        # Test various image sizes
        image_sizes = [(512, 512), (1024, 768), (256, 256), (2048, 1536)]

        for width, height in image_sizes:
            test_image = Image.new('RGB', (width, height))
            masks, metadata = segmenter.segment(test_image, "wall")

            # Should successfully segment regardless of input size
            assert isinstance(masks, np.ndarray)
            assert isinstance(metadata, dict)


class TestSAM3SegmenterIntegration:
    """Integration tests for SAM3Segmenter"""

    def test_segment_workflow_pattern(self, mock_env, mock_torch, mock_transformers):
        """Test typical workflow: initialize → segment multiple concepts"""
        # Set up mock output
        mock_output = MagicMock()
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        mock_transformers['model'].return_value = mock_output

        # Set up processor
        mock_inputs = MagicMock()
        mock_inputs.to.return_value = mock_inputs
        mock_transformers['processor'].return_value = mock_inputs

        # Initialize segmenter once
        segmenter = SAM3Segmenter()

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Segment multiple concepts (typical workflow)
        concepts = ["wall", "floor", "ceiling", "window", "door"]
        results = {}

        for concept in concepts:
            masks, metadata = segmenter.segment(test_image, concept)
            results[concept] = (masks, metadata)

        # Verify all concepts were segmented
        assert len(results) == 5
        for concept in concepts:
            assert concept in results
            masks, metadata = results[concept]
            assert metadata['concept'] == concept

    def test_facebook_sam3_model_path(self, mock_env, mock_torch, mock_transformers):
        """Test segmenter uses correct HuggingFace model path"""
        segmenter = SAM3Segmenter()

        # Verify both processor and model loaded from facebook/sam3
        processor_call = mock_transformers['processor_class'].from_pretrained.call_args
        model_call = mock_transformers['model_class'].from_pretrained.call_args

        assert processor_call[0][0] == "facebook/sam3"
        assert model_call[0][0] == "facebook/sam3"


class TestSAM3SegmenterEdgeCases:
    """Test edge cases and boundary conditions"""

    def test_segment_with_grayscale_image(self, mock_env, mock_torch, mock_transformers):
        """Test segment() handles grayscale images"""
        segmenter = SAM3Segmenter()

        # Set up mock output
        mock_output = MagicMock()
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        mock_transformers['model'].return_value = mock_output

        mock_inputs = MagicMock()
        mock_inputs.to.return_value = mock_inputs
        mock_transformers['processor'].return_value = mock_inputs

        from PIL import Image
        # Create grayscale image
        test_image = Image.new('L', (512, 512))

        # Should handle grayscale images (processor will handle conversion)
        masks, metadata = segmenter.segment(test_image, "wall")

        assert isinstance(masks, np.ndarray)
        assert isinstance(metadata, dict)

    def test_segment_with_very_long_concept_text(self, mock_env, mock_torch, mock_transformers):
        """Test segment() handles long concept descriptions"""
        segmenter = SAM3Segmenter()

        # Set up mock output
        mock_output = MagicMock()
        mock_pred_masks = MagicMock()
        mock_pred_masks.cpu().numpy.return_value = np.ones((1, 256, 256))
        mock_output.pred_masks = mock_pred_masks

        mock_iou_scores = MagicMock()
        mock_iou_scores.cpu().numpy().tolist.return_value = [0.95]
        mock_output.iou_scores = mock_iou_scores

        mock_transformers['model'].return_value = mock_output

        mock_inputs = MagicMock()
        mock_inputs.to.return_value = mock_inputs
        mock_transformers['processor'].return_value = mock_inputs

        from PIL import Image
        test_image = Image.new('RGB', (512, 512))

        # Very long concept description
        long_concept = "modern kitchen cabinet with white finish and chrome handles located on the left wall"

        masks, metadata = segmenter.segment(test_image, long_concept)

        assert metadata['concept'] == long_concept
