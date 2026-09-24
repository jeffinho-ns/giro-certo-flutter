#!/usr/bin/env bash
# Aplica o patch de bloqueio por manutenção no giro-certo-api.
# Uso: a partir da pasta giro-certo-api:
#   bash /caminho/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-api.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Pasta atual: $(pwd)"
test -f package.json && test -d src/routes || {
  echo "ERRO: entra na pasta giro-certo-api primeiro"
  exit 1
}

git checkout main
git pull origin main

mkdir -p src/utils src/services src/routes
cp "$SCRIPT_DIR/maintenance-block.ts" src/utils/maintenance-block.ts
cp "$SCRIPT_DIR/delivery.service.ts" src/services/delivery.service.ts
cp "$SCRIPT_DIR/alert.service.ts" src/services/alert.service.ts
cp "$SCRIPT_DIR/users.routes.ts" src/routes/users.routes.ts
cp "$SCRIPT_DIR/bikes.routes.ts" src/routes/bikes.routes.ts

grep -q userHasActiveCriticalMaintenance src/utils/maintenance-block.ts
grep -q maintenance-block-override src/routes/users.routes.ts
grep -q SQL_USER_HAS_ACTIVE_CRITICAL_MAINTENANCE src/services/delivery.service.ts

git add \
  src/utils/maintenance-block.ts \
  src/services/delivery.service.ts \
  src/services/alert.service.ts \
  src/routes/users.routes.ts \
  src/routes/bikes.routes.ts

git status
git commit -m "$(cat <<'EOF'
fix(maintenance): bloquear só pelo estado atual + override no admin

Aceitar corrida deixava de funcionar com logs CRITICO antigos mesmo após
marcar manutenção como feita. Agora usa o último log por peça; admin pode
ativar maintenanceBlockOverride no perfil.
EOF
)"
git push origin main
echo "SUCESSO: push API feito. Espera o Render ficar Live."
