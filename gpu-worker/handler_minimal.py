import runpod

def handler(job):
    return {"status": "ok", "input_received": job["input"]}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
