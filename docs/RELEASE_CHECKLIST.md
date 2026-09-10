# Checklist de release nas lojas — App Flutter (riders + lojistas)

> Identidade atual (TestFlight já em uso): Android `com.example.giro_certo`, iOS `com.example.giroCerto`.  
> **Não** criar app novo no Connect — só subir build. Guia: [`APP_STORE_CONNECT.md`](./APP_STORE_CONNECT.md).  
> Package final (`br.com.girocerto.app`) fica para quando for publicar na loja pública, não agora.

---

## Ordem recomendada

1. Subir build novo no TestFlight **do app que já existe**
2. Keystore Android + Crashlytics — quando for Play / loja pública
3. Só na loja pública: trocar package/bundle (quebra instalações atuais)

---

## Identidade do app

- [x] Bundle do piloto / TestFlight: `com.example.giroCerto` / `com.example.giro_certo`
- [ ] Package final `br.com.girocerto.app` — **não agora** (só na publicação pública)
- [x] Testers atuais continuam no mesmo app; só instalam o build novo

---

## Após piloto — assinatura Android

- [ ] Gerar keystore de upload (`keytool -genkey ...`) e guardar backup offline
- [ ] Criar `android/key.properties` (gitignored) com paths/passwords
- [ ] Em `android/app/build.gradle.kts`, trocar `signingConfig = debug` do `release` por signing de produção
- [ ] Confirmar Play App Signing (Google Play Console) se usar upload key separada

---

## Após piloto — assinatura / provisioning iOS

- [ ] Conta Apple Developer + App ID com o bundle final
- [ ] Certificados Distribution + perfil Provisioning
- [ ] Capabilities: Push Notifications, Background Modes → Remote notifications
- [ ] Archive no Xcode / `flutter build ipa` com o bundle final

---

## Após piloto — Firebase / FCM (produção)

Stub de passos (detalhe operacional em `FIREBASE_SETUP.md` e `PUSH_BACKGROUND_SETUP.md`):

1. [ ] No Firebase Console, criar (ou recriar) apps **Android** e **iOS** com o **package/bundle final** (não reutilizar só o `com.example.*` se o ID mudar).
2. [ ] Descarregar e colocar localmente (não versionar segredos):
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
3. [ ] Confirmar que o plugin Google Services aplica no Android quando o JSON existe (`build.gradle.kts` já é condicional).
4. [ ] Alinhar o projeto Firebase com o backend (mesma conta/projeto usado pela API para FCM Admin, se aplicável).
5. [ ] Testar registo de token FCM e push `delivery_offer` com app em background / tela bloqueada.

### APNs (iOS)

- [ ] Criar chave APNs no Apple Developer
- [ ] Carregar a chave no Firebase Console (Cloud Messaging → Apple)
- [ ] Validar `UIBackgroundModes` / remote notifications no Runner
- [ ] Testar push com prioridade alta (`apns-priority: 10`) conforme `PUSH_BACKGROUND_SETUP.md`

---

## Após piloto — Mapbox (produção)

- [ ] Tokens de produção (não de desenvolvimento) em:
  - `android/local.properties` — `MAPBOX_DOWNLOADS_TOKEN` (`sk.*`) + `MAPBOX_ACCESS_TOKEN` (`pk.*`)
  - `ios/MapboxKeys.xcconfig` — `MAPBOX_ACCESS_TOKEN` (`pk.*`)
- [ ] Build release sem placeholder `CONFIGURE_MAPBOX_ACCESS_TOKEN_NO_LOCAL_PROPERTIES`
- [ ] (Opcional) estilos Studio via `--dart-define=MAPBOX_STYLE_DAY=...` / `MAPBOX_STYLE_NIGHT=...`

---

## Após piloto — API / WEB no build de loja

```bash
flutter build apk --release \
  --dart-define=API_URL=https://YOUR-API \
  --dart-define=WEB_URL=https://YOUR-NEXT

# ou
flutter build ipa --release \
  --dart-define=API_URL=https://YOUR-API \
  --dart-define=WEB_URL=https://YOUR-NEXT
```

- [ ] `API_URL` termina em `/api` e aponta para produção
- [ ] `WEB_URL` é a origem pública do Next (vitrine)
- [ ] Default no código (se omitir define): `https://giro-certo-api.onrender.com/api` — preferir define explícito no CI/loja

Comandos de piloto (device, sem loja): ver [`PILOTO_BUILD.md`](./PILOTO_BUILD.md).

---

## Após piloto — observabilidade

- [ ] Handlers de erro globais (já em `main.dart`) — manter
- [ ] Integrar **Firebase Crashlytics** (ou Sentry) e encaminhar erros dos handlers
- [ ] Validar crash de teste no console antes do internal track
- [ ] (Opcional) Analytics básico de funil entrega (aceite → conclusão)

---

## Após piloto — distribuição interna

### Google Play (internal testing)

- [ ] Criar app no Play Console com o `applicationId` final
- [ ] Upload do AAB assinado (`flutter build appbundle --release --dart-define=...`)
- [ ] Track **Internal testing** + lista de testers
- [ ] Política de privacidade / fichas da loja (mínimo para internal)

### Apple TestFlight

- [ ] App record no App Store Connect com o bundle final
- [ ] Upload do IPA / Archive
- [ ] Grupo de testers internos + build processado
- [ ] Testar push e Mapbox em build TestFlight (não só cabo)

---

## Smoke final (tracks internos)

### Entregador

- [ ] Login
- [ ] Ficar online
- [ ] Receber oferta (FCM, app em background)
- [ ] Aceitar → Mapbox abre
- [ ] Código loja → PIN cliente → concluir
- [ ] Histórico e payout

### Lojista no app

- [ ] Pedidos em tempo real
- [ ] Itens da loja virtual no card
- [ ] Dispatch
- [ ] Produtos / promoções / personalizar
- [ ] “Ver vitrine” abre `WEB_URL`

### Social

- [ ] Feed, post, story
- [ ] Garagem + manutenção
- [ ] Manual / comunidades

---

## Referências

| Doc | Uso |
|-----|-----|
| [`PILOTO_BUILD.md`](./PILOTO_BUILD.md) | Release no device apontando a produção (agora) |
| [`../FIREBASE_SETUP.md`](../FIREBASE_SETUP.md) | Storage (API) + FCM no app |
| [`../PUSH_BACKGROUND_SETUP.md`](../PUSH_BACKGROUND_SETUP.md) | Push background / APNs |
| `giro-certo-api/docs/GO_LIVE_2_SEMANAS.md` | Plano geral; loja só no final |
