# Build piloto — App Flutter apontando para produção

> Fase **antes** da publicação nas lojas. Instala no telefone via cabo/USB.  
> **Não** altera package ID (`com.example.*`). **Não** publica na Play Store / App Store.  
> Checklist de loja: [`RELEASE_CHECKLIST.md`](./RELEASE_CHECKLIST.md) (só **após** o piloto).

---

## Debug vs piloto (release no device)

| Modo | Comando típico | Quando usar |
|------|----------------|-------------|
| **Debug (casa / smoke)** | `flutter run` | Desenvolvimento, hot reload, logs verbosos. Pode usar API default ou `--dart-define`. |
| **Piloto (release no device)** | `flutter run --release --dart-define=...` | Teste realista de performance/rede com API e web de produção. Ainda **sem** Play/App Store. |
| **Loja (após piloto)** | `flutter build apk` / `ipa` + assinatura + package final | Ver `RELEASE_CHECKLIST.md`. |

O default de `API_URL` no código já aponta para produção Render:

`https://giro-certo-api.onrender.com/api`

Mesmo assim, no piloto **passe os defines explicitamente** para não depender do default e para configurar o `WEB_URL` da vitrine.

---

## Dart-defines usados pelo app

| Define | Onde | Default | Notas |
|--------|------|---------|--------|
| `API_URL` | `lib/services/api_service.dart` | `https://giro-certo-api.onrender.com/api` | Deve terminar em `/api`. |
| `WEB_URL` | `lib/screens/sidebars/profile_sidebar.dart` (“Ver vitrine”) | `''` (vazio) | Se vazio, o lojista só copia o path `/loja/{slug}`. Com valor, abre o browser. |
| `MAPBOX_STYLE_DAY` / `MAPBOX_STYLE_NIGHT` | `lib/config/mapbox_studio_style_config.dart` | vazio | Opcional (estilos Studio). |

---

## Comando piloto (device físico)

Substitua as URLs pelas de produção reais (API e Next):

```bash
cd /caminho/para/giro-certo-flutter

flutter run --release --dart-define=API_URL=https://YOUR-API --dart-define=WEB_URL=https://YOUR-NEXT
```

Equivalente (mais legível):

```bash
flutter run --release \
  --dart-define=API_URL=https://YOUR-API \
  --dart-define=WEB_URL=https://YOUR-NEXT
```

Exemplo com o ambiente atual (Render + domínio da vitrine):

```bash
flutter run --release \
  --dart-define=API_URL=https://giro-certo-api.onrender.com/api \
  --dart-define=WEB_URL=https://SEU-DOMINIO-NEXT
```

### APK / IPA só para instalação lateral (ainda não é loja)

```bash
flutter build apk --release \
  --dart-define=API_URL=https://YOUR-API \
  --dart-define=WEB_URL=https://YOUR-NEXT

flutter build ipa --release \
  --dart-define=API_URL=https://YOUR-API \
  --dart-define=WEB_URL=https://YOUR-NEXT
```

> No Android, o `build.gradle.kts` ainda assina release com **keystore de debug** — suficiente para piloto em aparelhos de confiança. Keystore de produção fica para a fase de loja.

---

## Tokens locais obrigatórios (Mapbox)

Sem estes ficheiros/tokens, a navegação turn-by-turn **não arranca** (placeholder no Android).

### Android

1. Copiar exemplo:
   ```bash
   cp android/local.properties.example android/local.properties
   ```
2. Preencher (ficheiro no `.gitignore`):
   - `MAPBOX_DOWNLOADS_TOKEN` — token **secreto** `sk.*` com scope `DOWNLOADS:READ` (Gradle baixa o SDK).
   - `MAPBOX_ACCESS_TOKEN` — token **público** `pk.*` (runtime no app).
3. Opcional: `GOOGLE_MAPS_API_KEY` se usar Google Maps em algum ecrã.

### iOS

1. Copiar exemplo:
   ```bash
   cp ios/MapboxKeys.xcconfig.example ios/MapboxKeys.xcconfig
   ```
2. Preencher `MAPBOX_ACCESS_TOKEN=pk....` (incluído por `Debug`/`Release`/`Profile.xcconfig`).
3. Para pods Mapbox, o token de downloads costuma ir no ambiente / `~/.netrc` conforme o `Podfile` (ver comentários em `ios/Podfile`).

### Opcional (estilos)

```bash
--dart-define=MAPBOX_STYLE_DAY=mapbox://styles/USER/STYLE_ID \
--dart-define=MAPBOX_STYLE_NIGHT=mapbox://styles/USER/STYLE_ID
```

---

## Firebase no piloto

- Package atual: Android `com.example.giro_certo`, iOS `com.example.giroCerto`.
- Se já existir `google-services.json` / `GoogleService-Info.plist` **para estes IDs**, push FCM pode funcionar no piloto.
- **Não** recriar Firebase com package final agora — isso quebra instalações atuais. Ver secção “após piloto” em `RELEASE_CHECKLIST.md` e `FIREBASE_SETUP.md` / `PUSH_BACKGROUND_SETUP.md`.

---

## Smoke rápido no device (piloto)

1. Login (entregador / lojista).
2. Entregador: online → oferta → aceite → Mapbox → PIN → concluir.
3. Lojista: pedidos em tempo real + “Ver vitrine” (abre `WEB_URL` se definido).
4. Confirmar que as chamadas batem na API de produção (não localhost).

Próximo passo do plano de go-live (API): `docs/GO_LIVE_DIA_0` / checklist de dia 0 no repo `giro-certo-api`.
