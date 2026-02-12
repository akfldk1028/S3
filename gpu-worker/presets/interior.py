"""
건축/인테리어 프리셋 — SAM3 concept → 프롬프트 매핑

TODO: Auto-Claude 구현
- 각 concept에 대한 SAM3 텍스트 프롬프트
- 인스턴스 분리가 필요한 concept 표시
- 보호 기본값
"""

INTERIOR_CONCEPTS = {
    "Wall": {"prompt": "wall surface", "multi_instance": False},
    "Floor": {"prompt": "floor surface", "multi_instance": False},
    "Ceiling": {"prompt": "ceiling", "multi_instance": False},
    "Window": {"prompt": "window", "multi_instance": True},
    "Door": {"prompt": "door", "multi_instance": True},
    "Frame_Molding": {"prompt": "frame and molding trim", "multi_instance": False},
    "Tile": {"prompt": "tile", "multi_instance": True},
    "Grout": {"prompt": "grout lines between tiles", "multi_instance": False},
    "Cabinet": {"prompt": "cabinet door", "multi_instance": True},
    "Countertop": {"prompt": "countertop surface", "multi_instance": False},
    "Light": {"prompt": "light fixture", "multi_instance": True},
    "Handle": {"prompt": "door handle or knob", "multi_instance": True},
}

PROTECT_DEFAULTS = ["Grout", "Frame_Molding", "Glass_highlight"]
