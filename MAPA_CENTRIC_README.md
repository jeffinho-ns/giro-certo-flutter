# Reestruturação Map-Centric – Giro Certo

## Resumo das alterações

### 1. HomeScreen (Hub de Mapa)
- **Layout**: `Stack` com `GoogleMap` como fundo dinâmico.
- **Corridas**: Ao aceitar uma corrida (pipcar), a rota é desenhada com `Polyline` e a câmera é atualizada (Google Directions API).
- **Mensagens Rápidas**: Card flutuante com glassmorphism (blur) no canto inferior esquerdo, acima do menu, com as últimas notificações/alertas.

### 2. ModernHeader (Topo)
- **Esquerda**: Foto e saudação ao piloto (inalterado).
- **Direita**: Display com **[Hora atual] | [KM da moto]** (de `appState.bike.currentKm`), em container escuro com bordas arredondadas e opacidade. Ícone de notificação removido.

### 3. Coluna FAB (Direita)
- Modo Drive (Racing Orange, em destaque).
- Notificações (sino).
- Zona Quente (heatmap no mapa).
- Filtro (Mecânicos, Auto Peças, Eventos).
- Re-center (focar na posição GPS).

### 4. Navegação (5 ícones)
- **Chat** → CommunityScreen  
- **Eventos** → RankingScreen  
- **Menu** (central) → Abre modal com grid: Manutenção Detalhada, Parceiros e Mecânicos, Corridas, Foto Sport, Rotas, Help, News, Modo Drive, Veículos, Comunidades, Pesquisar, Amigos.  
- **Momentos** → Placeholder (MomentosScreen).  
- **Garagem** → GarageScreen  

### 5. Lógica de interação
- Pipcar: modal flutuante ao centro com dados da entrega e valor; ao aceitar, rota calculada via Google Directions e desenhada no mapa.
- Elementos flutuantes com `BoxShadow` para legibilidade sobre o mapa.
- Estado e integração com giro-certo-api via `AppStateProvider` e `ApiService`.

### 6. Mapa dinâmico e animado
- **Animação de câmera**: transições com duração (800 ms para recentrar/rota, 300 ms para zoom).
- **Controles flutuantes** (canto superior esquerdo): Zoom +, Zoom −, tipo de mapa (Normal / Satélite / Híbrido).
- **Tipos de mapa**: Normal, Satélite, Híbrido (GoogleMap `mapType`).
- **Gestos**: rotação, inclinação (tilt), scroll e zoom por gestos; bússola ativada.
- **Re-center** (coluna FAB direita): foca na posição GPS com animação suave.

---

## Configuração da API do Google Maps

**A mesma API key do projeto Agilizaiapp está configurada** em:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
- `lib/services/map_service.dart`

Se precisar de uma chave própria, substitua `AIzaSyCYujVw1ifZiGAYCrp30RD4yiB5DFcrj4k` nos três ficheiros. Ative no Google Cloud: **Maps SDK for Android**, **Maps SDK for iOS** e **Directions API**.

---

## Esquema de cores (mantido)
- Racing Orange, Neon Green, Status Ok/Warning/Critical, Alert Red, etc., conforme `lib/utils/colors.dart`.
