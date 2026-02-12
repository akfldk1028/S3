"""
S3 GPU Worker — Entry Point

어댑터 선택 + 실행. 환경변수 ADAPTER로 분기:
- "runpod" (기본) → adapters.runpod_serverless
- "queue_pull" → adapters.queue_pull

TODO: Auto-Claude 구현
"""

import os


def main():
    adapter = os.getenv("ADAPTER", "runpod")

    if adapter == "runpod":
        from adapters.runpod_serverless import start
        start()
    elif adapter == "queue_pull":
        from adapters.queue_pull import start
        start()
    else:
        raise ValueError(f"Unknown adapter: {adapter}")


if __name__ == "__main__":
    main()
