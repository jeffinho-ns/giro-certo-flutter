# BRIEF PARA AGENTE — patch bloqueio de manutenção

Lê isto **antes** de qualquer `git commit` / `git push`.

## Objetivo (único)

Corrigir o bug em que o motoboy **não consegue aceitar corrida** depois de marcar manutenção como feita, porque a API ainda olha logs `CRITICO` **antigos**.

Também: no admin (Next), botão para liberar override + histórico de manutenção no perfil.

## O que NÃO fazer

- **NÃO** versionar nem fazer commit de `.cursor/`, skills, hooks, rules, agents.
- **NÃO** misturar com outros chores (foto de capa, bundle iOS, etc.) neste push.
- **NÃO** alterar `pubspec.yaml` / `ios/` só para “passar o checkout”.
- **NÃO** declarar sucesso sem **verificar no GitHub** os marcadores abaixo.

## Repos e ficheiros (exato)

### A) `jeffinho-ns/giro-certo-api` → branch `main`

Copiar **destes** ficheiros (pasta deste patch) para o repo API:

| Origem (neste patch) | Destino no API |
|---|---|
| `maintenance-block.ts` | `src/utils/maintenance-block.ts` (**novo**) |
| `delivery.service.ts` | `src/services/delivery.service.ts` |
| `alert.service.ts` | `src/services/alert.service.ts` |
| `users.routes.ts` | `src/routes/users.routes.ts` |
| `bikes.routes.ts` | `src/routes/bikes.routes.ts` |

Commit message sugerida:

```
fix(maintenance): bloquear só pelo estado atual + override no admin
```

**Verificação obrigatória no `main` remoto depois do push:**

```bash
# tem de existir:
src/utils/maintenance-block.ts

# users.routes.ts tem de conter:
maintenance-block-override

# delivery.service.ts NÃO pode ter o EXISTS antigo sem DISTINCT ON;
# tem de referenciar SQL_USER_HAS_ACTIVE_CRITICAL_MAINTENANCE ou userHasActiveCriticalMaintenance
```

### B) `jeffinho-ns/giro-certo-next` → branch `main`

| Origem | Destino |
|---|---|
| `next/user-full-profile-dialog.tsx` | `app/dashboard/users/user-full-profile-dialog.tsx` |

Commit message sugerida:

```
feat(admin): histórico de manutenção + liberar override no perfil
```

**Verificação obrigatória no `main` remoto:**

```bash
# o ficheiro TEM de conter estas strings:
Liberar apesar da manutenção
maintenance-block-override
```

### C) Flutter

Os patches e a mensagem amigável de erro já estão neste PR.  
**Não é necessário** push Flutter para o desbloqueio automático (isso é 100% API).  
Flutter só precisa de novo build se quiseres a mensagem de erro amigável no app.

## Como aplicar (escolhe UM caminho)

### Caminho 1 — script no Mac do utilizador (preferido se Cloud Agent sem write em api/next)

No Mac, pastas irmãs típicas: `~/GitHub/giro-certo-{flutter,api,next}`.

```bash
cd ~/GitHub/giro-certo-flutter
# se checkout falhar por WIP em pubspec/ios:
git stash push -u -m "wip antes do patch manutencao" -- pubspec.yaml ios/Runner.xcodeproj/project.pbxproj

git fetch origin
git checkout cursor/fix-manutencao-bloqueio-admin-4e8a
git pull origin cursor/fix-manutencao-bloqueio-admin-4e8a

bash docs/patches/maintenance-block-admin/APLICAR_TUDO.sh
```

### Caminho 2 — Cloud Agent com write nos 3 repos

1. Confirmar token cobre `giro-certo-api` e `giro-certo-next` (senão 403).
2. Correr `APLICAR_TUDO.sh` com paths absolutos dos 3 clones, **ou** copiar os 5+1 ficheiros à mão e push.
3. Correr a secção **Verificação pós-push** no fim de `APLICAR_TUDO.sh`.

## Critério de “está tudo certo”

| Check | Esperado |
|---|---|
| API `main` tem `src/utils/maintenance-block.ts` | sim |
| API `delivery.service` bloqueia só último log / peça | sim |
| API tem rota `PUT .../maintenance-block-override` | sim |
| Next tem botão “Liberar apesar da manutenção” | sim |
| Último commit api/next **não** é só `.cursor/` | sim |
| Render API redeploy Live | sim (aguardar) |

Se algum check falhar → **não** digas que está pronto; corrige e re-verifica.
