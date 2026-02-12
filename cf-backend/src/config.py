"""Application configuration via environment variables."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """S3 Backend settings. Loaded from .env file or environment."""

    # SAM3 Model
    sam3_weights_path: str = "/app/weights/sam3.pt"
    sam3_device: str = "cuda"

    # HuggingFace
    hf_token: str = ""

    # Cloudflare R2 (S3-compatible)
    r2_endpoint: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket: str = "s3-images"

    # Supabase
    supabase_url: str = ""
    supabase_service_key: str = ""

    # Security
    api_secret_key: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
