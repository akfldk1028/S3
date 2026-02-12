"""Pytest fixtures for cf-backend tests."""

import os

import pytest
from fastapi.testclient import TestClient

# 테스트용 환경변수 설정 (app import 전에 설정해야 함)
os.environ.setdefault("API_SECRET_KEY", "test-secret-key")

from src.main import app


@pytest.fixture
def client():
    """FastAPI test client."""
    return TestClient(app)


@pytest.fixture
def auth_headers():
    """Backend API 인증 헤더 (X-API-Key)."""
    return {"X-API-Key": "test-secret-key"}


# TODO: SAM3 mock predictor fixture
# @pytest.fixture
# def mock_predictor():
#     ...

# TODO: R2 mock storage fixture
# @pytest.fixture
# def mock_storage():
#     ...
