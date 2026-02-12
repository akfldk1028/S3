"""S3 Backend — SAM3 GPU Inference Server.

SAM3 추론 전용 서버. API 로직(CRUD, Auth, R2 업로드)은 Edge에서 처리.
이 서버는 Edge에서만 호출 가능한 Internal API.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from src.config import settings
from src.core.middleware import setup_middleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: load model on startup, cleanup on shutdown."""
    # TODO: SAM3 모델 로드
    # from src.sam3.predictor import SAM3Predictor
    # from src.sam3.config import SAM3Config
    # predictor = SAM3Predictor(SAM3Config.from_settings(settings))
    # await predictor.load()
    # app.state.predictor = predictor
    yield
    # TODO: cleanup


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="S3 Backend — SAM3 GPU Inference Server",
        description="SAM3 추론 전용 Internal API. Edge(Cloudflare Workers)에서만 호출.",
        version="0.1.0",
        lifespan=lifespan,
    )

    setup_middleware(app)

    # Segmentation router (유일한 도메인)
    from src.segmentation.router import router as segmentation_router

    app.include_router(segmentation_router)

    # Health (no prefix, no auth)
    @app.get("/health")
    async def health():
        return {
            "status": "ok",
            "model_loaded": False,  # TODO: app.state.predictor.is_loaded
            "gpu_available": False,  # TODO: torch.cuda.is_available()
            "gpu_name": None,
            "vram_used_mb": None,
            "vram_total_mb": None,
        }

    return app


app = create_app()
