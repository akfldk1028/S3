"""Download SAM3 model weights from HuggingFace.

Usage:
    python scripts/download_weights.py --output ../cf-backend/weights/

Requires HF_TOKEN environment variable.

TODO: 실제 SAM3 모델 HuggingFace 레포 확정 후 repo_id 업데이트.
"""

import argparse
import os
from pathlib import Path


def download_weights(output_dir: str, repo_id: str = "facebook/sam3") -> None:
    """HuggingFace Hub에서 SAM3 가중치 다운로드.

    Args:
        output_dir: 저장 디렉토리
        repo_id: HuggingFace 모델 레포 ID

    TODO:
    1. huggingface_hub 라이브러리로 다운로드
    2. 가중치 파일 검증 (checksum)
    3. 다운로드 진행률 표시
    """
    # from huggingface_hub import hf_hub_download
    #
    # hf_token = os.environ.get("HF_TOKEN")
    # if not hf_token:
    #     print("Warning: HF_TOKEN not set. Some models may require authentication.")
    #
    # output_path = Path(output_dir)
    # output_path.mkdir(parents=True, exist_ok=True)
    #
    # print(f"Downloading {repo_id} to {output_path}...")
    # hf_hub_download(
    #     repo_id=repo_id,
    #     filename="sam3.pt",
    #     local_dir=str(output_path),
    #     token=hf_token,
    # )
    # print("Download complete!")

    print(f"TODO: Download {repo_id} weights to {output_dir}")
    print("Install: pip install huggingface_hub")
    print("Set HF_TOKEN environment variable if needed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download SAM3 model weights")
    parser.add_argument(
        "--output",
        type=str,
        default="../cf-backend/weights/",
        help="Output directory for weights",
    )
    parser.add_argument(
        "--repo-id",
        type=str,
        default="facebook/sam3",
        help="HuggingFace model repo ID",
    )
    args = parser.parse_args()
    download_weights(args.output, args.repo_id)
