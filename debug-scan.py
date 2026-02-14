"""Debug script to reproduce daemon scan logic."""
import json
from pathlib import Path

specs_dir = Path(r"C:\DK\S3\.auto-claude\specs")
QUEUE_STATUSES = frozenset({"queue", "backlog", "queued"})

print(f"Specs dir: {specs_dir}")
print(f"Exists: {specs_dir.exists()}")
print()

for spec_dir in sorted(specs_dir.iterdir()):
    if not spec_dir.is_dir() or spec_dir.name.startswith("."):
        print(f"SKIP: {spec_dir.name} (is_dir={spec_dir.is_dir()}, starts_with_dot={spec_dir.name.startswith('.')})")
        continue

    plan_path = spec_dir / "implementation_plan.json"
    print(f"\n=== {spec_dir.name} ===")
    print(f"  plan exists: {plan_path.exists()}")
    print(f"  plan size: {plan_path.stat().st_size if plan_path.exists() else 'N/A'}")

    if plan_path.exists():
        try:
            with open(plan_path, encoding="utf-8-sig") as f:
                plan = json.load(f)
            status = plan.get("status", "").lower()
            plan_status = plan.get("planStatus", "")
            print(f"  status: '{status}'")
            print(f"  planStatus: '{plan_status}'")
            print(f"  in QUEUE_STATUSES: {status in QUEUE_STATUSES}")
        except Exception as e:
            print(f"  ERROR: {type(e).__name__}: {e}")
