# Configuração Manual de iOS Push Notifications — Fase 1

> **Para quem acabou de receber a assinatura Apple Developer**  
> Guia prático passo-a-passo para ativar notificações push no Giro Certo.
> 
> **Data da última atualização:** 2026-09-02  
> **Referência:** Consulte também [`PUSH_BACKGROUND_SETUP.md`](../PUSH_BACKGROUND_SETUP.md) para testes em todos os cenários.

---

## ⚠️ Pré-requisitos

- ✅ **Assinatura Apple Developer** ativa (acabou de ser criada)
- ✅ **Xcode 16+** instalado no Mac (`/Applications/Xcode.app`)
- ✅ **Projeto Firebase** já criado com app iOS registrado
- ✅ **Device físico iOS 13+** para testes (notificações push **não funcionam no simulador**)
- ✅ **Account Apple Developer** vinculada no Xcode (`Xcode > Settings > Accounts`)

**Seu Team ID (Apple Developer):** `9HHX57B4G5`

---

## Parte A — Portal Apple Developer

### A.1 — Registrar/Verificar App ID com Push Notifications

A Apple exige um App ID explícito (identificador único) para ativar Push Notifications. Este é **diferente** do bundle ID do Xcode — é um registro no portal.

#### Passo 1: Acessar Certificates, Identifiers & Profiles

1. Abra o navegador e acesse: **https://developer.apple.com/account/resources/identifiers/list**
2. Faça login com sua conta Apple Developer (a mesma vinculada ao Xcode)
3. Clique no botão **"+" (Registrar um novo ID)** no canto superior direito

#### Passo 2: Selecionar tipo "App IDs"

1. Na tela "Register a New Identifier", escolha:
   - **☑ App IDs** (é a opção padrão)
   - Clique **Continue**

#### Passo 3: Configurar App ID

1. **Select type:** escolha **App** (a primeira opção)
2. Clique **Continue**

#### Passo 4: Preencher dados do app

Aparecerá um formulário. Preencha:

| Campo | Valor | Observação |
|-------|-------|-----------|
| **Description** | Giro Certo Entregador | Nome legível; usado só no portal |
| **Bundle ID** | `com.example.giroCerto` | Não use wildcards (*); deve ser único globalmente |
| **Capabilities** | ✅ **Push Notifications** | Marque esta caixa obrigatoriamente |

**Screnshot mental:** Você verá uma lista de "Capabilities" (App Groups, Associated Domains, Background Modes, etc.). Procure por **"Push Notifications"** e marque a caixa ao lado.

3. Clique **Continue**

#### Passo 5: Confirmar e criar

1. Revise os dados (Description, Bundle ID, Capabilities)
2. Clique **Register**
3. **Sucesso!** Você verá a mensagem "App ID 'com.example.giroCerto' has been registered."

#### Passo 6: Localizar o App ID (para referência futura)

Você agora aparece na lista em **Certificates, Identifiers & Profiles > Identifiers**.  
Salve o **"Identifier"** (será algo como `com.example.giroCerto`).

---

### A.2 — Criar APNs Authentication Key (.p8)

APNs (Apple Push Notification service) é o servidor da Apple que envia as notificações. A chave `.p8` é a credencial que autoriza seu backend (Firebase) a enviar notificações.

#### Passo 1: Acessar Keys

1. No mesmo portal, vá para: **Certificates, Identifiers & Profiles > Keys**
2. Clique **"+" (Create a new key)** no canto superior direito

#### Passo 2: Selecionar tipo "Apple Push Notifications service (APNs)"

1. Na tela "Create a new key", marque:
   - ☑ **Apple Push Notifications service (APNs)**
   - (Não marque outras opções; queremos só APNs)

2. Clique **Continue**

#### Passo 3: Configurar a chave

1. **Key Name:** `GiroCerto-APNs-Key` (um nome descritivo)
2. **Configure key:** nenhuma config adicional é necessária
3. Clique **Continue**

#### Passo 4: Baixar e guardar o arquivo `.p8`

1. Aparecerá a tela "Download Your Key"
2. Clique **Download** — seu navegador baixará um arquivo chamado:
   ```
   AuthKey_[KEY_ID].p8
   ```
   **Exemplo:** `AuthKey_AB12CD34EF.p8`

3. **Guarde este arquivo em um local seguro** (ex.: `~/Downloads/`, depois mova para um lugar seguro no seu projeto)
4. ⚠️ **AVISO:** A Apple só permite fazer download **uma única vez**. Se perder, terá de criar uma nova chave.
5. Clique **Done**

#### Passo 5: Anotar o Key ID

Na tela "Keys", você verá uma tabela com a chave que acabou de criar.  
Procure pela linha com o nome `GiroCerto-APNs-Key` e copie o **"Key ID"** (uma sequência de 10 caracteres, algo como `AB12CD34EF`).

**Guarde isto para o Passo A.3.**

---

### A.3 — Confirmar Team ID

Seu **Team ID** já foi fornecido acima: `9HHX57B4G5`

Para confirmá-lo:

1. No portal, clique no seu nome no canto superior direito
2. Escolha **Account**
3. Role até **"Membership"** ou **"Team ID"**
4. Você verá: `9HHX57B4G5`

**Anote tudo:**

| Valor | O que é | Exemplo |
|-------|---------|---------|
| **Bundle ID** | Identificador do app (React Native) | `com.example.giroCerto` |
| **Key ID** | Identificador da chave APNs | `AB12CD34EF` |
| **Team ID** | Seu identificador de desenvolvedor Apple | `9HHX57B4G5` |
| **Arquivo .p8** | Chave privada para enviar pushes | `AuthKey_AB12CD34EF.p8` |

---

## Parte B — Firebase Console

### B.1 — Fazer upload da chave APNs ao Firebase

Agora você vai conectar a chave `.p8` que baixou ao seu projeto Firebase.

#### Passo 1: Acessar Cloud Messaging

1. Abra **Firebase Console:** https://console.firebase.google.com
2. Clique no seu projeto (ex: `giro-certo`)
3. No menu lateral, vá para:
   - **Settings** (ícone de engrenagem no rodapé) 
   - ou **Project settings > Cloud Messaging**

#### Passo 2: Encontrar aba "Apple app configuration"

Na página "Project Settings", procure pela aba/seção **"Apple app configuration"** (deve estar ao lado de "Android", "Web", etc.).

#### Passo 3: Upload da chave APNs

1. Na seção "Apple app configuration", procure por um campo ou botão dizendo:
   - **"APNs Key Configuration"** ou **"Upload APNs Key"**
   
2. Clique em **"Upload"** (se houver um botão) ou em **"Upload Authentication Key"**

3. Uma janela de seleção de arquivo abrirá. Navegue e escolha o arquivo `.p8` que você baixou:
   - `AuthKey_AB12CD34EF.p8`

4. Após o upload, o Firebase **pedirá automaticamente:**
   - **Key ID:** Cole o valor que anotou em A.3 (ex: `AB12CD34EF`)
   - **Team ID:** Cole `9HHX57B4G5`

5. Clique **Save** ou **Upload**

**Screenshot mental:** A chave foi marcada como "uploaded" (verá um ícone de sucesso ou o upload será confirmado com mensagem verde).

---

### B.2 — Verificar Bundle ID do app iOS no Firebase

Ainda na seção "Apple app configuration", confirme:

1. **Bundle ID** está registrado como `com.example.giroCerto` (deve aparecer numa lista de apps iOS)
2. Se não aparecer:
   - Vá para **Project Settings > Your apps**
   - Procure por um app iOS chamado "Runner" (padrão do Flutter)
   - Clique e verifique o Bundle ID (deve ser `com.example.giroCerto`)
   - Se estiver errado, exclua e registre novamente

**Compatibilidade é crítica:** O Bundle ID no Xcode, no Portal Apple Developer, e no Firebase **DEVEM SER IDÊNTICOS**.

---

### B.3 — Enviar notificação de teste pelo Firebase

Agora que tudo está conectado, teste enviando uma notificação manualmente.

#### Passo 1: Acessar Messaging

1. No Firebase Console, vá para **Engage > Cloud Messaging**

#### Passo 2: Criar notificação

1. Clique **"New campaign"** ou **"Send your first message"**
2. Escolha **"Firebase Notification Compose"** (primeira opção)

#### Passo 3: Preencher dados da notificação

| Campo | Valor |
|-------|-------|
| **Title** | `Teste de Push` |
| **Body** | `Notificação de teste — iOS push!` |
| **Target** | Escolha "User segment" (ou registre um token específico) |
| **Platform** | ☑ iOS |

#### Passo 4: Enviar

1. Clique **Review** → **Publish**
2. A notificação será enviada para todos os devices com a app instalada e FCM registrado

**Esperado:** Se o app está rodando no device (foreground), você verá uma notificação no console ou em logs. Se está em background, aparecerá uma notificação nativa na tela.

---

## Parte C — Xcode (Verificação Manual)

Depois de configurar o portal e Firebase, confirme no Xcode que as capacidades estão ativas.

### C.1 — Abrir projeto no Xcode

```bash
cd /Users/preto/Documents/GitHub/giro-certo-flutter
open ios/Runner.xcworkspace
```

⚠️ **Importante:** Abra o `.xcworkspace`, **não** o `.xcodeproj`. O workspace inclui as dependências do CocoaPods (Flutter, Firebase, etc.).

### C.2 — Selecionar o target "Runner"

1. No Xcode, à esquerda, vá para **Project Navigator** (primeiro ícone)
2. Procure por **"Runner"** (pode estar embaixo de "Pods")
3. Clique em **Runner** para selecioná-lo
4. Na barra do topo, escolha **Target** (segunda coluna) e clique **"Runner"**

### C.3 — Verificar aba "Signing & Capabilities"

1. Na barra do topo, clique na aba **"Signing & Capabilities"**

2. Procure pelas seções:
   - ✅ **Push Notifications** (deve estar lá, com ícone de "✓")
   - ✅ **Background Modes > Remote notifications** (deve estar ativa)

3. Se alguma estiver faltando:
   - Clique o botão **"+ Capability"** (canto superior esquerdo)
   - Digite "Push"
   - Clique **"Push Notifications"**
   - Repita para "Background Modes" → "Remote notifications"

### C.4 — Verificar Signing (Team)

1. Ainda na aba "Signing & Capabilities", procure por:
   - **Team:** deve aparecer `9HHX57B4G5` (seu Team ID)
   - **Bundle Identifier:** deve aparecer `com.example.giroCerto`

2. Se o Team não estiver correto:
   - Clique no dropdown "Team"
   - Escolha sua conta Apple Developer
   - Se não aparecer, vá para **Xcode > Settings > Accounts** e vincule sua conta

### C.5 — Compilação e assinatura

Tudo configurado? Bom, agora:

```bash
# No terminal, na raiz do flutter:
flutter clean
flutter pub get
flutter run -d "<seu_device_id>"
```

Onde `<seu_device_id>` é o ID do seu iPhone/iPad. Você pode achar com:

```bash
flutter devices
```

**Screenshot mental:** O Xcode vai compilar a app, assinando com seu time (`9HHX57B4G5`). Se tudo correr bem, a app é instalada no device e você verá o prompt de permissão de notificação.

---

## Parte D — Test Checklist (4 Cenários)

Baseado em [`PUSH_BACKGROUND_SETUP.md`](../PUSH_BACKGROUND_SETUP.md), aqui estão os 4 cenários obrigatórios de teste:

### Setup Inicial

1. **Instale a app** no device físico (não simulator)
2. **Gere um novo delivery order** no painel/lojista (ou use o endpoint `/api/deliveries/create` do backend)
3. **Confirme que o FCM token foi registrado** (check logs do Firebase ou do backend)

---

### Cenário 1: App aberto (Foreground)

| Passo | Ação | Esperado |
|-------|------|----------|
| 1 | Abra o Giro Certo no device | App visível |
| 2 | Envie um push de "nova corrida" do backend | |
| 3 | Verifique tela | Modal de oferta aparece **dentro** do app + som toca |
| 4 | Confirme FCM handler | Handler impresso nos logs (check `flutter logs`) |

**Payload esperado do backend:**
```json
{
  "notification": {
    "title": "Nova corrida!",
    "body": "Entrega de R$ 45,00"
  },
  "data": {
    "type": "delivery_offer",
    "orderId": "order-123"
  },
  "apns": {
    "headers": { "apns-priority": "10" },
    "payload": { "aps": { "sound": "default" } }
  }
}
```

**Se não funcionou:**
- Verifique se o app tem **permissão de notificação** (Settings > App > Notifications)
- Verifique se `onMessage` listener do FCM está registrado em `push_notification_service.dart`
- Confira `flutter logs` por erros do Firebase

---

### Cenário 2: App em background (Background)

| Passo | Ação | Esperado |
|-------|------|----------|
| 1 | Abra o Giro Certo e deixe rodar ~5s | App aberto |
| 2 | Clique **home button** para minimizar | App sai da tela, fica em RAM |
| 3 | Abra outro app (ex: Safari) | Giro Certo está em background |
| 4 | Envie um push do backend | |
| 5 | Olhe para a tela | **Notificação nativa iOS aparece no topo** + som toca |
| 6 | Toque na notificação | App volta e abre o fluxo de oferta |

**Comportamento:** Notificação aparece na **notification center** do iOS (deslize para baixo da tela).

**Se não funcionou:**
- Verifique Firebase > Cloud Messaging > Recent messages (deve haver registros de entrega)
- Verifique permissão (Settings > App > Notifications > Allow notifications)
- Confirme APNs key foi feito upload no Firebase (Parte B)
- Confira `firebaseMessagingBackgroundHandler` em `push_notification_service.dart`

---

### Cenário 3: Outro app aberto

| Passo | Ação | Esperado |
|-------|------|----------|
| 1 | Abra Safari (ou outro app qualquer) | Giro Certo em background |
| 2 | Envie push do backend | |
| 3 | Olhe para a tela | Notificação nativa iOS aparece no topo |
| 4 | Toque na notificação | **Giro Certo é trazido para frente** e abre oferta |

**Diferença do Cenário 2:** Aqui, outro app está **ativo** (foreground), não é só background.

---

### Cenário 4: Tela bloqueada (Lock screen)

| Passo | Ação | Esperado |
|-------|------|----------|
| 1 | Pressione **power button** (ou use Lock Screen) | Tela preta, bloqueada |
| 2 | Deixe Giro Certo em background (rodar antes, depois lock) | Device bloqueado; app suspenso |
| 3 | Envie push do backend | |
| 4 | Olhe para a tela bloqueada | **Notificação aparece na lock screen** + som toca |
| 5 | Deslize para cima na notificação | App abre e mostra oferta |

**Comportamento:** Na lock screen, a notificação é "expandida" (mostra título e corpo).

---

### Checklist de Validação Global

- [ ] **Todos os 4 cenários funcionam** (app aberto, background, outro app, lock screen)
- [ ] **Som toca em todos** (se configurado no payload)
- [ ] **App abre o fluxo correto** ao tocar na notificação
- [ ] **Token FCM é registrado** no backend (database)
- [ ] **Firebase Console mostra status "delivered"** para as notificações enviadas
- [ ] **Não há crash** de app durante testes
- [ ] **Logs limpos** (sem erros Firebase ou Permission denied)

---

## Parte E — Troubleshooting: Problemas Comuns de iOS Push

### Problema: "APNs key not configured in Firebase"

**Sintoma:** Firebase Console exibe aviso; notificações não chegam ao device iOS.

**Solução:**
1. Volte para **Parte B.1** — confirme o upload da chave `.p8`
2. Verifique **Key ID** e **Team ID** estão corretos
3. Teste: envie um push pelo Firebase; confira **Cloud Messaging > Recent messages** para status

---

### Problema: "App não solicita permissão de notificação"

**Sintoma:** Device nunca pediu "Allow notifications?" durante instalação da app.

**Solução:**
1. Verifique `main.dart` ou `push_notification_service.dart` — há chamada a `requestPermissionAndRegisterToken()`?
2. Se não houver, adicione:

```dart
// Em push_notification_service.dart
Future<void> requestPermissionAndRegisterToken() async {
  NotificationSettings settings = 
    await FirebaseMessaging.instance.requestUserPermission(
      alert: true,
      announcement: true,
      badge: true,
      carryForward: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permission');
  }
}
```

3. Chame no `main()` ou durante onboarding do app

4. Se já foi concedida uma vez:
   - **Settings > Giro Certo > Notifications > Allow Notifications** (ative)
   - Ou desinstale a app e reinstale (será solicitado novamente)

---

### Problema: "Notificação aparece, mas não faz som"

**Sintoma:** Notificação chega, mas som não toca (vibração talvez, mas sem áudio).

**Solução:**
1. **No device:** Settings > Giro Certo > Notifications > Sound → ativar e escolher som (ex: "Default")
2. **No payload do backend**, confirme:

```json
{
  "apns": {
    "payload": {
      "aps": {
        "sound": "default"
      }
    }
  }
}
```

3. **Verifique Android também:** Se for uma app multi-plataforma, confira o payload Android:

```json
{
  "android": {
    "priority": "high",
    "notification": {
      "sound": "default",
      "channel_id": "giro_certo_alerts"
    }
  }
}
```

---

### Problema: "Bundle ID mismatch: Xcode ≠ Firebase ≠ Portal"

**Sintoma:** Notificações não chegam; erros sobre "App not configured" no Firebase.

**Solução:**
1. Confirme o Bundle ID em 3 lugares:
   - **Xcode:** Target > General > Bundle Identifier (ex: `com.example.giroCerto`)
   - **Firebase:** Project Settings > Your apps > iOS app > Bundle ID
   - **Portal Apple Developer:** Certificates, Identifiers & Profiles > Identifiers > Bundle ID

2. Se houver diferença:
   - Escolha **UM** Bundle ID (ex: `com.example.giroCerto`)
   - Altere Xcode para esse Bundle ID
   - Altere Firebase para esse Bundle ID
   - Verifique que o Portal Apple Developer tem um App ID para esse Bundle ID

3. **Limpe e recompile:**

```bash
flutter clean
flutter pub get
flutter run -d <device_id>
```

---

### Problema: "Device iOS não recebe push; Android funciona"

**Sintoma:** Android push chega; iOS nada.

**Causas e soluções:**

| Causa | Verificação |
|-------|-----------|
| APNs key não foi feito upload | **Parte B.1:** confirme na Firebase Console |
| Team ID errado | Verifique no Xcode: Target > Signing & Capabilities > Team |
| Bundle ID não corresponde | Veja "Bundle ID mismatch" acima |
| Permissão de notificação negada | Settings > Giro Certo > Notifications > On |
| Código de background handler faltando | Confira `firebaseMessagingBackgroundHandler` em `push_notification_service.dart` |
| Device não conectado ao WiFi/celular | Notificações precisam de rede; tente WiFi |

---

### Problema: "Notificação chega, mas não abre a tela de oferta"

**Sintoma:** Notificação é recebida e toca som; ao tocar na notificação, app abre mas **não navega para a oferta**.

**Solução:**
1. Verifique o handler `onMessageOpenedApp` em `push_notification_service.dart`:

```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  if (message.data['type'] == 'delivery_offer') {
    final orderId = message.data['orderId'];
    // Navegar para delivery offer screen com orderId
    // GoRouter.of(context).pushNamed('delivery-offer', queryParams: {'orderId': orderId});
  }
});
```

2. Verifique se as rotas do GoRouter estão definidas (check `lib/routes/app_router.dart` ou similar)

3. Se estiver usando `GoRouter`, confirme que a rota `delivery-offer` existe:

```dart
GoRoute(
  path: '/delivery-offer/:orderId',
  name: 'delivery-offer',
  builder: (context, state) => DeliveryOfferScreen(
    orderId: state.pathParameters['orderId']!,
  ),
)
```

---

### Problema: "Simulator iOS não mostra notificações"

**Sintoma:** Tudo funciona no device, mas no simulador do Xcode não há push.

**Motivo:** **Simulador não suporta APNs.** Notificações push **só funcionam em device físico**.

**Solução:** Sempre testes em device iOS real (iPhone, iPad).

---

### Problema: "Ainda não funciona — preciso debugar"

**Passos de diagnóstico:**

1. **Confira logs do Flutter:**

```bash
flutter logs
```

Procure por erros relacionados a Firebase, FCM, ou permissões.

2. **Confira logs no Firebase Console:**
   - Vá para **Cloud Messaging > Recent messages**
   - Procure pela notificação que enviou
   - Verifique coluna **"Status"** — deve ser "Delivered" (iOS) ou "Sent" (Android)
   - Se houver error, copie e pesquise no docs do Firebase

3. **Teste payload direto via API:**

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/seu-projeto/messages:send \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "seu_fcm_token_aqui",
      "notification": {
        "title": "Teste",
        "body": "Debugando push"
      },
      "apns": {
        "payload": {
          "aps": {
            "sound": "default"
          }
        }
      }
    }
  }'
```

(Você precisa de um token FCM; copie do `flutter logs` ou do console app.)

4. **Verifique tokens registrados no backend:**

Se tiver acesso ao banco de dados, procure por registros na tabela `fcm_tokens` ou similar:

```sql
SELECT * FROM fcm_tokens WHERE user_id = 'seu_user_id' AND platform = 'ios';
```

Confirme que um token está registrado para seu device.

---

## Resumo Final

| Etapa | Arquivo/Recurso | O que fazer |
|-------|----------|-----------|
| **A** | Apple Developer Portal | Registrar App ID + criar chave APNs .p8 + anotar IDs |
| **B** | Firebase Console | Upload chave APNs + configurar Bundle ID |
| **C** | Xcode | Verificar Push Notifications + Background Modes ativas |
| **D** | Device iOS | Testar em 4 cenários (foreground, background, outro app, lock screen) |
| **E** | Logs + Firebase | Debugar se algo não funcionar |

**Você está pronto para:**
- ✅ Receber notificações push em background
- ✅ Som e vibração ativados
- ✅ Navegação automática para oferta ao tocar

**Próximas etapas:**
1. Implementar handlers em `lib/services/push_notification_service.dart` (se ainda não estiverem)
2. Registrar e renovar tokens FCM no backend
3. Enviar payloads com `type: delivery_offer` + `orderId`
4. Testar em production (Phase 2)

---

**Dúvidas?** Consulte:
- [`PUSH_BACKGROUND_SETUP.md`](../PUSH_BACKGROUND_SETUP.md) — cenários de teste completos
- [`PLANO_LOJA_VIRTUAL.md`](../../PLANO_LOJA_VIRTUAL.md) — arquitetura geral
- Firebase docs: https://firebase.google.com/docs/cloud-messaging/ios/certs
- Apple docs: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server
