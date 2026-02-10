"""Convert SAM3 model weights to different formats.

Usage:
    python scripts/convert_model.py --input ../backend/weights/sam3.pt --format fp16

TODO: 실제 SAM3 모델 변환 로직 구현.
"""

import argparse


def convert_model(input_path: str, output_format: str) -> None:
    """모델 가중치 변환.

    Supported formats:
    - fp16: FP32 → FP16 (메모리 절약)
    - onnx: PyTorch → ONNX (추론 최적화)
    - tensorrt: PyTorch → TensorRT (NVIDIA 최적화)

    TODO:
    1. PyTorch 모델 로드
    2. 변환 실행
    3. 변환된 가중치 저장
    """
    # import torch
    #
    # if output_format == "fp16":
    #     model = torch.load(input_path, map_location="cpu")
    #     model = model.half()
    #     output_path = input_path.replace(".pt", "_fp16.pt")
    #     torch.save(model, output_path)
    #     print(f"Saved FP16 model to {output_path}")
    #
    # elif output_format == "onnx":
    #     # torch.onnx.export(...)
    #     pass

    print(f"TODO: Convert {input_path} to {output_format}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert SAM3 model weights")
    parser.add_argument("--input", type=str, required=True, help="Input weights path")
    parser.add_argument(
        "--format",
        type=str,
        choices=["fp16", "onnx", "tensorrt"],
        default="fp16",
        help="Output format",
    )
    args = parser.parse_args()
    convert_model(args.input, args.format)
