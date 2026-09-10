# App Store Connect — novo app Giro Certo

Use estes valores ao **criar o app de novo** em [App Store Connect](https://appstoreconnect.apple.com).  
O bundle antigo `com.example.giroCerto` deixa de valer: o IPA novo é outro app. Testers do TestFlight piloto precisam **reinstalar**.

Team Apple Developer: `9HHX57B4G5`

---

## 1) Apple Developer — Identifiers (antes do Connect)

1. [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **+**
2. App IDs → App
3. Preencher:

| Campo | Valor |
|---|---|
| Description | Giro Certo |
| Bundle ID | **Explicit** `br.com.girocerto.app` |

Capabilities a marcar:

- Push Notifications
- Associated Domains (só se for usar universal links da vitrine)

Salvar. O provisioning Automatic Signing no Xcode (`DEVELOPMENT_TEAM = 9HHX57B4G5`) gera o perfil.

---

## 2) Criar o app no App Store Connect

Apps → **+** → New App:

| Campo | Valor |
|---|---|
| Platforms | iOS |
| Name | Giro Certo |
| Primary Language | Portuguese (Brazil) |
| Bundle ID | `br.com.girocerto.app` (precisa aparecer na lista; se não, volte ao passo 1) |
| SKU | `girocerto-ios` |
| User Access | Full Access |

Se o nome “Giro Certo” estiver tomado, use “Giro Certo Entregas” no Connect; o nome **no ícone** continua `Giro Certo` (`CFBundleDisplayName`).

---

## 3) Informações da ficha (App Information)

| Campo | Sugestão |
|---|---|
| Category | Lifestyle (secundária: Navigation ou Social Networking) |
| Content Rights | Does not contain, or has license |
| Age Rating | Responda o questionário; o app tem localização e conteúdo gerado por usuários (posts/chat) |

**Criptografia (export compliance):** o Info.plist já tem `ITSAppUsesNonExemptEncryption = false`. No Connect, escolha que o app **só usa criptografia isenta** (HTTPS).

---

## 4) Privacidade (App Privacy)

O `PrivacyInfo.xcprivacy` declara os mesmos tipos. No formulário:

- **Data used to track you:** No
- Tipos usados, **ligados à identidade**, **não** para tracking:

| Tipo | Uso |
|---|---|
| Precise Location | Mapa e corridas |
| Name | Conta |
| Email Address | Login |
| Phone Number | Cadastro / entrega |
| Physical Address | Endereço de entrega |
| Photos or Videos | Perfil, momentos, documentos |
| User ID | Conta |
| Device ID | Push FCM |
| Other User Content | Posts, stories, chat |

Purpose: **App Functionality**.  
Não marque tracking / advertising.

**Política de privacidade:** URL pública obrigatória. Sem ela o Connect não deixa submeter. Hospede uma página (site da Giro Certo ou a vitrine Next) e cole o link aqui.

---

## 5) Firebase + APNs (obrigatório depois do bundle novo)

O `GoogleService-Info.plist` antigo é do `com.example.giroCerto`. Push **não** funciona no app novo até:

1. Firebase Console → adicionar app **iOS** com bundle `br.com.girocerto.app`
2. Baixar o novo `GoogleService-Info.plist` e colocar em `ios/Runner/` (ficheiro **gitignored**)
3. Cloud Messaging → Apple → chave APNs (pode reutilizar a chave do time)
4. Restringir a chave Maps iOS no Google Cloud ao bundle `br.com.girocerto.app`

---

## 6) Build e upload

```bash
flutter build ipa --release \
  --dart-define=API_URL=https://giro-certo-api.onrender.com/api \
  --dart-define=WEB_URL=https://SEU-DOMINIO-NEXT
```

Ou Xcode: Scheme Runner → Any iOS Device → Product → Archive → Distribute App → App Store Connect.

Versão no `pubspec.yaml`: `1.0.0+1` (marketing 1.0.0, build 1). Cada upload seguinte incrementa o `+N`.

TestFlight: processar o build → grupo Internal Testing → convidar testers **de novo** (app novo).

---

## 7) O que o binário já traz

- Bundle `br.com.girocerto.app`
- Nome Giro Certo
- Entitlements Release: `aps-environment = production`
- Manifesto de privacidade
- ATS só HTTPS (sem HTTP aberto)
- Textos de permissão (localização, câmera, microfone, galeria, Face ID)
- Sem `NSUserTrackingUsageDescription` (não usamos ATT / IDFA)

---

## Android (Play, depois)

`applicationId` também passou a `br.com.girocerto.app`. Recrie o app Android no Firebase com esse package antes do AAB de loja. Keystore de upload ainda está no checklist (`signingConfig = debug` no release).
