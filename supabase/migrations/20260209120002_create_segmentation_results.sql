-- 세그멘테이션 결과 테이블

CREATE TABLE IF NOT EXISTS segmentation_results (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id        UUID REFERENCES projects(id) ON DELETE SET NULL,
    user_id           UUID NOT NULL REFERENCES users_profile(id) ON DELETE CASCADE,
    source_image_url  TEXT NOT NULL,
    mask_image_url    TEXT,
    text_prompt       TEXT NOT NULL,
    labels            JSONB DEFAULT '[]'::jsonb,
    metadata          JSONB DEFAULT '{}'::jsonb,
    status            TEXT NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'processing', 'done', 'error')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 인덱스
CREATE INDEX idx_segmentation_results_user_id ON segmentation_results(user_id);
CREATE INDEX idx_segmentation_results_project_id ON segmentation_results(project_id);
CREATE INDEX idx_segmentation_results_status ON segmentation_results(status);
CREATE INDEX idx_segmentation_results_created_at ON segmentation_results(created_at DESC);

-- updated_at 트리거
CREATE TRIGGER segmentation_results_updated_at
    BEFORE UPDATE ON segmentation_results
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- RLS 활성화
ALTER TABLE segmentation_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own results"
    ON segmentation_results FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own results"
    ON segmentation_results FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own results"
    ON segmentation_results FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own results"
    ON segmentation_results FOR DELETE
    USING (auth.uid() = user_id);

-- Realtime 활성화 (추론 상태 실시간 알림)
ALTER PUBLICATION supabase_realtime ADD TABLE segmentation_results;
