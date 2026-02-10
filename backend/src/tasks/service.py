"""Tasks domain — Supabase result update (Backend-only).

Backend는 추론 완료 후 Supabase에 결과를 직접 업데이트한다.
CRUD(create, get, list)는 Edge가 담당.
"""


class TaskService:
    """추론 결과 업데이트 전용 (Backend → Supabase)."""

    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase_url = supabase_url
        self.supabase_key = supabase_key
        # TODO: from supabase import create_client
        # self.client = create_client(supabase_url, supabase_key)

    async def update_status(self, task_id: str, status: str):
        """status 업데이트 (processing → done / error). TODO: UPDATE"""
        raise NotImplementedError

    async def update_result(
        self, task_id: str, mask_url: str, labels: list[str], metadata: dict,
    ):
        """추론 완료 결과 저장 (mask_url, labels, metadata, status=done). TODO: UPDATE"""
        raise NotImplementedError
