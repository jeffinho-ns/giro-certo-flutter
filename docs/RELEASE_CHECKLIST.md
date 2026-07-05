# Checklist de release — App Flutter (riders + lojistas)

> Parte do go-live de 2 semanas. Agentes ECC: `ecc-flutter-reviewer`, `ecc-dart-build-resolver`.

## Bloqueadores (você precisa fazer)

### 1. Identidade do app
- [ ] Definir package final (ex.: `br.com.girocerto.app`)
- [ ] Android: `applicationId` em `android/app/build.gradle.kts` (hoje `com.example.giro_certo`)
- [ ] iOS: `PRODUCT_BUNDLE_IDENTIFIER` no Xcode (hoje `com.example.giroCerto`)

### 2. Assinatura Android
- [ ] Gerar keystore (`keytool -genkey ...`)
- [ ] Criar `android/key.properties` (gitignored)
- [ ] Trocar `signingConfig = debug` por release em `build.gradle.kts`

### 3. Firebase / FCM
- [ ] Recriar apps Android/iOS no Firebase com o package final
- [ ] Baixar `google-services.json` e `GoogleService-Info.plist` (não versionar)
- [ ] Configurar APNs (Apple) + `UIBackgroundModes` / remote notifications
- [ ] Testar push `delivery_offer` com tela bloqueada

### 4. Mapbox
- [ ] Token de produção em `android/local.properties` e `ios/MapboxKeys.xcconfig`
- [ ] Build release sem token de placeholder

### 5. API
```bash
flutter build apk --dart-define=API_URL=https://SUA-API/api
# ou
flutter build ipa --dart-define=API_URL=https://SUA-API/api
```
- [ ] Default atual: `https://giro-certo-api.onrender.com/api`

### 6. Observabilidade
- [ ] Handlers de erro globais (já no `main.dart`)
- [ ] Adicionar Crashlytics ou Sentry (próximo passo)

## Smoke no device real (entregador)

- [ ] Login
- [ ] Ficar online
- [ ] Receber oferta (FCM)
- [ ] Aceitar → Mapbox abre
- [ ] Código loja → PIN cliente → concluir
- [ ] Histórico e payout

## Smoke lojista no app

- [ ] Pedidos em tempo real
- [ ] Itens da loja virtual no card
- [ ] Dispatch
- [ ] Produtos / promoções / personalizar

## Smoke social

- [ ] Feed, post, story
- [ ] Garagem + manutenção
- [ ] Manual / comunidades
