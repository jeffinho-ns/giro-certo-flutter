# Ideias: Rede social mais rica e integração Delivery + Motociclistas

Documento de sugestões para enriquecer a rede social do Giro Certo e integrar melhor **motociclistas de delivery** e **motociclistas “normais”** (lazer/commute), refletindo em várias partes da app.

---

## 1. Badge no ícone e notificações (implementado)

- **Badge no ícone (Android/iOS):** contagem de não lidas no ícone da app (`app_badge_plus` + `NotificationsCountProvider`).
- **Ecrã de notificações:** filtros (Não lidas, Todas, Pedidos de amizade), marcar como lida ao clicar (remove da lista e atualiza o badge), botão “Marcar todas como lidas”, botão “Excluir” por item e swipe para excluir.

---

## 2. Rede social mais rica

### 2.1 Perfil e identidade

- **Tipo de piloto visível no perfil:** exibir “Delivery” ou “Lazer” (e no futuro “Lojista”) no perfil, na lista de seguidores e em posts.
- **Badge/emblema no post:** pequeno ícone ou texto “Entregador” / “Piloto” ao lado do nome no card do post.
- **Bio e moto:** permitir “Moto de trabalho” e “Moto de lazer” no perfil; na social mostrar a que fizer mais sentido (ex.: “Trabalho: Honda PCX | Lazer: CB 500”).

### 2.2 Feed e conteúdo

- **Filtros no feed:** “Todos”, “Só entregadores”, “Só pilotos lazer”, “Comunidades que sigo”, “Eventos”.
- **Hashtags e temas:** ex. `#delivery`, `#estrada`, `#manutencao`, `#evento`; filtrar feed por hashtag.
- **Tipos de post:** além de texto/foto, suportar “Dica de manutenção”, “Rota do dia”, “Entrega concluída” (com opção de partilha automática só para amigos).
- **Reações:** além de like, reações rápidas (ex.: “Boa rota”, “Boa dica”) que possam ser usadas em analytics/ranking.

### 2.3 Comunidades e grupos

- **Comunidades por tipo:** “Entregadores da cidade X”, “Pilotos fim de semana”, “Marca Y”, “Manutenção em casa”.
- **Grupos por zona/rota:** ex. “Zona Norte – entregas” para combinarem paragens e dicas.
- **Eventos na social:** criar evento (data, local, descrição), convidar comunidade; aparecer no feed e no mapa (ver secção mapa).

### 2.4 Stories e momentos

- **Story “Em entrega”:** template opcional para entregadores (ex.: “Entrega X concluída”) com rota ou zona (sem dados sensíveis).
- **Story “Rota do dia”:** traço no mapa (opcional) para pilotos partilharem rotas de lazer.
- **Stories por comunidade:** stories de comunidade (ex.: evento) em separado do feed pessoal.

---

## 3. Integração Delivery ↔ Motociclistas “normais”

### 3.1 Visibilidade no mapa

- **Camada “Pilotos perto de mim” (opcional):** quem permitir aparece no mapa como “piloto por perto” (sem detalhes de entrega); útil para encontros e sensação de comunidade.
- **Camada “Entregadores ativos” (opcional):** para lojistas ou outros entregadores verem “quem está na rua” na zona (sem expor pedidos).
- **Pontos de interesse partilhados:** mecânicos, paragens, postos de combustível recomendados por pilotos ou entregadores, com pequeno comentário; visíveis no mapa e na social (ex. post “Mecânico fixe aqui”).

### 3.2 Ranking e gamificação

- **Ranking unificado com filtro:** mesmo ranking (km, rotas, etc.) com filtro “Todos”, “Só delivery”, “Só lazer”.
- **Conquistas:** “Primeira entrega”, “100 entregas”, “Rota partilhada”, “Dica de manutenção útil” (likes/comentários); mostrar no perfil e na social.
- **Leaderboard por comunidade:** ex. “Entregadores Lisboa” ou “Pilotos fim de semana”.

### 3.3 Chat e rede

- **Chat por comunidade:** além de conversas 1‑a‑1, canal de grupo por comunidade (ex. “Entregadores Zona Norte”).
- **Pedidos de amizade entre tipos:** entregador pode seguir piloto lazer e vice‑versa; feed e notificações unificados.
- **Sugestões “Quem seguir”:** “Outros entregadores na tua zona”, “Pilotos com a mesma moto”, “Membros da comunidade X”.

---

## 4. Refletir a social noutras partes da app

### 4.1 Home / Mapa

- **Resumo social no hub:** “3 novos posts na tua comunidade”, “João partilhou uma rota”; toque abre a social no tab certo.
- **Eventos no mapa:** eventos criados na social com local aparecem como pins; toque abre detalhe e link para a publicação.
- **Notificações de rede no mapa:** ex. “Maria está perto” (se ambos ativaram “mostrar no mapa”) ou “Novo evento na tua zona”.

### 4.2 Garagem e manutenção

- **Posts “Dica de manutenção” no feed:** link para peça ou intervenção na garagem (ex. “Trocar óleo” com link para o registo na garagem).
- **Partilha da garagem (opcional):** “Partilhar resumo da minha moto” como post (km, próxima revisão) sem dados sensíveis.
- **Comunidade “Manutenção em casa”:** conteúdo e dicas refletidas na secção de ajuda ou na garagem (“Dicas da comunidade”).

### 4.3 Perfil e sidebars

- **Perfil universal:** já existe; enriquecer com “Entregador desde…”, “Moto de trabalho”, “Comunidades”, “Conquistas”.
- **Sidebar notificações:** já com contagem e filtros; no futuro: “Notificações de entrega” (ex. novo pedido) vs “Social” (likes, follows, comentários).
- **Atalhos:** “Ver feed”, “Minhas comunidades”, “Eventos” acessíveis a partir do drawer/menu.

### 4.4 Lojista (parceiro)

- **Feed “Minha loja”:** posts ou stories que mencionem a loja (hashtag ou tag); opcionalmente permitir ao lojista publicar ofertas que aparecem no feed da comunidade.
- **Ranking de entregadores:** lojista vê ranking (anonimizado ou por acordo) dos entregadores que mais usam a loja, para reconhecimento interno.
- **Notificações:** “Pedido novo” (já) + “Novo seguidor na comunidade da loja” ou “Alguém mencionou a loja”.

---

## 5. Resumo de prioridades sugeridas

| Prioridade | Ideia | Impacto |
|------------|--------|--------|
| Alta | Tipo de piloto (Delivery/Lazer) no perfil e no post | Identidade e confiança |
| Alta | Filtros no feed (Todos / Só delivery / Só lazer) | Conteúdo relevante |
| Alta | Comunidades por tipo (entregadores, lazer, zona) | Rede mais útil |
| Média | Hashtags e filtro por hashtag no feed | Descoberta e temas |
| Média | Eventos na social + pins no mapa | Encontros e rotas |
| Média | Conquistas e badges no perfil | Engajamento |
| Média | Chat por comunidade | Coordenação e apoio |
| Baixa | Camada “Pilotos perto de mim” no mapa | Sensação de comunidade |
| Baixa | Story “Em entrega” / “Rota do dia” | Conteúdo específico |

---

## 6. Tabela de prioridades (implementação)

| Prioridade | Ideia | Estado |
|------------|--------|--------|
| Alta | Tipo de piloto (Delivery/Lazer) no perfil e no post | ✅ Implementado (badge no PostCard e no perfil) |
| Alta | Filtros no feed (Todos / Só delivery / Só lazer) | ✅ Implementado (chips + provider) |
| Alta | Tipos de post (Dica, Rota, Entrega concluída) | ✅ Implementado (create post + PostCard) |
| Alta | Hashtags e filtro por hashtag no feed | ✅ Implementado (extração no post + chips clicáveis + filtro) |
| Alta | Reações (Boa rota, Boa dica) | ✅ Implementado (PostCard + API setPostReaction) |
| Alta | Conquistas no perfil | ✅ Implementado (secção Conquistas + API getAchievements) |
| Média | Comunidades por tipo/zona | ✅ Modelo Community.type e .zone; API pode filtrar |
| Média | Eventos na social | ✅ Ecrã EventsScreen + API getEvents; pins no mapa dependem do mapa |
| Média | Story template (Em entrega, Rota do dia) | ✅ Modelo Story.template; UI do create story pode enviar template |
| Média | Visibilidade no mapa (pilotos/entregadores) | 🔧 API getMapVisibility, updateMapVisibility, getMapNearbyUsers; falta UI no mapa |
| Média | Pontos de interesse partilhados | 🔧 API getPointsOfInterest; falta camada no mapa |
| Média | Ranking unificado com filtro | 🔧 API getDeliveryRanking; falta filtro “Pilotos” na UI de ranking |
| Média | Sugestões “quem seguir” | 🔧 API getSuggestedFollows; falta widget na social |
| Média | Chat por comunidade | 🔧 API getCommunityChannels; falta UI de canais |
| Baixa | Resumo social na home/mapa | Pendente |
| Baixa | Garagem ↔ dicas no feed | Pendente |
| Baixa | Lojista: feed “minha loja”, ranking entregadores | 🔧 API getPartnerFeed, getDeliveryRanking; falta secção na PartnerHomeScreen |

## 7. Notas técnicas

- **Badge no ícone (Android):** em alguns fabricantes (Samsung, Xiaomi, etc.) pode ser necessário configurar permissões no `AndroidManifest.xml` conforme a documentação do `app_badge_plus`.
- **API:** vários endpoints foram adicionados em `api_service.dart` (getEvents, getAchievements, getSuggestedFollows, getMapVisibility, updateMapVisibility, getPointsOfInterest, getMapNearbyUsers, getCommunityChannels, getPartnerFeed, getDeliveryRanking, setPostReaction). Se o backend ainda não os implementar, as chamadas devolvem listas vazias ou null sem quebrar a app.
- **Privacidade:** opções “mostrar no mapa” e “mostrar que sou entregador” devem ser explícitas e desligáveis pelo utilizador; quando a UI do mapa estiver ligada a estes endpoints, convém pedir confirmação.
- **Modelos:** foram criados ou estendidos: `PostType`, `ReactionType`, `CommunityType`, `StoryTemplate`, `SocialEvent`, `Achievement`, `PointOfInterest`; `Post` com `postType`, `hashtags`, `reactions`, `userPilotProfile`; `Community` com `type` e `zone`; `Story` com `template`; `User` com getters `isDeliveryPilot` e `pilotTypeLabel`.

Este documento pode ser usado como backlog de produto e para alinhar com a API e o design.
