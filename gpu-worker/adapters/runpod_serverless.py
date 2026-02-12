"""
Runpod Serverless Adapter — MVP

TODO: Auto-Claude 구현
- runpod.serverless.start({"handler": handler})
- handler(event) → engine.pipeline.process_job(event["input"])
- event["input"] = GpuQueueMessage (workflow.md 섹션 7)
"""


def handler(event: dict) -> dict:
    """Runpod serverless handler. Receives job, returns result."""
    from engine.pipeline import process_job
    return process_job(event["input"])


def start():
    """Start Runpod serverless worker."""
    import runpod
    runpod.serverless.start({"handler": handler})
