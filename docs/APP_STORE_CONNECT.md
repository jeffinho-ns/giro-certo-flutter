# App Store Connect — novo build (app que já existe)

Você **não** cria um app novo. Os dois IPAs de teste já estão neste registro:

| Campo | Valor já usado |
|---|---|
| Bundle ID | `com.example.giroCerto` |
| Team | `9HHX57B4G5` |
| Nome | Giro Certo |

O que muda agora é só **um build novo** (versão `1.0.0`, build `3`) em cima do mesmo app.

---

## O que NÃO precisa fazer de novo

- Criar App ID no Apple Developer
- Criar app no App Store Connect
- Convidar testers de novo (o grupo Internal/External continua)
- Recriar Firebase / APNs / `GoogleService-Info.plist` (continuam do bundle `com.example.giroCerto`)

---

## O que fazer agora

1. No Mac, no repo atualizado (`main`):

```bash
flutter build ipa --release \
  --dart-define=API_URL=https://giro-certo-api.onrender.com/api
```

Ou Xcode: Scheme **Runner** → Any iOS Device → **Product → Archive** → Distribute App → App Store Connect.

2. App Store Connect → o app Giro Certo que já existe → **TestFlight**
3. Esperar o processamento do build **3**
4. Adicionar esse build ao grupo de testers que você já usa

O Info.plist deste build já traz o que a Apple pede no review (privacidade, criptografia HTTPS, textos de permissão). Isso vai **no binário**; não abre um app novo no Connect.

---

## Quando SÓ aí precisaria de app novo

Só se o Bundle ID no Xcode for diferente de `com.example.giroCerto`.  
Neste código ele voltou a ser o mesmo dos dois testes. Próximo upload entra na mesma ficha.
