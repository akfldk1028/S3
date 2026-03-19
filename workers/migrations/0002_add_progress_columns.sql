-- jobs_log에 진행률 컬럼 3개 추가
-- GET /jobs 목록 조회에서 progress_done/failed/total SELECT하는데 컬럼이 없어서 500 에러 발생
ALTER TABLE jobs_log ADD COLUMN progress_done INTEGER NOT NULL DEFAULT 0;
ALTER TABLE jobs_log ADD COLUMN progress_failed INTEGER NOT NULL DEFAULT 0;
ALTER TABLE jobs_log ADD COLUMN progress_total INTEGER NOT NULL DEFAULT 0;
