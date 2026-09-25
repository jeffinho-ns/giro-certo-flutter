#!/usr/bin/env bash
# =============================================================================
# APLICAR_TUDO.sh — patch bloqueio de manutenção (API + Next)
# =============================================================================
#
# LÊ TAMBÉM: PARA_O_AGENTE.md (nesta pasta) antes de improvisar.
#
# O QUE ESTE SCRIPT FAZ
#   1) Localiza giro-certo-api e giro-certo-next (irmãos do Flutter ou args)
#   2) Aplica ficheiros do patch (NÃO toca em .cursor/)
#   3) Commit + push em main de cada repo
#   4) Verifica marcadores locais (e remotos se gh estiver disponível)
#
# O QUE ESTE SCRIPT NÃO FAZ
#   - Não versiona .cursor / skills / hooks / rules
#   - Não resolve WIP do Flutter (faz stash só se precisares à mão)
#   - Não faz deploy no Render (só push; espera Live depois)
#
# USO
#   # A partir do Flutter, com pastas irmãs ~/GitHub/giro-certo-{api,next}:
#   bash docs/patches/maintenance-block-admin/APLICAR_TUDO.sh
#
#   # Ou com paths explícitos:
#   bash APLICAR_TUDO.sh /Users/preto/GitHub/giro-certo-api /Users/preto/GitHub/giro-certo-next
#
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
ok()   { echo "${GREEN}✔${RESET} $*"; }
warn() { echo "${YELLOW}⚠${RESET} $*"; }
die()  { echo "${RED}✖${RESET} $*" >&2; exit 1; }
header(){ echo; echo "${BOLD}=== $* ===${RESET}"; }

# --- Pré-checagens do patch ---
header "Pré-checagem dos ficheiros do patch"
need=(
  maintenance-block.ts
  delivery.service.ts
  alert.service.ts
  users.routes.ts
  bikes.routes.ts
  next/user-full-profile-dialog.tsx
  aplicar-api.sh
  aplicar-next.sh
  PARA_O_AGENTE.md
)
for f in "${need[@]}"; do
  test -f "$SCRIPT_DIR/$f" || die "Falta no patch: $SCRIPT_DIR/$f — faz checkout da branch cursor/fix-manutencao-bloqueio-admin-4e8a no Flutter"
  ok "patch: $f"
done

# --- Resolver paths dos repos ---
API_DIR="${1:-}"
NEXT_DIR="${2:-}"

if [[ -z "$API_DIR" ]]; then
  for candidate in \
    "$FLUTTER_ROOT/../giro-certo-api" \
    "$HOME/GitHub/giro-certo-api" \
    "$HOME/github/giro-certo-api" \
    "$HOME/Developer/giro-certo-api"
  do
    if [[ -d "$candidate/src/routes" && -f "$candidate/package.json" ]]; then
      API_DIR="$(cd "$candidate" && pwd)"
      break
    fi
  done
fi

if [[ -z "$NEXT_DIR" ]]; then
  for candidate in \
    "$FLUTTER_ROOT/../giro-certo-next" \
    "$HOME/GitHub/giro-certo-next" \
    "$HOME/github/giro-certo-next" \
    "$HOME/Developer/giro-certo-next"
  do
    if [[ -d "$candidate/app/dashboard/users" && -f "$candidate/package.json" ]]; then
      NEXT_DIR="$(cd "$candidate" && pwd)"
      break
    fi
  done
fi

[[ -n "$API_DIR" && -d "$API_DIR" ]] || die "Não encontrei giro-certo-api. Passe o path: $0 /path/api /path/next"
[[ -n "$NEXT_DIR" && -d "$NEXT_DIR" ]] || die "Não encontrei giro-certo-next. Passe o path: $0 /path/api /path/next"

ok "API  = $API_DIR"
ok "Next = $NEXT_DIR"
ok "Flutter (fonte do patch) = $FLUTTER_ROOT"

# --- Guard: nunca adicionar .cursor ---
assert_no_cursor_staged() {
  local repo="$1"
  if git -C "$repo" diff --cached --name-only | grep -E '^\.cursor(/|$)' >/dev/null; then
    die "[$repo] .cursor/ entrou no stage — ABORTADO. Este patch NÃO versiona .cursor/"
  fi
}

verify_api_working_tree() {
  local repo="$1"
  test -f "$repo/src/utils/maintenance-block.ts" || die "API: falta src/utils/maintenance-block.ts"
  grep -q "userHasActiveCriticalMaintenance\|SQL_USER_HAS_ACTIVE_CRITICAL_MAINTENANCE" \
    "$repo/src/utils/maintenance-block.ts" "$repo/src/services/delivery.service.ts" \
    || die "API: delivery/maintenance-block sem marcadores do patch"
  grep -q "maintenance-block-override" "$repo/src/routes/users.routes.ts" \
    || die "API: users.routes.ts sem maintenance-block-override"
  # Regressão: EXISTS genérico sem DISTINCT ON / util novo
  if grep -n 'FROM "MaintenanceLog" ml' "$repo/src/services/delivery.service.ts" \
    | grep -v maintenance-block >/dev/null 2>&1; then
    # ainda pode haver SQL via constante importada — OK se importar o util
    grep -q "from '../utils/maintenance-block'" "$repo/src/services/delivery.service.ts" \
      || grep -q "from \"../utils/maintenance-block\"" "$repo/src/services/delivery.service.ts" \
      || warn "API: delivery.service.ts pode ainda ter SQL antigo — revê manualmente"
  fi
  ok "API working tree: marcadores OK"
}

verify_next_working_tree() {
  local repo="$1"
  local f="$repo/app/dashboard/users/user-full-profile-dialog.tsx"
  test -f "$f" || die "Next: falta user-full-profile-dialog.tsx"
  grep -q "Liberar apesar da manutenção" "$f" || die "Next: falta botão 'Liberar apesar da manutenção'"
  grep -q "maintenance-block-override" "$f" || die "Next: falta chamada maintenance-block-override"
  ok "Next working tree: marcadores OK"
}

apply_api() {
  header "Aplicar + commit + push — giro-certo-api"
  cd "$API_DIR"
  git checkout main
  git pull origin main

  mkdir -p src/utils src/services src/routes
  cp "$SCRIPT_DIR/maintenance-block.ts" src/utils/maintenance-block.ts
  cp "$SCRIPT_DIR/delivery.service.ts"  src/services/delivery.service.ts
  cp "$SCRIPT_DIR/alert.service.ts"     src/services/alert.service.ts
  cp "$SCRIPT_DIR/users.routes.ts"      src/routes/users.routes.ts
  cp "$SCRIPT_DIR/bikes.routes.ts"      src/routes/bikes.routes.ts

  verify_api_working_tree "$API_DIR"

  git add \
    src/utils/maintenance-block.ts \
    src/services/delivery.service.ts \
    src/services/alert.service.ts \
    src/routes/users.routes.ts \
    src/routes/bikes.routes.ts

  assert_no_cursor_staged "$API_DIR"

  if git diff --cached --quiet; then
    warn "API: nada novo para commit (já aplicado?). A seguir à verificação remota."
  else
    git status --short
    git commit -m "$(cat <<'EOF'
fix(maintenance): bloquear só pelo estado atual + override no admin

Aceitar corrida deixava de funcionar com logs CRITICO antigos mesmo após
marcar manutenção como feita. Agora usa o último log por peça; admin pode
ativar maintenanceBlockOverride no perfil.
EOF
)"
    git push origin main
    ok "API: push origin main feito"
  fi
}

apply_next() {
  header "Aplicar + commit + push — giro-certo-next"
  cd "$NEXT_DIR"
  git checkout main
  git pull origin main

  cp "$SCRIPT_DIR/next/user-full-profile-dialog.tsx" \
    app/dashboard/users/user-full-profile-dialog.tsx

  verify_next_working_tree "$NEXT_DIR"

  git add app/dashboard/users/user-full-profile-dialog.tsx
  assert_no_cursor_staged "$NEXT_DIR"

  if git diff --cached --quiet; then
    warn "Next: nada novo para commit (já aplicado?). A seguir à verificação remota."
  else
    git status --short
    git commit -m "feat(admin): histórico de manutenção + liberar override no perfil"
    git push origin main
    ok "Next: push origin main feito"
  fi
}

verify_remote_github() {
  header "Verificação no GitHub (main)"
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh não instalado — verifica à mão no browser"
    return 0
  fi

  local api_file next_file
  if gh api repos/jeffinho-ns/giro-certo-api/contents/src/utils/maintenance-block.ts?ref=main \
      --jq '.path' 2>/dev/null | grep -q maintenance-block; then
    ok "remoto API: maintenance-block.ts existe"
  else
    die "remoto API: maintenance-block.ts AUSENTE no main — push falhou ou não chegou"
  fi

  api_file="$(gh api repos/jeffinho-ns/giro-certo-api/contents/src/routes/users.routes.ts?ref=main --jq '.content' | base64 -d)"
  echo "$api_file" | grep -q "maintenance-block-override" \
    && ok "remoto API: maintenance-block-override presente" \
    || die "remoto API: users.routes sem maintenance-block-override"

  next_file="$(gh api repos/jeffinho-ns/giro-certo-next/contents/app/dashboard/users/user-full-profile-dialog.tsx?ref=main --jq '.content' | base64 -d)"
  echo "$next_file" | grep -q "Liberar apesar da manutenção" \
    && ok "remoto Next: botão Liberar presente" \
    || die "remoto Next: falta 'Liberar apesar da manutenção'"
  echo "$next_file" | grep -q "maintenance-block-override" \
    && ok "remoto Next: maintenance-block-override presente" \
    || die "remoto Next: falta maintenance-block-override"

  # Guard: último commit não pode ser só .cursor
  local api_msg next_msg
  api_msg="$(gh api repos/jeffinho-ns/giro-certo-api/commits?per_page=1 --jq '.[0].commit.message' | head -1)"
  next_msg="$(gh api repos/jeffinho-ns/giro-certo-next/commits?per_page=1 --jq '.[0].commit.message' | head -1)"
  echo "  último commit API : $api_msg"
  echo "  último commit Next: $next_msg"
  if echo "$api_msg" | grep -qi 'versiona regras\|skills e hooks\|\.cursor'; then
    warn "último commit API parece ser só .cursor — confirma se o fix de manutenção veio ANTES ou num commit seguinte"
  fi
}

# --- main ---
header "BRIEF (resumo)"
cat <<EOF
Bug: API bloqueava aceite se EXISTISSE qualquer MaintenanceLog CRITICO antigo.
Fix: bloquear só pelo ÚLTIMO log por peça + override admin no Next.
Repos:  $API_DIR  e  $NEXT_DIR
NÃO commitar: .cursor/
EOF

apply_api
apply_next
verify_remote_github

header "PRÓXIMOS PASSOS HUMANOS"
cat <<EOF
1) Espera o Render da API ficar Live.
2) No admin (Next), abre o perfil do piloto → deve aparecer
   "Liberar apesar da manutenção" e histórico.
3) No app: marcar manutenção feita OU usar o botão Liberar → aceitar corrida.
4) Flutter: opcional merge do PR #5 (mensagem de erro amigável).
EOF

ok "CONCLUÍDO — se todos os ✔ remotos passaram, está certo."
