# Push em Background e Tela Bloqueada (Delivery)

Objetivo: garantir alerta de nova corrida para entregadores mesmo com o app em segundo plano, outro app aberto, ou tela bloqueada.

> 📋 **Para configuração manual de iOS:** Veja [`docs/FASE1_IOS_PUSH_SETUP.md`](docs/FASE1_IOS_PUSH_SETUP.md)  
> (Setup do Portal Apple Developer, Firebase, Xcode e troubleshooting completo)

## Fase 1 — Configuracao iOS nativa

Esta fase prepara o projeto Xcode para receber push via APNs/FCM. O que ja foi feito no repositorio:

| Arquivo | Alteracao |
|---------|-----------|
| `ios/Runner/Runner.entitlements` | Criado com `aps-environment` = `development` |
| `ios/Runner/Info.plist` | Adicionado `UIBackgroundModes` > `remote-notification` |
| `ios/Runner.xcodeproj/project.pbxproj` | `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` em Debug, Release e Profile |
| `ios/Runner/AppDelegate.swift` | Ja configura `UNUserNotificationCenter.current().delegate`; `FlutterAppDelegate` + `firebase_messaging` registram token APNs/FCM |

**Identificadores do app:**
- Bundle ID: `com.example.giroCerto`
- Development Team: `9HHX57B4G5`

### Passos manuais ainda necessarios

1. **Apple Developer Portal** ([developer.apple.com](https://developer.apple.com/account)):
   - Em *Certificates, Identifiers & Profiles* > *Identifiers*, abrir (ou criar) o App ID `com.example.giroCerto`.
   - Habilitar capability **Push Notifications**.
   - Criar uma **APNs Auth Key** (.p8) ou certificado APNs (recomendado: Auth Key, reutilizavel).

2. **Firebase Console** > Project Settings > Cloud Messaging:
   - Em *Apple app configuration*, fazer upload da APNs Auth Key (.p8) com Key ID e Team ID (`9HHX57B4G5`).
   - Confirmar que o app iOS esta registrado com bundle `com.example.giroCerto`.

3. **`GoogleService-Info.plist`** (nao commitar):
   - Baixar do Firebase Console e colocar em `ios/Runner/GoogleService-Info.plist`.
   - O arquivo ja deve estar no `.gitignore`; nunca commitar credenciais Firebase.

4. **Xcode** (validacao visual, opcional):
   - Abrir `ios/Runner.xcworkspace`.
   - Target Runner > *Signing & Capabilities*: confirmar **Push Notifications** e **Background Modes** > *Remote notifications* (refletidos pelos arquivos acima).

5. **Build de producao / TestFlight** (quando for publicar):
   - Alterar `aps-environment` em `Runner.entitlements` de `development` para `production`.
   - Builds de debug/profile usam sandbox APNs (`development`); App Store/TestFlight exigem `production`.

6. **Teste em dispositivo fisico** (simulador nao recebe push real):
   - Instalar app, conceder permissao de notificacao.
   - Verificar token FCM no backend via logs de `requestPermissionAndRegisterToken()`.

---

## 1) Pre-requisitos Firebase

1. Criar projeto/app no Firebase Console:
   - Android: pacote `com.example.giro_certo`
   - iOS: bundle `com.example.giroCerto`
2. Baixar arquivos e adicionar no projeto:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
3. iOS (Apple Developer + Xcode):
   - Habilitar `Push Notifications`
   - Habilitar `Background Modes > Remote notifications`
   - Configurar chave APNs no Firebase

## 2) O que ja foi preparado no app

- Handler de push em background:
  - `lib/services/push_notification_service.dart`
  - `firebaseMessagingBackgroundHandler(...)`
- Canal Android para notificacao de alta prioridade com som:
  - canal: `giro_certo_alerts`
- Registro de token FCM e renovacao de token (`onTokenRefresh`)
- Meta-data no Android para canal padrao de push:
  - `android/app/src/main/AndroidManifest.xml`
- Build Android sem quebrar se `google-services.json` ainda nao existir:
  - `android/settings.gradle.kts`
  - `android/app/build.gradle.kts`

## 3) Payload recomendado para "nova corrida"

No backend, enviar push com:

- `data.type = delivery_offer`
- `data.orderId = <id_da_corrida>`
- prioridade alta:
  - Android: `priority: high`
  - APNs: `apns-priority: 10`
- som:
  - Android: `sound: default`
  - iOS APNs payload com `sound: "default"`

## 4) Comportamento esperado por estado do app

- App aberto (foreground):
  - exibe modal de oferta + som (fluxo in-app)
- App em background:
  - push nativo aparece no sistema com som
- Tela bloqueada:
  - push nativo aparece na lock screen com som
- App finalizado:
  - push nativo aparece; ao tocar, app abre e redireciona para fluxo de oferta

## 5) Checklist de teste rapido (real device)

1. Abrir app como entregador aprovado
2. Confirmar permissao de notificacao concedida
3. Gerar corrida no painel/lojista
4. Testar nos 4 cenarios:
   - app aberto
   - app em segundo plano
   - usando outro app
   - tela bloqueada
5. Validar:
   - tocou som
   - notificacao apareceu
   - ao tocar, abriu o fluxo correto

## 6) Diagnostico de falhas

- Token FCM nao chega no backend:
  - verificar logs de `requestPermissionAndRegisterToken()`
- Android nao mostra push:
  - conferir permissao de notificacao (Android 13+)
  - conferir `google-services.json` e package id
- iOS nao mostra push:
  - conferir APNs key no Firebase
  - conferir capabilities no Xcode
- Som nao toca:
  - verificar payload com `sound`
  - confirmar canal Android com `playSound: true`

