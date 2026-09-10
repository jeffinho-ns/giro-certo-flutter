# Distribuição piloto — Android e iOS

> Objetivo: instalar o Giro Certo em **outros telemóveis** sem publicar ainda na Play Store / App Store.  
> Package: Android e iOS `br.com.girocerto.app`. App novo no TestFlight / App Store Connect.

## O que já está pronto no projeto

- Push FCM iOS/Android com API (`giro-certo-72def`)
- Entitlements iOS: **Debug** = sandbox (`Runner.entitlements`), **Release/Profile** = production (`RunnerRelease.entitlements`) — necessário para TestFlight
- UI de diagnóstico FCM removida

---

## Android — partilhar APK

### Gerar

```bash
cd /Users/preto/Documents/GitHub/giro-certo-flutter

flutter build apk --release \
  --dart-define=API_URL=https://giro-certo-api.onrender.com/api
```

APK gerado em:

`build/app/outputs/flutter-apk/app-release.apk`

(Opcional) com vitrine:

```bash
--dart-define=WEB_URL=https://SEU-DOMINIO-NEXT
```

### Instalar noutros Android

1. Enviar o `app-release.apk` (WhatsApp, Drive, AirDrop para um Mac→Android, etc.)
2. No telemóvel: permitir **instalar apps de fontes desconhecidas** / esse ficheiro
3. Abrir o APK e instalar
4. Login entregador ou lojista

> Assinatura atual = keystore **debug** (ok para piloto em aparelhos de confiança). Keystore de loja fica para depois.

---

## iOS — TestFlight (recomendado para vários iPhones)

Cabo USB só serve no teu Mac. Para outros iPhones use **TestFlight**.

### Pré-requisitos (uma vez)

1. [App Store Connect](https://appstoreconnect.apple.com) → criar app:
   - Bundle ID: `br.com.girocerto.app` (tem de existir no Apple Developer)
   - Nome: Giro Certo
2. Em **Users and Access**, convidar os testadores (email Apple ID)
3. Xcode → conta Apple Developer ligada (Team `9HHX57B4G5`)

### Build e upload

```bash
cd /Users/preto/Documents/GitHub/giro-certo-flutter

flutter build ipa --release \
  --dart-define=API_URL=https://giro-certo-api.onrender.com/api
```

Ou no Xcode:

1. `open ios/Runner.xcworkspace`
2. Scheme **Runner** → **Any iOS Device**
3. **Product → Archive**
4. **Distribute App → App Store Connect → Upload**

### Depois do upload

1. App Store Connect → app → **TestFlight**
2. Esperar processamento (~5–30 min)
3. Adicionar build ao grupo **Internal Testing** (ou External)
4. Testadores instalam a app **TestFlight** e aceitam o convite

> Push em TestFlight usa APNs **production** (já alinhado em `RunnerRelease.entitlements`).

---

## Smoke após instalar noutro device

- [ ] Login entregador / lojista
- [ ] Entregador: recebe push com tela bloqueada ao despachar pedido
- [ ] Lojista: vê pedidos / despacha
- [ ] Mapbox / mapa abre (tokens locais no build da máquina que gerou o IPA/APK)

---

## Ainda não fazer (loja)

- Mudar package/bundle final
- Keystore de produção Android
- Publicação pública Play / App Store  

Ver `RELEASE_CHECKLIST.md` depois do piloto.
