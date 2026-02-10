-- Seed data for local development
-- Run with: supabase db reset

-- Note: 실제 유저는 Supabase Auth를 통해 생성됨.
-- seed는 테스트 데이터 삽입용.
-- auth.users에 직접 INSERT하면 trigger가 users_profile을 자동 생성.

-- 테스트용 프로젝트 (auth user 생성 후 수동 실행)
-- INSERT INTO projects (user_id, name, description) VALUES
--   ('<user-uuid>', 'Test Project', 'Local development test project');
