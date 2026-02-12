"""Tests for segmentation endpoints (SAM3 추론 전용)."""


def test_health_check(client):
    """GET /health returns ok status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


def test_model_info(client, auth_headers):
    """GET /api/v1/model/info returns model metadata."""
    response = client.get("/api/v1/model/info", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["model_name"] == "SAM3"
    assert data["parameters"] == 848_000_000


def test_predict_requires_auth(client):
    """POST /api/v1/predict without API key returns 401."""
    response = client.post("/api/v1/predict", json={
        "image_url": "https://example.com/image.png",
        "text_prompt": "cat",
        "user_id": "test-user",
        "task_id": "test-task",
    })
    assert response.status_code == 401


# TODO: predict 엔드포인트 테스트 (mock predictor 필요)
# def test_predict(client, auth_headers, mock_predictor):
#     response = client.post("/api/v1/predict", json={...}, headers=auth_headers)
#     assert response.status_code == 200
