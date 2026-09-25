# Patch: bloqueio por manutenção + liberação no admin

> **Agente / humano:** começa por [`PARA_O_AGENTE.md`](./PARA_O_AGENTE.md) e corre [`APLICAR_TUDO.sh`](./APLICAR_TUDO.sh).

## O que aconteceu no teu teste

A API bloqueava o aceite se **existisse qualquer** `MaintenanceLog` antigo com `CRITICO` / desgaste ≥ 90%.  
Quando marcas “fiz a manutenção” no app, cria-se um log **novo** OK — mas o log crítico antigo ficava e o bloqueio continuava.

## Correção

1. **API** — o bloqueio usa só o **último log por peça** (estado atual). Marcar como feita na Garagem **libera automaticamente**.
2. **API** — endpoint admin `PUT /api/users/:id/maintenance-block-override` com `{ "override": true|false }` para suporte liberar na hora.
3. **Next (admin)** — no perfil completo do motociclista: histórico/estado atual de manutenção + botão **Liberar apesar da manutenção**.
4. **Flutter** — mensagem de erro ao aceitar fica legível (sem `Exception: Erro 400:...`).

## Aplicar no Mac (recomendado)

Pastas típicas: `~/GitHub/giro-certo-{flutter,api,next}`.

```bash
cd ~/GitHub/giro-certo-flutter

# Se o checkout falhar por WIP local (pubspec / ios):
git stash push -u -m "wip antes do patch manutencao" -- pubspec.yaml ios/Runner.xcodeproj/project.pbxproj

git fetch origin
git checkout cursor/fix-manutencao-bloqueio-admin-4e8a
git pull origin cursor/fix-manutencao-bloqueio-admin-4e8a

# Aplica API + Next, faz push e verifica no GitHub:
bash docs/patches/maintenance-block-admin/APLICAR_TUDO.sh
```

Paths explícitos (se não forem pastas irmãs):

```bash
bash docs/patches/maintenance-block-admin/APLICAR_TUDO.sh \
  ~/GitHub/giro-certo-api \
  ~/GitHub/giro-certo-next
```

### Scripts individuais (só se precisares)

```bash
cd ~/GitHub/giro-certo-api
bash ~/GitHub/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-api.sh

cd ~/GitHub/giro-certo-next
bash ~/GitHub/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-next.sh
```

## O que NÃO fazer

- Não fazer commit de `.cursor/`, skills, hooks ou rules — isso **não** é este patch.
- Não declarar sucesso sem os checks remotos (o `APLICAR_TUDO.sh` falha se faltar).

## Flutter (mensagem amigável)

Já vai neste PR do `giro-certo-flutter`. Precisa de novo build só para a mensagem; o desbloqueio automático é só API.

## Fluxo esperado

| Situação | Resultado |
|---|---|
| Peça crítica (último log) | Não aceita corrida |
| Piloto marca manutenção feita (OK) | Libera sozinho |
| Admin “Liberar apesar da manutenção” | Override temporário |
| Admin “Bloquear corridas” | `deliveryRiderBlocked` (inadimplência etc.) |
