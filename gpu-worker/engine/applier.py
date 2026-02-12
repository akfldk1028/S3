"""
Applier — Rule Apply (recolor, tone, texture)

TODO: Auto-Claude 구현
- apply_rules(image, masks: dict, concepts: dict) → result image
  - concepts 예: {"Floor": {"action": "recolor", "value": "oak_a"}}
  - 보호 마스크 영역은 원본 유지
  - 지원 action: recolor, tone, texture (MVP: recolor만)
"""


def apply_rules(image, masks: dict, concepts: dict, protect_mask=None):
    """Apply rules to image using masks. Returns processed image."""
    # TODO: implement
    raise NotImplementedError
