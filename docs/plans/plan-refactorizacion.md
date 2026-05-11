# Plan de Refactorización: Evolución de progressive-harness a Context-Progressive Harness

## Estado Actual

`progressive-harness/` es un arnés funcional pero monolítico. `AGENTS.md` acumula startup workflow, working rules, definición de done y end-of-session en un solo archivo. A medida que un proyecto crece, esto genera:

- **Ineficiencia de tokens**: el agente lee reglas de startup aunque ya esté en mitad de una sesión.
- **Dificultad de mantenimiento**: un solo archivo de 70+ líneas mezcla concerns distintos.
- **Sin persistencia de aprendizaje**: entre sesiones no hay registro de decisiones ni preferencias.

## Estado Deseado

Un arnés que implemente **Contexto Progresivo** (inspirado en [dotagents](https://github.com/bgreenwell/dotagents)):

- `AGENTS.md` como **router**: slim, solo identidad + mapa de qué leer según el momento.
- `rules/` para reglas desacopladas por concern.
- `LOGS/` con estructura jerárquica por agente y por sesión.
- `MEMORY/` para conocimiento persistente del proyecto y del usuario.
- `templates/` para formatos reutilizables que el agente copia al crear logs, decisiones o handoffs.

## Decisiones acordadas

- `.agents/progress/CURRENT.md` reemplaza el legacy `.agents/harness/progress/PROGRESS.md`.
- `.agents/progress/HISTORY.md` será un índice compacto append-only, inspirado en `progress/history.md` del repo de referencia.
- El detalle completo de cada sesión va en `.agents/LOGS/sessions/*.md` y los aportes especializados en `.agents/LOGS/agents/<agent-name>/*.md`.
- `LOGS/agents/` es agnóstico a proveedor/nombre de agente; las subcarpetas se crean bajo demanda.

## Estructura de Carpetas Propuesta

```
progressive-harness/
├── AGENTS.md                    # Router de contexto (slim)
├── ARCHITECTURE.md              # Mapa del sistema (se mantiene)
├── init.sh                      # Verificación y arranque (se mantiene)
├── docs/
│   ├── README.md                # Índice de documentación
│
└── .agents/
    ├── progress/                # Estado operativo vivo del arnés
    │   ├── feature_list.json
    │   ├── feature_list.schema.json
    │   ├── CURRENT.md           # Estado actual mutable (interrupt-resume)
    │   └── HISTORY.md           # Historial compacto append-only por sesión cerrada
    │
    ├── rules/                   # Reglas de comportamiento (solo lectura por el agente)
    │   ├── 00-startup.md        # Qué hacer al iniciar una sesión
    │   ├── 01-working.md        # Reglas durante el trabajo
    │   ├── 02-done.md           # Definición de done
    │   ├── 03-end-of-session.md # Qué hacer antes de cerrar
    │   └── 04-escalation.md     # Cuándo y cómo escalar
    │
    ├── templates/               # Plantillas reutilizables (solo lectura)
    │   ├── current.md           # Formato base para progress/CURRENT.md
    │   ├── history-entry.md     # Formato base para entradas de progress/HISTORY.md
    │   ├── session-log.md       # Formato base para LOGS/sessions/
    │   ├── agent-log.md         # Formato base para LOGS/agents/<agent-name>/
    │   ├── decision.md          # Formato base para entradas en MEMORY/DECISIONS.md
    │   ├── user.md              # Formato base para MEMORY/USER.md
    │   ├── pattern.md           # Formato base para MEMORY/PATTERNS.md
    │   └── handoff.md           # Formato base para handoffs largos, si aplica
    │
    ├── LOGS/                    # Bitácoras (el agente escribe aquí)
    │   ├── sessions/            # Logs completos por sesión cerrada
    │   │   └── YYYY-MM-DD_HHMMSS_description.md
    │   └── agents/              # Logs por especialista (agnóstico al proveedor/agente)
    │       └── <agent-name>/    # Directorio creado bajo demanda
    │           └── YYYY-MM-DD_HHMMSS_description.md
    │
    └── MEMORY/                  # Conocimiento persistente (lectura/escritura)
        ├── DECISIONS.md         # Decisiones arquitectónicas (ADRs ligeros)
        ├── USER.md              # Preferencias y estilo del usuario
        └── PATTERNS.md          # Convenciones que surgieron orgánicamente
```

## Convenciones de Nomenclatura

### Archivos de Reglas (`rules/`)
- Prefijo numérico `00-`, `01-`, etc. para indicar orden de lectura natural.
- Nombre en minúsculas con guiones.
- Extensión `.md`.

### Archivos de Logs (`LOGS/`)
- Formato: `YYYY-MM-DD_HHMMSS_descripcion-corta.md`
- Ejemplos:
  - `2025-01-15_143022_implementar-auth-jwt.md`
  - `2025-01-15_154500_revisar-arquitectura-cache.md`
- El agente debe generar el timestamp al inicio de la sesión y usarlo consistentemente.

### Plantillas (`templates/`)
- Viven en `.agents/templates/` porque son parte del arnés, no del historial ni de la memoria.
- Son archivos de referencia de solo lectura: el agente los consulta y copia su estructura al crear nuevos artefactos.
- No deben contener estado real del proyecto; solo formatos.
- Se mantienen en minúsculas porque no son autoridad operacional como `AGENTS.md` o `MEMORY/`, sino infraestructura auxiliar.

### Estado Operativo (`progress/`)
- Los archivos operativos/autoritativos van en MAYÚSCULAS: `CURRENT.md`, `HISTORY.md`.
- `CURRENT.md` es mutable durante la sesión; `HISTORY.md` es append-only al cierre.
- Las plantillas relacionadas viven en minúsculas en `.agents/templates/` (por ejemplo: `current.md`, `history-entry.md`).

### Archivos de Memoria (`MEMORY/`)
- Nombre en MAYÚSCULAS (como `AGENTS.md`), para transmitir autoridad.
- Sin prefijo numérico: no hay orden de lectura, se consultan bajo demanda.

## Flujo de Contexto Progresivo

```
[Sesión nueva]
    │
    ▼
┌──────────────┐
│  AGENTS.md   │  "Soy el router. ¿Acabas de empezar?"
└──────────────┘
    │
    ▼
┌─────────────────┐
│ rules/00-startup.md │  "Confirma directorio, lee ARCHITECTURE.md, ejecuta init.sh..."
└─────────────────┘
    │
    ▼
┌──────────────────┐
│ rules/01-working.md │  "Una feature a la vez, verificación obligatoria..."
└──────────────────┘
    │
    ▼ (durante el trabajo)
┌──────────────────┐     ┌──────────────┐
│ rules/02-done.md │     │ MEMORY/      │
└──────────────────┘     │ DECISIONS.md │ ("¿Ya decidimos esto antes?")
    │                    │ USER.md      │ ("¿El usuario prefiere X?")
    ▼                    └──────────────┘
[Fin de sesión]
    │
    ▼
┌──────────────────────────┐
│ rules/03-end-of-session.md │  "Actualiza CURRENT.md/HISTORY.md, genera log en LOGS/sessions/..."
└──────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────┐
│ LOGS/sessions/2025-01-15_143022_feature-x.md │
└────────────────────────────────────────────┘
```

## Responsabilidad de Cada Pieza

| Artefacto | Tipo | Quién lee | Quién escribe | ¿Cuándo? |
|-----------|------|-----------|---------------|----------|
| `AGENTS.md` | Router | Agente siempre | Humano (inicial), luego raramente | Arranque de cada sesión |
| `rules/*.md` | Reglas | Agente según fase | Humano (inicial), luego raramente | Cuando el router lo indica |
| `templates/*.md` | Formatos reutilizables | Agente bajo demanda | Humano (inicial), luego raramente | Cuando se crea un log, decisión o handoff |
| `LOGS/sessions/` | Bitácora | Agente (últimos N) | Agente (al finalizar sesión) | End of session |
| `LOGS/agents/<agent-name>/` | Bitácora por especialista | Agente (contexto específico) | Agente especialista | Cuando el especialista actúa |
| `MEMORY/DECISIONS.md` | Conocimiento persistente | Agente (bajo demanda) | Agente (cuando toma una decisión arquitectónica) | Cuando hay una decisión no trivial |
| `MEMORY/USER.md` | Preferencias | Agente (bajo demanda) | Agente (cuando detecta preferencia) | Cuando el usuario expresa preferencia |
| `MEMORY/PATTERNS.md` | Convenciones | Agente (bajo demanda) | Agente (cuando emerge patrón) | Cuando emerge un patrón repetido |
| `progress/CURRENT.md` | Estado vivo mutable | Agente (siempre) | Agente (durante y fin de sesión) | Trabajo activo |
| `progress/HISTORY.md` | Índice histórico compacto append-only | Agente (consulta rápida) | Agente (al cerrar sesión) | Cierre de sesión |

## Separación de Responsabilidades de `CURRENT.md`, `HISTORY.md` y `LOGS/`

El estado operativo se separa en tres capas:

- `CURRENT.md`: estado vivo mutable para continuidad inmediata (interrupt-resume).
- `HISTORY.md`: historial compacto append-only, una entrada por sesión cerrada, con enlace al log completo.
- `LOGS/sessions/*.md`: evidencia completa y cronología detallada de cada sesión.

Esta separación toma el tradeoff observado en el repo de referencia (`current.md` + `history.md`): es simple, pero un único history puede crecer demasiado. En este arnés híbrido, `HISTORY.md` se mantiene compacto como índice y el detalle vive en logs por sesión.

### `CURRENT.md` debe conservar
- Estado actual del proyecto.
- Feature activa o siguiente feature recomendada.
- Próximas acciones concretas.
- Blockers y riesgos abiertos.
- Última verificación conocida, con comando, resultado y enlace al log de sesión.
- Punteros mínimos a historial y memoria persistente.

### `CURRENT.md` no debe contener
- Narrativa completa de la sesión.
- Lista exhaustiva de archivos modificados en cada sesión.
- Salidas largas de comandos.
- Decisiones arquitectónicas completas.
- Preferencias del usuario.
- Historial acumulativo de sesiones cerradas.

### Responsabilidad de otros artefactos
- `LOGS/sessions/`: narrativa completa de cada sesión, archivos tocados, comandos ejecutados, evidencia y notas operativas.
- `LOGS/agents/<agent-name>/`: contribuciones específicas de especialistas, creadas bajo demanda (nombre agnóstico).
- `progress/HISTORY.md`: timeline compacto append-only con un entry por sesión cerrada y enlace al log completo.
- `MEMORY/DECISIONS.md`: decisiones persistentes con contexto, alternativas y consecuencias.
- `MEMORY/USER.md`: preferencias explícitas o estables del usuario.
- `MEMORY/PATTERNS.md`: convenciones repetidas que emergen en el proyecto.

### Regla anti-"teléfono descompuesto"
- Los resultados de especialistas/subagentes deben persistirse en archivos de log.
- La respuesta en chat debe referenciar el archivo generado (ruta + resumen breve), no incluir reportes extensos inline.
- Esta regla debe mantenerse agnóstica al proveedor y al nombre del agente.

### Sketch de `CURRENT.md` (mutable, vivo, corto)

```md
# Current State

## Snapshot

**Last Updated:** YYYY-MM-DD HH:MM
**Active Feature:** [feat-XXX - Feature Name] / None
**Current Session Log:** [LOGS/sessions/YYYY-MM-DD_HHMMSS_description.md]

## Current State
- [Dónde está el proyecto ahora mismo, en 2-5 bullets]

## Next Actions

1. [Most important next action]
2. [Second next action]
3. [Third next action]

## Open Blockers / Risks

- **[Blocker/Risk]**: [impact + mitigation or owner]

## Latest Verification

- **Command:** `[command]`
- **Result:** Pass / Fail / Not run
- **Evidence:** [link to session log]

## Context Pointers

- History index: `progress/HISTORY.md`
- Decisions: `MEMORY/DECISIONS.md`
- User preferences: `MEMORY/USER.md`
- Project patterns: `MEMORY/PATTERNS.md`
```

### Sketch de `HISTORY.md` (append-only, compacto)

```md
# Session History (Compact Index)

> Una línea por sesión cerrada. Append-only.

- YYYY-MM-DD HH:MM | session-id: `YYYY-MM-DD_HHMMSS_description` | foco: [tema] | resultado: [done/partial/blocked] | log: `LOGS/sessions/YYYY-MM-DD_HHMMSS_description.md`
- YYYY-MM-DD HH:MM | session-id: `YYYY-MM-DD_HHMMSS_description` | foco: [tema] | resultado: [done/partial/blocked] | log: `LOGS/sessions/YYYY-MM-DD_HHMMSS_description.md`
```

### Sketch de `LOGS/sessions/*.md` (evidencia completa)

```md
# Session Log: YYYY-MM-DD_HHMMSS_description

## Objective
- [Objetivo de la sesión]

## Timeline
- HH:MM [acción relevante]

## Files Touched
- `path/file.ext` — [cambio resumido]

## Verification
- Command: `[command]`
- Result: Pass/Fail/Not run
- Evidence: [salida resumida o referencia]

## Decisions / Notes
- [decisión o hallazgo]

## Handoff
- [siguiente paso sugerido]
```

## Checklist de Implementación

### Fase 1: Router y Reglas
- [ ] Reescribir `AGENTS.md` como router slim (identidad + context routing).
- [ ] Crear `rules/00-startup.md` extrayendo el startup workflow actual.
- [ ] Crear `rules/01-working.md` extrayendo las working rules actuales.
- [ ] Crear `rules/02-done.md` extrayendo la definición de done actual.
- [ ] Crear `rules/03-end-of-session.md` extrayendo el end-of-session actual.
- [ ] Crear `rules/04-escalation.md` extrayendo la sección de escalation actual.
- [ ] Validar que `init.sh` sigue funcionando tras la refactorización.

### Fase 2: Progress State (migración base)
- [ ] Reemplazar `.agents/harness/` por `.agents/progress/`.
- [ ] Mover `.agents/harness/feature_list.json` a `.agents/progress/feature_list.json`.
- [ ] Mover `.agents/harness/feature_list.schema.json` a `.agents/progress/feature_list.schema.json`.
- [ ] Migrar `.agents/harness/progress/PROGRESS.md` a `.agents/progress/CURRENT.md`.
- [ ] Crear `.agents/progress/HISTORY.md` (append-only, compacto, inspirado en `progress/history.md` de referencia).
- [ ] Refactorizar `CURRENT.md` para estado vivo corto (interrupt-resume).
- [ ] Crear plantillas mínimas en `.agents/templates/`: `current.md`, `history-entry.md`.

### Fase 3: Logs
- [ ] Crear estructura de carpetas `LOGS/sessions/` y `LOGS/agents/` (vacío, contenedor agnóstico).
- [ ] Crear `.agents/templates/session-log.md` para logs de sesión.
- [ ] Crear `.agents/templates/agent-log.md` para logs por especialista (subcarpetas por `<agent-name>` creadas bajo demanda).
- [ ] Mantener detalle operativo y evidencia extensa en `LOGS/sessions/`.
- [ ] Mantener en `CURRENT.md` solo estado actual, próximos pasos, blockers, última verificación y punteros.
- [ ] Actualizar `rules/03-end-of-session.md` para incluir generación de logs y actualización de `HISTORY.md`.

### Fase 4: Memoria
- [ ] Crear estructura de carpetas `MEMORY/`.
- [ ] Crear `.agents/templates/decision.md` con formato de ADR ligero.
- [ ] Crear `.agents/templates/user.md` y `.agents/templates/pattern.md` (opcionales pero recomendadas).
- [ ] Crear `MEMORY/DECISIONS.md` como índice/registro vivo de decisiones persistentes.
- [ ] Crear `MEMORY/USER.md` y `MEMORY/PATTERNS.md` como archivos reales de memoria (no plantillas).
- [ ] Crear `.agents/templates/handoff.md` para handoffs largos, si aplica.

### Fase 5: Documentación y Validación
- [ ] Ajustar referencias en `init.sh` a las nuevas rutas (`.agents/progress/`, `CURRENT.md`, `HISTORY.md`, `LOGS/`).
- [ ] Actualizar `docs/README.md` para reflejar la nueva estructura.
- [ ] Actualizar `progressive-harness/README.md` (el README del ejemplo) para explicar la filosofía de contexto progresivo.
- [ ] Ejecutar `./init.sh` y confirmar que pasa todas las fases.
- [ ] Revisión final de consistencia entre todos los archivos.

## Riesgos y ajustes pendientes

- Definir si `init.sh` validará explícitamente la existencia de `CURRENT.md` y `HISTORY.md`.
- Definir formato final de `HISTORY.md`: una línea por entrada vs bloque corto por sesión.
- Definir política de cierre: log de sesión obligatorio siempre o solo cuando hubo trabajo efectivo.
- Mantener `HISTORY.md` compacto para evitar duplicar contenido de `LOGS/sessions/`.

## Notas de Diseño

1. **¿Por qué `rules/` con prefijo numérico?** Para que el `ls` muestre el orden de lectura natural. El agente no necesita adivinar qué leer primero.

2. **¿Por qué `LOGS/` en mayúsculas?** Para que resalte como directorio de "escritura activa" del agente. Es donde el agente deja huella.

3. **¿Por qué `MEMORY/` en mayúsculas?** Porque es el equivalente a `AGENTS.md` pero para conocimiento persistente. Transmite autoridad y permanencia.

4. **¿Por qué separar `LOGS/sessions/` de `LOGS/agents/`?** Porque un log de sesión es narrativa lineal ("hoy hice X, luego Y"), mientras que un log de agente es especializado ("un especialista recomendó usar patrón Z"). Distinta granularidad, distinto propósito.

5. **¿Qué pasa con `PROGRESS.md`?** Solo aparece como artefacto legacy de migración. El futuro queda en `CURRENT.md` (vivo) + `HISTORY.md` (índice compacto) + `LOGS/` (detalle completo).

## Próximos Pasos

1. Revisar este plan y acordar ajustes.
2. Implementar fase por fase.
3. Iterar sobre las plantillas de logs y memory según experiencia de uso.
