#!/usr/bin/env bash

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { printf "${GREEN}[OK]${NC}   %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
fail() { printf "${RED}[FAIL]${NC} %s\n" "$1"; }

EXIT_CODE=0
PYTHON_CMD=""

REQUIRED_FILES=(
  "AGENTS.md"
  "ARCHITECTURE.md"
  "init.sh"
  ".agents/progress/feature_list.json"
  ".agents/progress/CURRENT.md"
  ".agents/progress/HISTORY.md"
)

echo "== 1) Validating required files =="

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    ok "Found $file"
  else
    fail "Missing required file: $file"
    EXIT_CODE=1
  fi
done

echo ""
echo "== 2) Validating feature_list.json =="

if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  fail "Python is required to validate .agents/progress/feature_list.json"
  exit 1
fi

"$PYTHON_CMD" - <<'PY'
import json
import sys

path = ".agents/progress/feature_list.json"
required_feature_fields = {"id", "name", "description", "status"}
allowed_statuses = {"pending", "in_progress", "blocked", "done"}

try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"[FAIL] Invalid JSON in {path}: {exc}")
    sys.exit(1)

if not isinstance(data, dict):
    print("[FAIL] feature_list.json root must be an object")
    sys.exit(1)

features = data.get("features")
if not isinstance(features, list):
    print("[FAIL] Missing or invalid top-level 'features' list")
    sys.exit(1)

in_progress_count = 0
for index, feature in enumerate(features):
    if not isinstance(feature, dict):
        print(f"[FAIL] features[{index}] must be an object")
        sys.exit(1)

    missing = required_feature_fields - set(feature.keys())
    if missing:
        print(f"[FAIL] features[{index}] missing required field(s): {', '.join(sorted(missing))}")
        sys.exit(1)

    status = feature.get("status")
    if status not in allowed_statuses:
        allowed = ", ".join(sorted(allowed_statuses))
        print(f"[FAIL] features[{index}].status='{status}' is invalid (allowed: {allowed})")
        sys.exit(1)

    if status == "in_progress":
        in_progress_count += 1

if in_progress_count > 1:
    print(f"[FAIL] Multiple features in progress: {in_progress_count} (maximum: 1)")
    sys.exit(1)

print(f"[OK] feature_list.json is valid ({len(features)} feature(s), in_progress={in_progress_count})")
PY

if [ $? -eq 0 ]; then
  ok "Feature list validation passed"
else
  EXIT_CODE=1
fi

echo ""
echo "== 3) Optional test run =="

if [ -d "tests" ]; then
  if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    if npm test -- --watch=false; then
      ok "npm tests passed"
    else
      fail "npm tests failed"
      EXIT_CODE=1
    fi
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; then
    if command -v pytest >/dev/null 2>&1; then
      if pytest -q; then
        ok "pytest passed"
      else
        fail "pytest failed"
        EXIT_CODE=1
      fi
    else
      warn "tests/ exists but pytest is unavailable; skipping tests"
    fi
  else
    warn "tests/ exists but no safe default test command was detected; skipping"
  fi
else
  warn "No tests/ directory found; skipping tests"
fi

echo ""
echo "== Summary =="
if [ "$EXIT_CODE" -eq 0 ]; then
  ok "Minimal harness checks passed"
else
  fail "Minimal harness checks failed"
fi

exit "$EXIT_CODE"
