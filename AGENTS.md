# AGENTS.md — Instruções para qualquer IA / agente

> Este repositório faz parte da iniciativa **Loja Virtual (Giro Certo)**, que abrange três repos:
> `giro-certo-api` (backend), `giro-certo-next` (web) e `giro-certo-flutter` (app).
>
> **ANTES de qualquer tarefa, leia o documento mestre [`PLANO_LOJA_VIRTUAL.md`](./PLANO_LOJA_VIRTUAL.md) na raiz.** Ele contém o objetivo, a arquitetura, o modelo de dados, o roadmap e os checklists de segurança. Siga-o como fonte de verdade.

## Como você (agente) deve agir

- **Sempre alerte o usuário** (em português) quando uma ação tocar em qualquer um dos pontos críticos abaixo, antes de executá-la.
- Não desvie do plano sem avisar. Se algo no plano conflitar com a realidade do código, **pare e alerte**.
- Na loja virtual, este app **mexe pouco**: o foco é o `PartnerHomeScreen` exibir os itens do pedido (via `storeOrderId`). Aceite/despacho seguem idênticos ao fluxo atual.

## ALERTAS OBRIGATÓRIOS (sempre avisar antes de prosseguir)

1. **Nunca commitar segredos nem lixo de build.** ESPECIALMENTE `android/app/google-services.json` (credenciais), `android/.gradle/`, `android/local.properties`, e qualquer `.env`/keystore. Alerte e bloqueie antes de qualquer `git add`/commit amplo. **Revise o `.gitignore` antes de commits.**
2. **Segurança mora na API.** Toda autorização real é imposta na `giro-certo-api`, nunca no app.
3. **Nunca confiar em preço/valor calculado no cliente.** O total vem/é validado pela API.
4. **Pedido só vira entrega após pagamento confirmado pelo webhook do Asaas.**
5. **Rastreamento com privacidade.** Localização do motoboy só durante a entrega ativa.
6. **Isolamento por loja.** Lojista só vê a própria loja (`partnerId`).

## Específico deste repo (giro-certo-flutter)

- Flutter + **provider**. `ApiService` em `lib/services/api_service.dart`. Realtime via Socket.IO (`lib/services/realtime_service.dart`). Navegação Mapbox em `lib/features/trip_navigation/`.
- App multi-perfil: motoboy (`HomeScreen`/`delivery_screen.dart`) e lojista (`partner_home_screen.dart`).
- **ATENÇÃO ao estado do git deste repo:** o `main` remoto costuma estar à frente; há WIP local que pode conflitar. Sempre alerte antes de operações de git destrutivas e prefira `stash` a descartar mudanças.

## Git

- Só commitar/push quando o usuário pedir explicitamente.
- Nunca incluir segredos/artefatos de build. Em commits, adicione arquivos específicos, não `git add .` cego.
