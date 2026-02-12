"""
쇼핑/셀러 프리셋 — SAM3 concept → 프롬프트 매핑

TODO: Auto-Claude 구현
"""

SELLER_CONCEPTS = {
    "Body": {"prompt": "product body", "multi_instance": False},
    "Label_Text": {"prompt": "product label text", "multi_instance": False},
    "Logo": {"prompt": "brand logo", "multi_instance": True},
    "Gloss": {"prompt": "glossy highlight reflection", "multi_instance": False},
    "Parts": {"prompt": "product parts and components", "multi_instance": True},
    "Accessories": {"prompt": "product accessories cable box manual", "multi_instance": True},
}

PROTECT_DEFAULTS = ["Label_Text", "Logo", "Gloss"]
