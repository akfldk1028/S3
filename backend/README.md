# S3 Backend - API Gateway + Service Agents

## Role in S3 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  API GATEWAY + SERVICE AGENTS                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ┌─────────────────────┐                     │
│                    │    API GATEWAY      │                     │
│                    │   (FastAPI Router)  │                     │
│                    └──────────┬──────────┘                     │
│                               │                                 │
│         ┌─────────────────────┼─────────────────────┐          │
│         │                     │                     │          │
│         ▼                     ▼                     ▼          │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐  │
│  │    AUTH     │       │    DATA     │       │  NOTIFIER   │  │
│  │   AGENT     │       │   AGENT     │       │   AGENT     │  │
│  │             │       │             │       │             │  │
│  │ - JWT       │       │ - CRUD      │       │ - Push      │  │
│  │ - OAuth     │       │ - Query     │       │ - Email     │  │
│  │ - Session   │       │ - Cache     │       │ - SMS       │  │
│  └──────┬──────┘       └──────┬──────┘       └──────┬──────┘  │
│         │                     │                     │          │
│         └─────────────────────┼─────────────────────┘          │
│                               │                                 │
│                    ┌──────────▼──────────┐                     │
│                    │   ORCHESTRATOR      │                     │
│                    │   (Agent Router)    │                     │
│                    └──────────┬──────────┘                     │
│                               │                                 │
│         ┌─────────────────────┼─────────────────────┐          │
│         │                     │                     │          │
│         ▼                     ▼                     ▼          │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐  │
│  │  DATABASE   │       │    CACHE    │       │  EXTERNAL   │  │
│  │  (Postgres) │       │   (Redis)   │       │   SERVICES  │  │
│  └─────────────┘       └─────────────┘       └─────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Agent-Oriented Directory Structure

```
backend/
├── main.py                       # FastAPI 앱 진입점
├── requirements.txt              # Python 의존성
│
├── agents/                       # SERVICE AGENTS
│   ├── __init__.py
│   ├── base.py                   # 에이전트 베이스 클래스
│   │
│   ├── auth/                     # AUTH AGENT
│   │   ├── __init__.py
│   │   ├── handler.py            # 인증 로직
│   │   ├── jwt_manager.py        # JWT 토큰 관리
│   │   ├── oauth_provider.py     # OAuth 연동
│   │   └── session_store.py      # 세션 저장소
│   │
│   ├── data/                     # DATA AGENT
│   │   ├── __init__.py
│   │   ├── handler.py            # CRUD 로직
│   │   ├── query_builder.py      # 쿼리 빌더
│   │   └── cache_manager.py      # 캐시 관리
│   │
│   ├── notification/             # NOTIFICATION AGENT
│   │   ├── __init__.py
│   │   ├── handler.py            # 알림 로직
│   │   ├── push_service.py       # 푸시 알림
│   │   ├── email_service.py      # 이메일
│   │   └── sms_service.py        # SMS
│   │
│   └── orchestrator/             # AGENT ORCHESTRATOR
│       ├── __init__.py
│       ├── router.py             # 에이전트 라우팅
│       ├── queue.py              # 태스크 큐
│       └── scheduler.py          # 스케줄러
│
├── api/                          # API ENDPOINTS
│   ├── __init__.py
│   ├── v1/
│   │   ├── __init__.py
│   │   ├── auth.py               # /api/v1/auth/*
│   │   ├── users.py              # /api/v1/users/*
│   │   └── notifications.py      # /api/v1/notifications/*
│   └── deps.py                   # 의존성 주입
│
├── models/                       # DATA MODELS
│   ├── __init__.py
│   ├── user.py                   # User 모델
│   ├── session.py                # Session 모델
│   └── base.py                   # SQLAlchemy Base
│
├── schemas/                      # PYDANTIC SCHEMAS
│   ├── __init__.py
│   ├── user.py                   # User DTO
│   ├── auth.py                   # Auth DTO
│   └── response.py               # Response DTO
│
├── db/                           # DATABASE
│   ├── __init__.py
│   ├── database.py               # DB 연결
│   ├── migrations/               # Alembic 마이그레이션
│   └── seed.py                   # 시드 데이터
│
├── core/                         # CORE UTILITIES
│   ├── __init__.py
│   ├── config.py                 # 환경설정
│   ├── security.py               # 보안 유틸
│   └── exceptions.py             # 커스텀 예외
│
└── tests/                        # TESTS
    ├── __init__.py
    ├── conftest.py               # pytest fixtures
    ├── test_auth.py
    └── test_data.py
```

## Agent Communication Protocol

```
┌─────────────────────────────────────────────────────────────────┐
│                   AGENT MESSAGE FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  HTTP Request: POST /api/v1/auth/login                         │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                           │
│  │   API Gateway   │  → Validate request schema                │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │  Orchestrator   │  → Route to Auth Agent                    │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │   Auth Agent    │  → Process authentication                 │
│  │                 │                                           │
│  │  1. Validate    │                                           │
│  │  2. Query DB    │  ←→ Data Agent                           │
│  │  3. Create JWT  │                                           │
│  │  4. Store Sess  │  ←→ Cache (Redis)                        │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Notifier Agent  │  → Send login notification (optional)    │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  HTTP Response: { token, user, expires_at }                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

```powershell
cd C:\DK\S3\S3\backend

# 가상환경 생성
python -m venv .venv
.\.venv\Scripts\Activate

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn main:app --reload --port 8000
```

## Environment Configuration

```bash
# .env
DATABASE_URL=postgresql://user:pass@localhost:5432/s3
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=30

# Optional: AI Agent Integration
AI_AGENT_URL=http://localhost:8001
CLAUDE_API_KEY=your-api-key
```

## Auto-Claude Integration

이 모듈은 Auto-Claude의 Agent Terminal에서 개발됩니다:

```
Auto-Claude Kanban:
├── [Task] Setup FastAPI project structure
├── [Task] Implement Auth Agent
├── [Task] Implement Data Agent
├── [Task] Implement Notification Agent
├── [Task] Setup PostgreSQL + Redis
└── [Task] API integration tests

Agent Terminal:
> cd C:\DK\S3\S3\backend
> uvicorn main:app --reload
> (Coder Agent implements subtasks)
```

## Recommended Packages

```txt
# requirements.txt
fastapi>=0.115.0
uvicorn[standard]>=0.34.0
sqlalchemy>=2.0.0
alembic>=1.14.0
asyncpg>=0.30.0
pydantic>=2.10.0
pydantic-settings>=2.7.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
redis>=5.2.0
httpx>=0.28.0
python-multipart>=0.0.20

# Testing
pytest>=8.3.0
pytest-asyncio>=0.25.0
httpx>=0.28.0

# AI Integration (optional)
claude-agent-sdk>=0.1.25
```

## API Endpoints

| Method | Endpoint | Agent | Description |
|--------|----------|-------|-------------|
| POST | `/api/v1/auth/login` | Auth | 로그인 |
| POST | `/api/v1/auth/register` | Auth | 회원가입 |
| POST | `/api/v1/auth/refresh` | Auth | 토큰 갱신 |
| GET | `/api/v1/users/me` | Data | 내 정보 |
| PUT | `/api/v1/users/me` | Data | 정보 수정 |
| POST | `/api/v1/notifications/send` | Notifier | 알림 전송 |

## Agent Base Class

```python
# agents/base.py
from abc import ABC, abstractmethod
from typing import Any, Dict

class BaseAgent(ABC):
    """모든 서비스 에이전트의 베이스 클래스"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.name = self.__class__.__name__

    @abstractmethod
    async def process(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """에이전트 메시지 처리"""
        pass

    async def send_to_agent(self, agent_name: str, message: Dict) -> Dict:
        """다른 에이전트에 메시지 전송"""
        from agents.orchestrator import router
        return await router.route(agent_name, message)
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | FastAPI |
| ORM | SQLAlchemy 2.0 |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Auth | JWT (python-jose) |
| Validation | Pydantic 2 |
| Testing | pytest-asyncio |
