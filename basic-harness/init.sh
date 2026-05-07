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

ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$1"; }

EXIT_CODE=0

echo "── 1. Verificando entorno ─────────────────────────────"

# Python disponible
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 no está instalado"
  exit 1
fi
ok "python3 -> $(python3 --version)"

# Versión mínima 3.9 (dataclasses + typing moderno)
PY_VERSION_OK=$(python3 -c 'import sys; print(int(sys.version_info >= (3, 9)))')
if [ "$PY_VERSION_OK" != "1" ]; then
  fail "Se requiere Python >= 3.9"
  exit 1
fi
ok "Versión de Python compatible"

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

for f in AGENTS.md ARCHITECTURE.md init.sh .agents/harness/feature_list.json .agents/harness/feature_list.schema.json .agents/harness/progress/PROGRESS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

echo ""
echo "── 3. Validando feature_list.json ──────────────────────"

python3 - <<'PY'
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

echo ""
echo "── 4. Ejecutando tests ─────────────────────────────────"

if [ -d "tests" ]; then
  if python3 -m unittest discover -s tests -v 2>&1; then
    ok "Todos los tests pasan"
  else
    fail "Hay tests rotos"
    EXIT_CODE=1
  fi
else
  warn "Carpeta tests/ no existe todavía"
fi

echo ""
echo "── 5. Resumen ──────────────────────────────────────────"

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
