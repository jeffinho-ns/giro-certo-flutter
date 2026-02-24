# Imagens - Giro Certo (igual ao agilizaiapp)

O Flutter **não usa Firebase SDK**. Igual ao agilizaiapp: envia imagens para a API, a API faz upload para Firebase Storage.

## Fluxo (como no agilizaiapp)

1. Flutter envia multipart POST para a API (com token de autenticação)
2. API (giro-certo-api) faz upload para Firebase Storage (Admin SDK)
3. API retorna a URL completa do Firebase
4. Flutter exibe com `Image.network(url)`

## Endpoints da API

- Posts: `POST /api/images/upload/post/:userId`
- Stories: `POST /api/images/upload/story/:userId`
- Perfil: `POST /api/users/me/upload-image` (type=avatar ou cover)

## Configuração Firebase

O Firebase é configurado apenas na **API** (giro-certo-api). Ver `giro-certo-api/FIREBASE_IMAGENS.md`.
