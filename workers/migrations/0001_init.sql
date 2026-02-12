-- S3 D1 Schema — workflow.md 섹션 5.3
-- 5 테이블: users, rules, jobs_log, job_items_log, billing_events

-- 유저 (MVP: anon만, v2: 소셜 로그인)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  created_at TEXT DEFAULT (datetime('now')),
  plan TEXT DEFAULT 'free',
  credits INTEGER DEFAULT 10,
  auth_provider TEXT DEFAULT 'anon',
  email TEXT,
  device_hash TEXT
);

-- 유저 룰 저장 (BM 핵심: 무료 2슬롯, 유료 20슬롯)
CREATE TABLE rules (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  preset_id TEXT NOT NULL,
  concepts_json TEXT NOT NULL,
  protect_json TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT
);

-- Job 히스토리
CREATE TABLE jobs_log (
  job_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  finished_at TEXT,
  status TEXT,
  preset TEXT,
  rule_id TEXT,
  concepts_json TEXT,
  protect_json TEXT,
  params_json TEXT,
  cost_estimate INTEGER,
  error TEXT
);

-- Item 히스토리
CREATE TABLE job_items_log (
  job_id TEXT NOT NULL,
  idx INTEGER NOT NULL,
  status TEXT,
  input_key TEXT,
  output_key TEXT,
  error TEXT,
  PRIMARY KEY (job_id, idx)
);

-- 정산
CREATE TABLE billing_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  amount INTEGER NOT NULL,
  ref TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

-- 인덱스
CREATE INDEX idx_rules_user ON rules(user_id);
CREATE INDEX idx_jobs_user ON jobs_log(user_id);
CREATE INDEX idx_jobs_status ON jobs_log(status);
CREATE INDEX idx_billing_user ON billing_events(user_id);
