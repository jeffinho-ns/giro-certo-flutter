#!/usr/bin/env bash
# Aplica o patch do perfil admin no giro-certo-next.
# Preferir: APLICAR_TUDO.sh (aplica API+Next e verifica remoto).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Pasta atual: $(pwd)"
test -f package.json && test -d app/dashboard/users || {
  echo "ERRO: entra na pasta giro-certo-next primeiro"
  exit 1
}
git checkout main
git pull origin main
cp "$SCRIPT_DIR/next/user-full-profile-dialog.tsx" app/dashboard/users/user-full-profile-dialog.tsx
grep -q maintenance-block-override app/dashboard/users/user-full-profile-dialog.tsx
grep -q "Liberar apesar da manutenção" app/dashboard/users/user-full-profile-dialog.tsx
git add app/dashboard/users/user-full-profile-dialog.tsx
if git diff --cached --name-only | grep -E '^\.cursor(/|$)' >/dev/null; then
  echo "ERRO: .cursor/ no stage — abortado"
  exit 1
fi
git status --short
if git diff --cached --quiet; then
  echo "Nada novo para commit (já aplicado?)."
else
  git commit -m "feat(admin): histórico de manutenção + liberar override no perfil"
  git push origin main
  echo "SUCESSO: push Next feito."
fi
