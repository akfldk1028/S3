-- S3 D1 초기 스키마 마이그레이션
-- 5 테이블: users, rules, jobs_log, job_items_log, billing_events
-- 4 인덱스: (user_id, created_at) on rules, jobs_log, billing_events + job_id on job_items_log

-- 유저 테이블
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  plan TEXT NOT NULL DEFAULT 'free',
  credits INTEGER NOT NULL DEFAULT 0,
  auth_provider TEXT NOT NULL,
  device_hash TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 유저 룰 저장 (무료 2슬롯, 유료 20슬롯)
CREATE TABLE IF NOT EXISTS rules (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  preset_id TEXT,
  concepts_json TEXT NOT NULL DEFAULT '[]',
  protect_json TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Job 히스토리
CREATE TABLE IF NOT EXISTS jobs_log (
  job_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  preset TEXT,
  rule_id TEXT,
  concepts_json TEXT NOT NULL DEFAULT '[]',
  protect_json TEXT NOT NULL DEFAULT '[]',
  cost_estimate INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  finished_at TEXT,
  error TEXT
);

-- Job 아이템 히스토리 (복합 PK)
CREATE TABLE IF NOT EXISTS job_items_log (
  job_id TEXT NOT NULL,
  idx INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  input_key TEXT,
  output_key TEXT,
  error TEXT,
  PRIMARY KEY (job_id, idx)
);

-- 정산 이벤트
CREATE TABLE IF NOT EXISTS billing_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  amount INTEGER NOT NULL DEFAULT 0,
  ref TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_rules_user_created ON rules (user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_jobs_log_user_created ON jobs_log (user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_billing_user_created ON billing_events (user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_job_items_job_id ON job_items_log (job_id);
