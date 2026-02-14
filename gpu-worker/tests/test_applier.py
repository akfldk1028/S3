"""
Unit tests for Rule Applier with fixture images and masks

Tests verify:
- apply_rules() applies recolor operation correctly
- Recolor changes pixel values in masked regions
- Protected mask preserves original pixels
- Output is PIL Image with correct format
- Multi-instance mask handling
- Edge cases (missing concepts, invalid colors, dimension mismatches)
"""

import os
import pytest
import numpy as np
from PIL import Image
import sys

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from engine.applier import apply_rules, _parse_color, _normalize_mask


@pytest.fixture
def test_image():
    """Create a test image for rule application"""
    # Create a simple 100x100 RGB image with red color
    img_array = np.zeros((100, 100, 3), dtype=np.uint8)
    img_array[:, :] = [255, 0, 0]  # Red
    return Image.fromarray(img_array, mode='RGB')


@pytest.fixture
def simple_mask():
    """Create a simple binary mask (50x50 region in top-left)"""
    mask = np.zeros((100, 100), dtype=np.uint8)
    mask[0:50, 0:50] = 255  # Top-left quadrant
    return mask


@pytest.fixture
def multi_instance_masks():
    """Create multiple instance masks for testing"""
    # Instance 1: Top-left quadrant
    mask1 = np.zeros((100, 100), dtype=np.uint8)
    mask1[0:50, 0:50] = 255

    # Instance 2: Bottom-right quadrant
    mask2 = np.zeros((100, 100), dtype=np.uint8)
    mask2[50:100, 50:100] = 255

    # Return as 3D array [num_instances, H, W]
    return np.stack([mask1, mask2])


@pytest.fixture
def protect_mask():
    """Create a protection mask (25x25 region in top-left corner)"""
    mask = np.zeros((100, 100), dtype=np.uint8)
    mask[0:25, 0:25] = 255  # Small protected region
    return mask


class TestApplyRulesRecolor:
    """Test apply_rules() with recolor operation"""

    def test_recolor_changes_masked_pixels(self, test_image, simple_mask):
        """Test that recolor operation changes pixel values in masked region"""
        # Original image is red [255, 0, 0]
        # Apply blue color to masked region
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#0000FF"}}  # Blue

        result = apply_rules(test_image, masks, concepts)

        # Convert to numpy to check pixel values
        result_array = np.array(result)

        # Check masked region (top-left 50x50) is now blue
        masked_pixel = result_array[25, 25]  # Center of masked region
        assert masked_pixel[2] > 200  # Blue channel should be high
        assert masked_pixel[0] < 50   # Red channel should be low

    def test_recolor_preserves_unmasked_pixels(self, test_image, simple_mask):
        """Test that recolor preserves pixels outside masked region"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#0000FF"}}

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Check unmasked region (bottom-right) is still red
        unmasked_pixel = result_array[75, 75]
        assert unmasked_pixel[0] > 200  # Red channel preserved
        assert unmasked_pixel[2] < 50   # Blue channel low

    def test_recolor_with_protect_mask(self, test_image, simple_mask, protect_mask):
        """Test that protect_mask prevents changes in protected regions"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#00FF00"}}  # Green

        result = apply_rules(test_image, masks, concepts, protect_mask=protect_mask)
        result_array = np.array(result)

        # Check protected region (top-left 25x25) is still red
        protected_pixel = result_array[10, 10]
        assert protected_pixel[0] > 200  # Red preserved
        assert protected_pixel[1] < 50   # Green not applied

        # Check non-protected but masked region has green applied
        masked_not_protected = result_array[40, 40]
        assert masked_not_protected[1] > 200  # Green applied
        assert masked_not_protected[0] < 50   # Red reduced

    def test_recolor_returns_pil_image(self, test_image, simple_mask):
        """Test that apply_rules returns a PIL Image object"""
        masks = {"Wall": simple_mask}
        concepts = {"Wall": {"action": "recolor", "value": "#FF5733"}}

        result = apply_rules(test_image, masks, concepts)

        assert isinstance(result, Image.Image)
        assert result.mode == "RGB"
        assert result.size == test_image.size

    def test_recolor_hex_color_parsing(self, test_image, simple_mask):
        """Test that hex colors are parsed correctly"""
        # Test specific color: #FF5733 (orange-red)
        masks = {"Wall": simple_mask}
        concepts = {"Wall": {"action": "recolor", "value": "#FF5733"}}

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Check masked region has approximately the target color
        masked_pixel = result_array[25, 25]
        assert 200 <= masked_pixel[0] <= 255  # Red ~255
        assert 50 <= masked_pixel[1] <= 100   # Green ~87
        assert 40 <= masked_pixel[2] <= 60    # Blue ~51


class TestApplyRulesMultiInstance:
    """Test apply_rules() with multi-instance masks"""

    def test_multi_instance_masks_3d_array(self, test_image, multi_instance_masks):
        """Test that 3D mask arrays [num_instances, H, W] are handled correctly"""
        masks = {"Window": multi_instance_masks}
        concepts = {"Window": {"action": "recolor", "value": "#FFFF00"}}  # Yellow

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Both instances should have yellow applied
        # Instance 1: top-left
        pixel1 = result_array[25, 25]
        assert pixel1[0] > 200  # Red channel high
        assert pixel1[1] > 200  # Green channel high

        # Instance 2: bottom-right
        pixel2 = result_array[75, 75]
        assert pixel2[0] > 200
        assert pixel2[1] > 200

    def test_multi_instance_masks_list(self, test_image):
        """Test that list of mask arrays is handled correctly"""
        # Create two separate masks as a list
        mask1 = np.zeros((100, 100), dtype=np.uint8)
        mask1[0:50, 0:50] = 255

        mask2 = np.zeros((100, 100), dtype=np.uint8)
        mask2[50:100, 50:100] = 255

        masks = {"Door": [mask1, mask2]}
        concepts = {"Door": {"action": "recolor", "value": "#00FFFF"}}  # Cyan

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Both mask regions should have cyan applied
        pixel1 = result_array[25, 25]
        pixel2 = result_array[75, 75]

        assert pixel1[1] > 200  # Green high
        assert pixel1[2] > 200  # Blue high
        assert pixel2[1] > 200
        assert pixel2[2] > 200


class TestApplyRulesEdgeCases:
    """Test edge cases and error handling"""

    def test_concept_not_in_masks(self, test_image, simple_mask):
        """Test that rule is skipped if concept not in masks"""
        masks = {"Floor": simple_mask}
        concepts = {"Wall": {"action": "recolor", "value": "#FF0000"}}  # Wall != Floor

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Image should remain unchanged (red)
        pixel = result_array[25, 25]
        assert pixel[0] > 200  # Still red

    def test_missing_action_in_rule(self, test_image, simple_mask):
        """Test that rule without 'action' field is skipped"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"value": "#FF0000"}}  # Missing 'action'

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Image should remain unchanged
        pixel = result_array[25, 25]
        assert pixel[0] > 200  # Still red

    def test_missing_value_in_rule(self, test_image, simple_mask):
        """Test that rule without 'value' field is skipped"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor"}}  # Missing 'value'

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Image should remain unchanged
        pixel = result_array[25, 25]
        assert pixel[0] > 200  # Still red

    def test_invalid_image_type(self, simple_mask):
        """Test that ValueError is raised for non-PIL image"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#FF0000"}}

        with pytest.raises(ValueError) as exc_info:
            apply_rules("not an image", masks, concepts)

        assert "must be a PIL Image" in str(exc_info.value)

    def test_invalid_hex_color(self, test_image, simple_mask):
        """Test that invalid hex color is handled gracefully"""
        masks = {"Floor": simple_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#GGGGGG"}}  # Invalid hex

        # Should not raise exception, but should skip or use default
        result = apply_rules(test_image, masks, concepts)
        assert isinstance(result, Image.Image)

    def test_empty_masks_dict(self, test_image):
        """Test that empty masks dictionary returns original image"""
        masks = {}
        concepts = {"Floor": {"action": "recolor", "value": "#FF0000"}}

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Image should remain unchanged
        pixel = result_array[50, 50]
        assert pixel[0] > 200  # Still red

    def test_empty_concepts_dict(self, test_image, simple_mask):
        """Test that empty concepts dictionary returns original image"""
        masks = {"Floor": simple_mask}
        concepts = {}

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Image should remain unchanged
        pixel = result_array[25, 25]
        assert pixel[0] > 200  # Still red

    def test_dimension_mismatch_mask(self, test_image):
        """Test that mismatched mask dimensions are handled"""
        # Create mask with wrong dimensions
        wrong_size_mask = np.ones((50, 50), dtype=np.uint8) * 255

        masks = {"Floor": wrong_size_mask}
        concepts = {"Floor": {"action": "recolor", "value": "#0000FF"}}

        # Should not crash, but mask should be skipped
        result = apply_rules(test_image, masks, concepts)
        assert isinstance(result, Image.Image)


class TestApplyRulesMultipleConcepts:
    """Test apply_rules() with multiple concepts"""

    def test_multiple_concepts_applied_sequentially(self, test_image):
        """Test that multiple concepts are applied in order"""
        # Create non-overlapping masks
        mask1 = np.zeros((100, 100), dtype=np.uint8)
        mask1[0:50, 0:50] = 255  # Top-left

        mask2 = np.zeros((100, 100), dtype=np.uint8)
        mask2[50:100, 50:100] = 255  # Bottom-right

        masks = {
            "Floor": mask1,
            "Wall": mask2
        }
        concepts = {
            "Floor": {"action": "recolor", "value": "#00FF00"},  # Green
            "Wall": {"action": "recolor", "value": "#0000FF"}    # Blue
        }

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Floor region should be green
        floor_pixel = result_array[25, 25]
        assert floor_pixel[1] > 200  # Green high

        # Wall region should be blue
        wall_pixel = result_array[75, 75]
        assert wall_pixel[2] > 200  # Blue high

    def test_overlapping_concepts_last_wins(self, test_image, simple_mask):
        """Test that overlapping concepts apply in order (last wins)"""
        masks = {
            "Floor": simple_mask,
            "Wall": simple_mask  # Same mask
        }
        concepts = {
            "Floor": {"action": "recolor", "value": "#FF0000"},  # Red first
            "Wall": {"action": "recolor", "value": "#0000FF"}    # Blue second (wins)
        }

        result = apply_rules(test_image, masks, concepts)
        result_array = np.array(result)

        # Should be blue (second application)
        pixel = result_array[25, 25]
        assert pixel[2] > 200  # Blue channel high
        assert pixel[0] < 50   # Red channel low


class TestParseColor:
    """Test _parse_color() helper function"""

    def test_parse_hex_color_6_digits(self):
        """Test parsing 6-digit hex color"""
        result = _parse_color("#FF5733")
        assert result == (255, 87, 51)

    def test_parse_hex_color_uppercase(self):
        """Test parsing uppercase hex color"""
        result = _parse_color("#AABBCC")
        assert result == (170, 187, 204)

    def test_parse_hex_color_lowercase(self):
        """Test parsing lowercase hex color"""
        result = _parse_color("#aabbcc")
        assert result == (170, 187, 204)

    def test_parse_hex_color_black(self):
        """Test parsing black color"""
        result = _parse_color("#000000")
        assert result == (0, 0, 0)

    def test_parse_hex_color_white(self):
        """Test parsing white color"""
        result = _parse_color("#FFFFFF")
        assert result == (255, 255, 255)

    def test_parse_invalid_hex_returns_default(self):
        """Test that invalid hex returns None"""
        result = _parse_color("#GGGGGG")
        assert result is None

    def test_parse_short_hex_returns_default_gray(self):
        """Test that 3-digit hex returns default gray (treated as named color)"""
        result = _parse_color("#ABC")
        # 3-digit hex doesn't match 6-digit pattern, so it's treated as named color
        assert result == (128, 128, 128)

    def test_parse_named_color_returns_default_gray(self):
        """Test that named colors return default gray (placeholder for v2)"""
        result = _parse_color("oak_a")
        assert result == (128, 128, 128)

    def test_parse_empty_string_returns_none(self):
        """Test that empty string returns None"""
        result = _parse_color("")
        assert result is None

    def test_parse_none_returns_none(self):
        """Test that None returns None"""
        result = _parse_color(None)
        assert result is None


class TestNormalizeMask:
    """Test _normalize_mask() helper function"""

    def test_normalize_255_range_mask(self):
        """Test normalizing mask with 0-255 range"""
        mask = np.array([[0, 128, 255]], dtype=np.uint8)
        result = _normalize_mask(mask, 1, 3)

        assert result is not None
        assert result.dtype == np.float32
        assert np.isclose(result[0, 0], 0.0)
        assert np.isclose(result[0, 1], 128/255, atol=0.01)
        assert np.isclose(result[0, 2], 1.0)

    def test_normalize_01_range_mask(self):
        """Test normalizing mask already in 0-1 range"""
        mask = np.array([[0.0, 0.5, 1.0]], dtype=np.float32)
        result = _normalize_mask(mask, 1, 3)

        assert result is not None
        assert np.isclose(result[0, 0], 0.0)
        assert np.isclose(result[0, 1], 0.5)
        assert np.isclose(result[0, 2], 1.0)

    def test_normalize_dimension_mismatch_returns_none(self):
        """Test that dimension mismatch returns None"""
        mask = np.ones((50, 50), dtype=np.uint8)
        result = _normalize_mask(mask, 100, 100)  # Wrong size

        assert result is None

    def test_normalize_3d_mask_returns_none(self):
        """Test that 3D mask returns None (expecting 2D)"""
        mask = np.ones((10, 10, 3), dtype=np.uint8)
        result = _normalize_mask(mask, 10, 10)

        assert result is None

    def test_normalize_none_returns_none(self):
        """Test that None input returns None"""
        result = _normalize_mask(None, 100, 100)
        assert result is None

    def test_normalize_non_array_returns_none(self):
        """Test that non-ndarray input returns None"""
        result = _normalize_mask([1, 2, 3], 1, 3)
        assert result is None


class TestApplyRulesIntegration:
    """Integration tests for apply_rules()"""

    def test_full_workflow_single_concept(self, test_image, simple_mask):
        """Test complete workflow with single concept"""
        # Simulate typical pipeline: segment → apply rules
        masks = {"Wall": simple_mask}
        concepts = {"Wall": {"action": "recolor", "value": "#FF5733"}}

        result = apply_rules(test_image, masks, concepts)

        # Verify result
        assert isinstance(result, Image.Image)
        assert result.size == (100, 100)
        assert result.mode == "RGB"

        # Verify color applied
        result_array = np.array(result)
        masked_pixel = result_array[25, 25]
        assert masked_pixel[0] > 200  # Red channel high

    def test_full_workflow_multi_concept_with_protect(self, test_image):
        """Test complete workflow with multiple concepts and protection"""
        # Create masks for different regions
        floor_mask = np.zeros((100, 100), dtype=np.uint8)
        floor_mask[50:100, :] = 255  # Bottom half

        wall_mask = np.zeros((100, 100), dtype=np.uint8)
        wall_mask[0:50, :] = 255  # Top half

        # Protect a small region
        protect = np.zeros((100, 100), dtype=np.uint8)
        protect[45:55, 45:55] = 255  # Center band

        masks = {
            "Floor": floor_mask,
            "Wall": wall_mask
        }
        concepts = {
            "Floor": {"action": "recolor", "value": "#8B4513"},  # Brown
            "Wall": {"action": "recolor", "value": "#E0E0E0"}    # Light gray
        }

        result = apply_rules(test_image, masks, concepts, protect_mask=protect)
        result_array = np.array(result)

        # Floor region (not protected) should be brown
        floor_pixel = result_array[75, 50]
        assert floor_pixel[0] > 100  # Has red component

        # Wall region (not protected) should be light gray
        wall_pixel = result_array[25, 50]
        assert 200 < wall_pixel[0] < 255
        assert 200 < wall_pixel[1] < 255
        assert 200 < wall_pixel[2] < 255

        # Protected region should remain original (red)
        protected_pixel = result_array[50, 50]
        assert protected_pixel[0] > 200  # Original red preserved

    def test_zero_instances_concept_graceful(self, test_image):
        """Test that zero-instance concepts don't cause errors"""
        # Empty mask array (zero instances)
        masks = {"NonexistentObject": np.array([])}
        concepts = {"NonexistentObject": {"action": "recolor", "value": "#FF0000"}}

        # Should not crash
        result = apply_rules(test_image, masks, concepts)
        assert isinstance(result, Image.Image)

    def test_grayscale_image_converted_to_rgb(self):
        """Test that grayscale images are converted to RGB"""
        # Create grayscale image
        gray_img = Image.new('L', (100, 100), color=128)

        mask = np.zeros((100, 100), dtype=np.uint8)
        mask[0:50, 0:50] = 255

        masks = {"Floor": mask}
        concepts = {"Floor": {"action": "recolor", "value": "#FF0000"}}

        result = apply_rules(gray_img, masks, concepts)

        # Result should be RGB
        assert result.mode == "RGB"
        assert isinstance(result, Image.Image)
