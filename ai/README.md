# S3 AI - LLM-Based Agents

## Role in S3 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AI AGENTS (LLM-Based)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ┌─────────────────────┐                     │
│                    │   AGENT GATEWAY     │                     │
│                    │   (Request Router)  │                     │
│                    └──────────┬──────────┘                     │
│                               │                                 │
│         ┌─────────────────────┼─────────────────────┐          │
│         │                     │                     │          │
│         ▼                     ▼                     ▼          │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐  │
│  │  ASSISTANT  │       │  ANALYZER   │       │ RECOMMENDER │  │
│  │   AGENT     │       │   AGENT     │       │   AGENT     │  │
│  │             │       │             │       │             │  │
│  │ - Chat      │       │ - Extract   │       │ - Suggest   │  │
│  │ - Answer    │       │ - Summarize │       │ - Rank      │  │
│  │ - Execute   │       │ - Classify  │       │ - Personalize│ │
│  └──────┬──────┘       └──────┬──────┘       └──────┬──────┘  │
│         │                     │                     │          │
│         └─────────────────────┼─────────────────────┘          │
│                               │                                 │
│                    ┌──────────▼──────────┐                     │
│                    │    LLM PROVIDER     │                     │
│                    │                     │                     │
│                    │  ┌───────────────┐  │                     │
│                    │  │ Claude SDK    │  │                     │
│                    │  │ (Primary)     │  │                     │
│                    │  └───────────────┘  │                     │
│                    │                     │                     │
│                    │  ┌───────────────┐  │                     │
│                    │  │ OpenAI / Local│  │                     │
│                    │  │ (Fallback)    │  │                     │
│                    │  └───────────────┘  │                     │
│                    └─────────────────────┘                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Agent-Oriented Directory Structure

```
ai/
├── main.py                       # AI 서비스 진입점
├── requirements.txt              # Python 의존성
│
├── agents/                       # AI AGENTS
│   ├── __init__.py
│   ├── base.py                   # 에이전트 베이스 클래스
│   │
│   ├── assistant/                # ASSISTANT AGENT
│   │   ├── __init__.py
│   │   ├── agent.py              # 어시스턴트 로직
│   │   ├── tools.py              # 사용 가능한 도구들
│   │   ├── memory.py             # 대화 메모리
│   │   └── executor.py           # 도구 실행기
│   │
│   ├── analyzer/                 # ANALYZER AGENT
│   │   ├── __init__.py
│   │   ├── agent.py              # 분석 로직
│   │   ├── extractors.py         # 데이터 추출
│   │   ├── summarizers.py        # 요약 생성
│   │   └── classifiers.py        # 분류 모델
│   │
│   └── recommender/              # RECOMMENDER AGENT
│       ├── __init__.py
│       ├── agent.py              # 추천 로직
│       ├── rankers.py            # 순위 알고리즘
│       └── personalizer.py       # 개인화
│
├── prompts/                      # PROMPT TEMPLATES
│   ├── __init__.py
│   ├── assistant/
│   │   ├── system.md             # 시스템 프롬프트
│   │   ├── chat.md               # 대화 프롬프트
│   │   └── tool_use.md           # 도구 사용 프롬프트
│   │
│   ├── analyzer/
│   │   ├── extract.md
│   │   ├── summarize.md
│   │   └── classify.md
│   │
│   └── recommender/
│       ├── suggest.md
│       └── personalize.md
│
├── providers/                    # LLM PROVIDERS
│   ├── __init__.py
│   ├── base.py                   # 프로바이더 인터페이스
│   ├── claude.py                 # Claude (Anthropic)
│   ├── openai.py                 # OpenAI GPT
│   └── local.py                  # 로컬 모델 (Ollama)
│
├── core/                         # CORE UTILITIES
│   ├── __init__.py
│   ├── config.py                 # 환경설정
│   ├── context.py                # 컨텍스트 관리
│   └── streaming.py              # 스트리밍 응답
│
├── api/                          # API ENDPOINTS
│   ├── __init__.py
│   ├── chat.py                   # POST /ai/chat
│   ├── analyze.py                # POST /ai/analyze
│   └── recommend.py              # POST /ai/recommend
│
└── tests/
    ├── __init__.py
    ├── test_assistant.py
    ├── test_analyzer.py
    └── test_recommender.py
```

## Agent Communication Protocol

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI AGENT MESSAGE FLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Message: "오늘 날씨 어때? 그리고 뉴스 요약해줘"              │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                           │
│  │  Agent Gateway  │  → Parse intent, route to agents          │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ├────────────────────┐                               │
│           │                    │                                │
│           ▼                    ▼                                │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │ Assistant Agent │  │ Analyzer Agent  │                      │
│  │                 │  │                 │                      │
│  │ Tool: weather() │  │ Task: summarize │                      │
│  │ → Get weather   │  │ → Fetch news    │                      │
│  │ → Format reply  │  │ → Summarize     │                      │
│  └────────┬────────┘  └────────┬────────┘                      │
│           │                    │                                │
│           └────────┬───────────┘                               │
│                    │                                            │
│                    ▼                                            │
│  ┌─────────────────────────────────┐                           │
│  │      Response Aggregator        │                           │
│  │                                 │                           │
│  │  "오늘 서울은 맑음, 15도입니다.   │                           │
│  │   오늘의 주요 뉴스 요약:         │                           │
│  │   1. ...                        │                           │
│  │   2. ..."                       │                           │
│  └─────────────────────────────────┘                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

```powershell
cd C:\DK\S3\S3\ai

# 가상환경 생성
python -m venv .venv
.\.venv\Scripts\Activate

# 의존성 설치
pip install -r requirements.txt

# AI 서비스 실행
uvicorn main:app --reload --port 8001
```

## Environment Configuration

```bash
# .env
# Primary LLM (Claude)
ANTHROPIC_API_KEY=your-anthropic-api-key
CLAUDE_MODEL=claude-sonnet-4-5-20250929

# Fallback LLM (OpenAI)
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-4o

# Local LLM (Ollama)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2

# Memory (Redis for context)
REDIS_URL=redis://localhost:6379/1

# Backend Integration
BACKEND_API_URL=http://localhost:8000/api/v1
```

## Auto-Claude Integration

이 모듈은 Auto-Claude의 Agent Terminal에서 개발됩니다:

```
Auto-Claude Kanban:
├── [Task] Setup AI Agent base structure
├── [Task] Implement Assistant Agent
├── [Task] Implement Analyzer Agent
├── [Task] Implement Recommender Agent
├── [Task] Create prompt templates
├── [Task] Multi-provider LLM support
└── [Task] Streaming response implementation

Agent Terminal:
> cd C:\DK\S3\S3\ai
> uvicorn main:app --reload --port 8001
> (Coder Agent implements subtasks)
```

## Recommended Packages

```txt
# requirements.txt

# Core
fastapi>=0.115.0
uvicorn[standard]>=0.34.0
pydantic>=2.10.0
pydantic-settings>=2.7.0

# LLM Providers
anthropic>=0.43.0
claude-agent-sdk>=0.1.27
openai>=1.60.0
ollama>=0.4.0

# Memory & Context
redis>=5.2.0
tiktoken>=0.8.0           # Token counting

# Tools & Utilities
httpx>=0.28.0             # HTTP client for tools
jinja2>=3.1.0             # Prompt templating

# Testing
pytest>=8.3.0
pytest-asyncio>=0.25.0
```

## Agent Base Class

```python
# agents/base.py
from abc import ABC, abstractmethod
from typing import Any, AsyncIterator
from pydantic import BaseModel

class AgentMessage(BaseModel):
    role: str  # "user" | "assistant" | "system"
    content: str
    metadata: dict = {}

class BaseAIAgent(ABC):
    """모든 AI 에이전트의 베이스 클래스"""

    def __init__(self, provider, prompt_template: str):
        self.provider = provider
        self.prompt_template = prompt_template
        self.name = self.__class__.__name__

    @abstractmethod
    async def process(self, message: str, context: dict) -> str:
        """메시지 처리 (일반 응답)"""
        pass

    @abstractmethod
    async def stream(self, message: str, context: dict) -> AsyncIterator[str]:
        """메시지 처리 (스트리밍 응답)"""
        pass

    def render_prompt(self, **kwargs) -> str:
        """프롬프트 템플릿 렌더링"""
        from jinja2 import Template
        template = Template(self.prompt_template)
        return template.render(**kwargs)
```

## API Endpoints

| Method | Endpoint | Agent | Description |
|--------|----------|-------|-------------|
| POST | `/ai/chat` | Assistant | 대화 응답 |
| POST | `/ai/chat/stream` | Assistant | 스트리밍 대화 |
| POST | `/ai/analyze` | Analyzer | 텍스트 분석 |
| POST | `/ai/summarize` | Analyzer | 요약 생성 |
| POST | `/ai/classify` | Analyzer | 분류 |
| POST | `/ai/recommend` | Recommender | 추천 |

## Assistant Agent Tools

```python
# agents/assistant/tools.py
from typing import Callable, Dict

AVAILABLE_TOOLS: Dict[str, Callable] = {
    "search_web": search_web,       # 웹 검색
    "get_weather": get_weather,     # 날씨 조회
    "execute_code": execute_code,   # 코드 실행
    "query_database": query_db,     # DB 조회
    "send_notification": send_notif, # 알림 전송
}

# Claude SDK Tool Use 연동
async def execute_tool(tool_name: str, args: dict) -> str:
    if tool_name in AVAILABLE_TOOLS:
        return await AVAILABLE_TOOLS[tool_name](**args)
    raise ValueError(f"Unknown tool: {tool_name}")
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | FastAPI |
| Primary LLM | Claude (Anthropic) |
| Fallback LLM | OpenAI GPT-4o |
| Local LLM | Ollama (llama3.2) |
| SDK | Claude Agent SDK |
| Context Store | Redis |
| Prompt Engine | Jinja2 |

## Integration with S3 Modules

```
┌──────────────────────────────────────────────────────────────┐
│                    S3 SYSTEM INTEGRATION                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Frontend (Flutter)                                          │
│       │                                                      │
│       │ HTTP: POST /ai/chat                                  │
│       ▼                                                      │
│  Backend (FastAPI)                                           │
│       │                                                      │
│       │ Internal: POST /ai/analyze                           │
│       ▼                                                      │
│  AI Service (This module)                                    │
│       │                                                      │
│       │ Claude SDK / OpenAI API                              │
│       ▼                                                      │
│  LLM Provider                                                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```
