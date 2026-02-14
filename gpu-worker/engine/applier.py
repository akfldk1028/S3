"""
Applier — Rule Apply (recolor, tone, texture)

Implements rule application for image transformations:
- recolor: Apply color to masked regions
- tone: Adjust tonal values (v2 feature)
- texture: Apply texture patterns (v2 feature)

Protected mask areas are preserved from the original image.
"""

import numpy as np
from PIL import Image


def apply_rules(image, masks: dict, concepts: dict, protect_mask=None):
    """
    Apply rules to image using masks. Returns processed image.

    Args:
        image: PIL Image to process
        masks: Dict mapping concept names to mask arrays or lists of mask arrays
               Each mask is a numpy array of shape (H, W) with values 0-255 or 0-1
        concepts: Dict mapping concept names to rule definitions
                  Example: {"Floor": {"action": "recolor", "value": "#FF5733"}}
        protect_mask: Optional numpy array (H, W) marking protected regions
                     Protected pixels will not be modified

    Returns:
        PIL Image: Processed image with rules applied

    Raises:
        ValueError: If image is not a PIL Image or invalid rule format

    Example:
        >>> masks = {"Floor": np.array([[0, 0], [255, 255]])}
        >>> concepts = {"Floor": {"action": "recolor", "value": "#FF5733"}}
        >>> result = apply_rules(image, masks, concepts)
    """
    if not isinstance(image, Image.Image):
        raise ValueError("image must be a PIL Image")

    # Convert image to numpy array for processing (RGB)
    img_array = np.array(image.convert("RGB"), dtype=np.float32)
    height, width = img_array.shape[:2]

    # Create a copy to modify
    result_array = img_array.copy()

    # Process each concept with its rule
    for concept_name, rule in concepts.items():
        # Skip if concept not in masks
        if concept_name not in masks:
            continue

        # Get action and value from rule
        action = rule.get("action")
        value = rule.get("value")

        if not action or not value:
            continue

        # Get masks for this concept (may be single mask or list of instance masks)
        concept_masks = masks[concept_name]

        # Normalize to list of masks
        if isinstance(concept_masks, np.ndarray):
            # Single mask - check if it's a list of instance masks or single mask
            if concept_masks.ndim == 3:
                # Shape: [num_instances, H, W]
                mask_list = [concept_masks[i] for i in range(concept_masks.shape[0])]
            else:
                # Shape: [H, W]
                mask_list = [concept_masks]
        elif isinstance(concept_masks, list):
            mask_list = concept_masks
        else:
            continue

        # Apply rule based on action type
        if action == "recolor":
            # Parse color value (hex string like "#FF5733" or color name)
            color_rgb = _parse_color(value)
            if color_rgb is None:
                continue

            # Apply color to each instance mask
            for mask in mask_list:
                # Normalize mask to 0-1 range
                mask_normalized = _normalize_mask(mask, height, width)
                if mask_normalized is None:
                    continue

                # Apply protect mask if provided
                if protect_mask is not None:
                    protect_normalized = _normalize_mask(protect_mask, height, width)
                    if protect_normalized is not None:
                        # Exclude protected regions from the mask
                        mask_normalized = mask_normalized * (1 - protect_normalized)

                # Apply recolor: blend original with target color based on mask
                # mask_normalized shape: (H, W), need to expand to (H, W, 3)
                mask_3d = np.expand_dims(mask_normalized, axis=2)

                # Apply color to masked region
                # result = original * (1 - mask) + color * mask
                result_array = result_array * (1 - mask_3d) + np.array(color_rgb) * mask_3d

        # TODO: Implement tone and texture actions (v2 features)
        # elif action == "tone":
        #     pass
        # elif action == "texture":
        #     pass

    # Convert back to uint8 and PIL Image
    result_array = np.clip(result_array, 0, 255).astype(np.uint8)
    result_image = Image.fromarray(result_array, mode="RGB")

    return result_image


def _parse_color(value: str) -> tuple:
    """
    Parse color value to RGB tuple.

    Args:
        value: Color string - hex format "#RRGGBB" or color name

    Returns:
        tuple: (R, G, B) values in 0-255 range, or None if invalid
    """
    if not value:
        return None

    # Handle hex color format
    if value.startswith("#"):
        try:
            # Remove # and parse hex
            hex_color = value.lstrip("#")
            if len(hex_color) == 6:
                r = int(hex_color[0:2], 16)
                g = int(hex_color[2:4], 16)
                b = int(hex_color[4:6], 16)
                return (r, g, b)
        except ValueError:
            return None

    # Handle named colors or material references (e.g., "oak_a")
    # For MVP, treat material names as placeholder - could map to actual colors in v2
    # For now, use a default color for non-hex values
    return (128, 128, 128)  # Default gray


def _normalize_mask(mask, target_height: int, target_width: int):
    """
    Normalize mask to 0-1 range with correct dimensions.

    Args:
        mask: Numpy array with mask values
        target_height: Expected height
        target_width: Expected width

    Returns:
        Normalized mask array of shape (H, W) with values 0-1, or None if invalid
    """
    if mask is None or not isinstance(mask, np.ndarray):
        return None

    # Ensure mask is 2D
    if mask.ndim != 2:
        return None

    # Resize if needed (though in practice masks should match image size)
    if mask.shape[0] != target_height or mask.shape[1] != target_width:
        # For now, skip mismatched masks - in production would resize
        return None

    # Normalize to 0-1 range
    if mask.max() > 1.0:
        # Assume 0-255 range
        return mask.astype(np.float32) / 255.0
    else:
        # Already in 0-1 range
        return mask.astype(np.float32)
