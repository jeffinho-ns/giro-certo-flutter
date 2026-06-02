# Firebase - Giro Certo

Este projeto usa Firebase em dois contextos diferentes:

1. **Imagens (Storage via backend)**  
2. **Push notifications (FCM no app Flutter)**

---

## 1) Imagens (Storage via API)

O upload de imagens segue o mesmo modelo do agilizaiapp:

- Flutter envia multipart para a API com token autenticado
- API (`giro-certo-api`) salva no Firebase Storage via Admin SDK
- API devolve URL final para o app

### Fluxo

1. Flutter envia multipart POST para a API (com token de autenticação)
2. API (giro-certo-api) faz upload para Firebase Storage (Admin SDK)
3. API retorna a URL completa do Firebase
4. Flutter exibe com `Image.network(url)`

### Endpoints usados para imagem

- Posts: `POST /api/images/upload/post/:userId`
- Stories: `POST /api/images/upload/story/:userId`
- Perfil: `POST /api/users/me/upload-image` (type=avatar ou cover)

---

## 2) Push notifications (FCM)

Para notificacoes em background/tela bloqueada, o Flutter usa:

- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications`

### Arquivos necessarios no app

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### Referencias de implementacao

- `lib/services/push_notification_service.dart`
- `android/app/src/main/AndroidManifest.xml`
- `PUSH_BACKGROUND_SETUP.md` (guia completo)

Sem esses arquivos/plataforma configurada, o app roda normalmente, mas push FCM pode nao funcionar em background.
