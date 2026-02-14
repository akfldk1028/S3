"""
Runpod Serverless Adapter

Handler interface for Runpod serverless infrastructure.
Receives jobs from Runpod queue, processes them via pipeline, returns results.

Handler Signature:
    handler(event: dict) -> dict

Event Format:
    event["input"] = GpuQueueMessage from workflow.md section 7:
        {
            "job_id": str,
            "user_id": str,
            "preset": str,
            "concepts": dict,
            "protect": list,
            "items": list,
            "callback_url": str,
            "batch_concurrency": int (optional)
        }

Response Format:
    Success: {"output": results_dict}
    Failure: {"error": error_message}
"""

import logging
import os

# Configure logging
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)


def handler(event: dict) -> dict:
    """
    Runpod serverless handler. Receives job from queue, processes it, returns result.

    Args:
        event: Runpod event dict containing:
            - input: Job specification (GpuQueueMessage)

    Returns:
        dict: On success: {"output": results_dict}
              On failure: {"error": error_message}

    Example:
        >>> event = {
        ...     "input": {
        ...         "job_id": "job_123",
        ...         "user_id": "u_abc",
        ...         "preset": "interior",
        ...         "concepts": {"Floor": {"action": "recolor", "value": "#FF5733"}},
        ...         "items": [...],
        ...         "callback_url": "https://api.example.com/jobs/job_123/callback"
        ...     }
        ... }
        >>> result = handler(event)
        >>> print(result)
        {'output': {'total_items': 1, 'successful_items': 1, 'failed_items': 0, 'errors': []}}
    """
    try:
        # Extract job input from event
        job_input = event.get("input")

        if not job_input:
            raise ValueError("Missing 'input' field in event")

        job_id = job_input.get("job_id", "unknown")
        logger.info(f"Runpod handler received job: {job_id}")

        # Import and call pipeline
        from engine.pipeline import process_job

        results = process_job(job_input)

        logger.info(f"Job {job_id} completed: {results}")

        # Return success response
        return {"output": results}

    except Exception as e:
        error_msg = str(e)
        logger.error(f"Job processing failed: {error_msg}", exc_info=True)

        # Return error response
        return {"error": error_msg}


def start():
    """
    Start Runpod serverless worker.

    Initializes the Runpod serverless event loop with the handler function.
    This function blocks and runs until the worker is terminated.

    Example:
        >>> if __name__ == "__main__":
        ...     start()
    """
    import runpod

    logger.info("Starting Runpod serverless worker...")
    runpod.serverless.start({"handler": handler})
