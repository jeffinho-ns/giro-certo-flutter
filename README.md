# Giro Certo

Comunidade para motociclistas com controlo de manutenção baseado em quilometragem e ranking de peças recomendadas pela comunidade.

## Documentação

- 📋 **[PLANO_LOJA_VIRTUAL.md](PLANO_LOJA_VIRTUAL.md)** — Arquitetura geral da feature (Leia primeiro!)
- 📋 **[AGENTS.md](AGENTS.md)** — Instruções para desenvolvedores/agentes IA
- 📱 **[PUSH_BACKGROUND_SETUP.md](PUSH_BACKGROUND_SETUP.md)** — Configuração de notificações push em background
- 📱 **[docs/FASE1_IOS_PUSH_SETUP.md](docs/FASE1_IOS_PUSH_SETUP.md)** — Guia manual de iOS Push (APNs, Firebase, Xcode)
- 🚀 **[docs/PILOTO_BUILD.md](docs/PILOTO_BUILD.md)** — Checklist para build de produção
- 🎯 **[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)** — Verificações antes de release

## Estrutura do Projeto

- `lib/models/`: Modelos de dados
- `lib/screens/`: Ecrãs do aplicativo
- `lib/widgets/`: Componentes reutilizáveis
- `lib/utils/`: Constantes e temas
- `lib/services/`: Serviços de dados e API
- `ios/`: Configuração iOS (Xcode workspace)
- `android/`: Configuração Android (Gradle)

## Executar o Projeto

```bash
flutter pub get
flutter run
```
