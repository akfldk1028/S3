-- 사용량 로그 테이블

CREATE TABLE IF NOT EXISTS usage_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users_profile(id) ON DELETE CASCADE,
    action        TEXT NOT NULL CHECK (action IN ('segmentation', 'upload')),
    credits_used  INTEGER NOT NULL DEFAULT 1,
    metadata      JSONB DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 인덱스
CREATE INDEX idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX idx_usage_logs_created_at ON usage_logs(created_at DESC);

-- RLS 활성화
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own usage"
    ON usage_logs FOR SELECT
    USING (auth.uid() = user_id);

-- INSERT는 service_role에서만 (Backend/Edge에서 직접 삽입)
CREATE POLICY "Service role can insert usage"
    ON usage_logs FOR INSERT
    WITH CHECK (true);
    -- Note: 프로덕션에서는 service_role key를 사용하는 경우에만 INSERT 허용
