# Script: disparar corrida de teste (alarme para todos os motoboys)

Script: [`scripts/disparar-corrida-teste.sh`](../scripts/disparar-corrida-teste.sh)

## O que faz

1. Login como **lojista**
2. Cria um pedido de entrega de teste
3. Chama `POST /api/delivery/:id/dispatch`
4. A API notifica **todos** os motoboys elegíveis:
   - Push FCM `type=delivery_offer` (“Nova corrida disponível”)
   - Socket `delivery:new_order_offer` (app aberto)

Elegíveis = utilizadores com cadastro delivery **ou** `pilotProfile=TRABALHO`, sem loja, não bloqueados, sem corrida ativa.

## Uso

```bash
cd giro-certo-flutter
chmod +x scripts/disparar-corrida-teste.sh

LOGIN_EMAIL='loja@exemplo.com' LOGIN_PASSWORD='senha' \
  ./scripts/disparar-corrida-teste.sh
```

Se a loja estiver em **pré-pago** (bloqueia despacho sem Asaas):

```bash
FORCE_POSTPAID=1 LOGIN_EMAIL='...' LOGIN_PASSWORD='...' \
  ./scripts/disparar-corrida-teste.sh
```

Cancelar automaticamente após 90s (ninguém fica com a corrida):

```bash
CANCEL_AFTER=90 FORCE_POSTPAID=1 LOGIN_EMAIL='...' LOGIN_PASSWORD='...' \
  ./scripts/disparar-corrida-teste.sh
```

## Checklist do teste

- [ ] Pelo menos 2–3 motoboys logados no app (iOS/Android), com notificação permitida
- [ ] App aberto nalgum aparelho + app em background/bloqueado noutro
- [ ] Correr o script
- [ ] Confirmar push + alarme/modal
- [ ] Nos logs Render: `[FCM] OK ... type=delivery_offer`

## Atenção

Isto bate na API de **produção** por omissão (`giro-certo-api.onrender.com`).  
Só corre se quiseres mesmo notificar os motoboys cadastrados nesse ambiente.
