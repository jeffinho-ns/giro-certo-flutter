# Patch: bloqueio por manutenção + liberação no admin

## O que aconteceu no teu teste

A API bloqueava o aceite se **existisse qualquer** `MaintenanceLog` antigo com `CRITICO` / desgaste ≥ 90%.  
Quando marcas “fiz a manutenção” no app, cria-se um log **novo** OK — mas o log crítico antigo ficava e o bloqueio continuava.

## Correção

1. **API** — o bloqueio usa só o **último log por peça** (estado atual). Marcar como feita na Garagem **libera automaticamente**.
2. **API** — endpoint admin `PUT /api/users/:id/maintenance-block-override` com `{ "override": true|false }` para suporte liberar na hora.
3. **Next (admin)** — no perfil completo do motociclista: histórico/estado atual de manutenção + botão **Liberar apesar da manutenção**.
4. **Flutter** — mensagem de erro ao aceitar fica legível (sem `Exception: Erro 400:...`).

## Aplicar no Mac

### 1) giro-certo-api

```bash
cd ~/caminho/para/giro-certo-api
git checkout main && git pull origin main
bash /caminho/para/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-api.sh
```

Ou copie os ficheiros de `docs/patches/maintenance-block-admin/` para `src/` (ver script).

### 2) giro-certo-next

```bash
cd ~/caminho/para/giro-certo-next
git checkout main && git pull origin main
cp /caminho/para/giro-certo-flutter/docs/patches/maintenance-block-admin/next/user-full-profile-dialog.tsx \
  app/dashboard/users/user-full-profile-dialog.tsx
git add app/dashboard/users/user-full-profile-dialog.tsx
git commit -m "feat(admin): liberar override de manutenção + histórico no perfil"
git push origin main
```

### 3) Flutter (mensagem amigável)

Já vai neste PR do `giro-certo-flutter`. Precisa de novo build só para a mensagem; o desbloqueio automático é só API.

## Fluxo esperado

| Situação | Resultado |
|---|---|
| Peça crítica (último log) | Não aceita corrida |
| Piloto marca manutenção feita (OK) | Libera sozinho |
| Admin “Liberar apesar da manutenção” | Override temporário |
| Admin “Bloquear corridas” | `deliveryRiderBlocked` (inadimplência etc.) |
