#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
#
# Salida esperada: códigos de salida claros y bloques marcados con [OK]/[FAIL].

set -u
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --verbose|-v)
      VERBOSE=1
      ;;
  esac
done

ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$1"; }

run_step() {
  # Usage: run_step "human-readable failure message" <command...>
  local failure_message="$1"
  shift
  local output_file
  output_file=$(mktemp)

  if [ "$VERBOSE" -eq 1 ]; then
    "$@"
    local status=$?
    rm -f "$output_file"
    return $status
  fi

  "$@" >"$output_file" 2>&1
  local status=$?
  if [ $status -ne 0 ]; then
    fail "$failure_message"
    printf '%s\n' "---- command output (debug) ----"
    cat "$output_file"
    printf '%s\n' "---- end command output ----"
  fi
  rm -f "$output_file"
  return $status
}

EXIT_CODE=0
PYPROJECT_EXISTS=0
PYTHON_CMD=""
if [ -f "pyproject.toml" ]; then
  PYPROJECT_EXISTS=1
fi

HARNESS_BASE_FILES=(
  AGENTS.md
  ARCHITECTURE.md
  init.sh
  .agents/harness/feature_list.json
  .agents/harness/feature_list.schema.json
  .agents/harness/progress/PROGRESS.md
)

# El path '.' puede ajustarse según cada proyecto, porque cada proyecto es distinto.
FORMAT_CMD=(uv run black --preview --unstable .)
LINT_CMD=(uv run ruff check --output-format grouped .)
TYPECHECK_CMD=(uv run pyrefly check --output-format min-text)

echo "── 1. Verificando entorno ─────────────────────────────"

if [ "$PYPROJECT_EXISTS" -eq 1 ]; then
  # uv disponible
  if ! command -v uv >/dev/null 2>&1; then
    fail "uv no está instalado"
    exit 1
  fi
  ok "uv -> $(uv --version)"

  # Sincronizar dependencias con uv
  if ! run_step "uv sync falló" uv sync --all-groups --all-extras; then
    exit 1
  fi
  ok "Dependencias sincronizadas con uv"

  # Activar entorno virtual del proyecto
  if [ ! -f ".venv/bin/activate" ]; then
    fail "No existe .venv/bin/activate después de uv sync"
    exit 1
  fi

  # shellcheck disable=SC1091
  source .venv/bin/activate
  ok "Entorno virtual .venv activado"

  # Python disponible en el entorno virtual
  if ! command -v python >/dev/null 2>&1; then
    fail "python no está disponible en el entorno virtual"
    exit 1
  fi
  PYTHON_CMD="python"
  ok "python -> $(python --version)"

  # Versión mínima 3.9 (dataclasses + typing moderno)
  PY_VERSION_OK=$(python -c 'import sys; print(int(sys.version_info >= (3, 9)))')
  if [ "$PY_VERSION_OK" != "1" ]; then
    fail "Se requiere Python >= 3.9"
    exit 1
  fi
  ok "Versión de Python compatible"
else
  warn "pyproject.toml no existe; se omiten uv sync y herramientas Python del proyecto. Se intentará validar feature_list.json con Python del sistema."

  if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
  elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
  fi
fi

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

MISSING_BASE_FILES=0
for f in "${HARNESS_BASE_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
    MISSING_BASE_FILES=1
  fi
done

if [ "$MISSING_BASE_FILES" -eq 0 ]; then
  ok "Todos los archivos base del arnés existen; podemos continuar."
fi

echo ""
echo "── 3. Validando feature_list.json ──────────────────────"

if [ -n "$PYTHON_CMD" ]; then
  "$PYTHON_CMD" - <<'PY'
import json, re, sys


def validate_type(value, expected_type, path):
    checks = {
        "object": lambda v: isinstance(v, dict),
        "array": lambda v: isinstance(v, list),
        "string": lambda v: isinstance(v, str),
    }
    if expected_type in checks and not checks[expected_type](value):
        raise ValueError(f"{path} debe ser de tipo {expected_type}")


def validate_schema(value, schema, path="$"):
    if "type" in schema:
        validate_type(value, schema["type"], path)

    if "enum" in schema and value not in schema["enum"]:
        allowed = ", ".join(schema["enum"])
        raise ValueError(f"{path} tiene valor inválido '{value}' (permitidos: {allowed})")

    if "pattern" in schema and isinstance(value, str):
        if not re.match(schema["pattern"], value):
            raise ValueError(f"{path} no cumple patrón {schema['pattern']}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        for key in required:
            if key not in value:
                raise ValueError(f"Falta campo requerido {path}.{key}")

        properties = schema.get("properties", {})
        for key, item in value.items():
            if key in properties:
                validate_schema(item, properties[key], f"{path}.{key}")

    if isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            validate_schema(item, schema["items"], f"{path}[{index}]")


try:
    data = json.load(open(".agents/harness/feature_list.json"))
    schema = json.load(open(".agents/harness/feature_list.schema.json"))
    validate_schema(data, schema)

    in_progress = [f for f in data["features"] if f["status"] == "in_progress"]
    if len(in_progress) > 1:
        print(f"[FAIL]  Hay {len(in_progress)} features en in_progress (máximo 1)")
        sys.exit(1)

    print(f"[OK]    .agents/harness/feature_list.json válido contra .agents/harness/feature_list.schema.json ({len(data['features'])} features)")
except Exception as e:
    print(f"[FAIL]  .agents/harness/feature_list.json inválido: {e}")
    sys.exit(1)
PY

  if [ $? -ne 0 ]; then EXIT_CODE=1; fi
else
  warn "Python no está disponible; se omite validación de feature_list.json."
fi

echo ""
echo "── 4. Formateando código ───────────────────────────────"

if [ "$PYPROJECT_EXISTS" -eq 1 ]; then
  FORMAT_OUTPUT_FILE=$(mktemp)
  FORMAT_CHANGED_FILE=$(mktemp)

  "${FORMAT_CMD[@]}" 2>&1 | tee "$FORMAT_OUTPUT_FILE"
  FORMAT_STATUS=${PIPESTATUS[0]}

  if [ "$FORMAT_STATUS" -eq 0 ]; then
    while IFS= read -r line; do
      case "$line" in
        reformatted\ *)
          printf '%s\n' "${line#reformatted }" >>"$FORMAT_CHANGED_FILE"
          ;;
      esac
    done <"$FORMAT_OUTPUT_FILE"

    if [ -s "$FORMAT_CHANGED_FILE" ]; then
      ok "Formateo aplicado correctamente"
      warn "Black modificó archivos:"
      while IFS= read -r formatted_file; do
        warn "- $formatted_file"
      done <"$FORMAT_CHANGED_FILE"
    else
      ok "Formateo aplicado; no hubo cambios."
    fi
  else
    fail "Formateo con Black falló"
    EXIT_CODE=1
  fi

  rm -f "$FORMAT_OUTPUT_FILE" "$FORMAT_CHANGED_FILE"
else
  warn "pyproject.toml no existe; se omite formateo con Black."
fi

echo ""
echo "── 5. Ejecutando linting ───────────────────────────────"

if [ "$PYPROJECT_EXISTS" -eq 1 ]; then
  if run_step "Linting falló" "${LINT_CMD[@]}"; then
    ok "Linting completado sin errores"
  else
    EXIT_CODE=1
  fi
else
  warn "pyproject.toml no existe; se omite linting con Ruff."
fi

echo ""
echo "── 6. Ejecutando type checking ─────────────────────────"

if [ "$PYPROJECT_EXISTS" -eq 1 ]; then
  if run_step "Type checking falló" "${TYPECHECK_CMD[@]}"; then
    ok "Type checking completado sin errores"
  else
    EXIT_CODE=1
  fi
else
  warn "pyproject.toml no existe; se omite type checking con Pyrefly."
fi

echo ""
echo "── 7. Ejecutando tests ─────────────────────────────────"

if [ -d "tests" ]; then
  if [ "$PYPROJECT_EXISTS" -eq 1 ]; then
    if [ "$VERBOSE" -eq 1 ]; then
      TEST_CMD=(pytest -v -rA --tb=short tests/test_*.py)
    else
      TEST_CMD=(pytest -q -r fE --tb=short --disable-warnings --log-cli-level=ERROR tests/test_*.py)
    fi

    if run_step "Hay tests rotos" "${TEST_CMD[@]}"; then
      ok "Todos los tests pasan"
    else
      EXIT_CODE=1
    fi
  else
    warn "pyproject.toml no existe; se omiten tests de Python."
  fi
else
  warn "Carpeta tests/ no existe todavía"
fi

echo ""
echo "── 8. Resumen ──────────────────────────────────────────"

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
