# 🏪 Mudanças: Home Específica para Lojistas

## ✅ Implementações Realizadas

### 1. Home Específica para Lojistas

**Arquivo:** `lib/screens/home/home_screen.dart`

**Mudanças:**
- ✅ Convertido de `StatelessWidget` para `StatefulWidget` para gerenciar estado
- ✅ Criada função `_loadPartnerData()` que busca dados reais da API
- ✅ Home do lojista agora mostra:
  - **Botão grande "Novo Pedido"** - Abre modal para criar pedido
  - **Cards de resumo** - Total de pedidos, pendentes, concluídos (dados reais)
  - **Card de Receita** - Receita total do dia (calculada dos pedidos concluídos)
  - **Seção "Em Andamento"** - Lista de pedidos ativos para rastrear
  - **Seção "Aguardando Aprovação"** - Lista de pedidos pendentes
- ✅ Removidos todos os mocks da home do lojista
- ✅ Integração completa com `ApiService.getDeliveryOrders(storeId: ...)`

### 2. Menu Lateral (Profile Sidebar)

**Arquivo:** `lib/screens/sidebars/profile_sidebar.dart`

**Mudanças:**
- ✅ Convertido para `StatefulWidget` para buscar dados da API
- ✅ Adicionada função `_loadUserData()` que busca usuário atual via `ApiService.getCurrentUser()`
- ✅ **Ocultada seção "Minha Moto"** quando for lojista
- ✅ **Adicionada seção "Minha Loja"** para lojistas com:
  - Email do lojista
  - Status de verificação
- ✅ **Ocultado item "Minha Garagem"** do menu quando for lojista
- ✅ Implementado logout real que:
  - Chama `ApiService.logout()`
  - Limpa estado do `AppStateProvider`
  - Navega para tela de login

### 3. Notificações

**Arquivo:** `lib/screens/sidebars/notifications_sidebar.dart`

**Mudanças:**
- ✅ Convertido para `StatefulWidget`
- ✅ Removidos todos os mocks
- ✅ Integração com `ApiService.getAlerts()` (endpoint `/api/alerts/me`)
- ✅ Função `_loadNotifications()` busca alertas reais da API
- ✅ Função `_markAsRead()` marca notificações como lidas
- ✅ Mapeamento de tipos de alerta (DOCUMENT_EXPIRING, MAINTENANCE_CRITICAL, PAYMENT_OVERDUE)
- ✅ Atualização automática após marcar como lida

### 4. Menu de Navegação (FloatingBottomNav)

**Arquivo:** `lib/widgets/floating_bottom_nav.dart`

**Mudanças:**
- ✅ **Menu adaptativo** baseado no tipo de usuário:
  - **Motociclistas:** Home, Manutenção, Parceiros, Ranking, Comunidade, Delivery
  - **Lojistas:** Home, Pedidos (apenas 2 itens)
- ✅ Lógica de posicionamento ajustada para diferentes quantidades de itens
- ✅ Índices mapeados corretamente (0 = Home, 5 = Delivery/Pedidos)

### 5. Navegação Principal

**Arquivo:** `lib/screens/main_navigation.dart`

**Mudanças:**
- ✅ Função `_getScreens()` que retorna telas diferentes baseado no tipo de usuário
- ✅ Para lojistas, telas de motociclista são substituídas por `SizedBox.shrink()` (ocultas)
- ✅ Lógica de ocultar menu ajustada para lojistas

### 6. Tela de Delivery

**Arquivo:** `lib/screens/delivery/delivery_screen.dart`

**Mudanças:**
- ✅ Removidos mocks da função `_loadOrders()`
- ✅ Integração completa com API:
  - Motociclistas: busca todos os pedidos e seus próprios pedidos
  - Lojistas: busca apenas pedidos do seu `partnerId`
- ✅ Removida função `_loadMockOrders()` (mantida apenas como referência)
- ✅ Removido uso de `getHotDeliveryZones()` (substituído por lista vazia)

### 7. API Service

**Arquivo:** `lib/services/api_service.dart`

**Mudanças:**
- ✅ Adicionado método `getAlerts()` - Busca alertas do usuário via `/api/alerts/me`
- ✅ Adicionado método `markAlertAsRead()` - Marca alerta como lido
- ✅ Adicionado método `markAllAlertsAsRead()` - Marca todos como lidos

### 8. Backend - Endpoints de Alertas

**Arquivo:** `giro-certo-api/src/routes/alerts.routes.ts`

**Mudanças:**
- ✅ Criado endpoint `GET /api/alerts/me` - Para usuários buscarem seus próprios alertas
- ✅ Endpoint `PUT /api/alerts/:alertId/read` - Agora permite usuários comuns marcarem seus próprios alertas
- ✅ Endpoint `PUT /api/alerts/read-all` - Agora permite usuários comuns marcarem todos seus alertas
- ✅ Validação de permissão: usuários só podem marcar alertas que pertencem a eles

## 🎯 Funcionalidades para Lojistas

### Home do Lojista:
1. **Criar Novo Pedido** - Botão grande e destacado
2. **Rastrear Corridas** - Lista de pedidos em andamento com informações do entregador
3. **Aprovar Pedidos** - Lista de pedidos pendentes
4. **Estatísticas** - Total de pedidos, pendentes, concluídos, receita do dia

### Menu Lateral:
1. **Dados da Conta** - Buscados da API
2. **Informações da Loja** - Email, status de verificação
3. **Notificações** - Alertas reais da API
4. **Logout** - Funcional

### Navegação:
1. **Apenas 2 itens no menu** - Home e Pedidos
2. **Todas as telas de motociclista ocultas**

## 📋 Arquivos Modificados

### Flutter:
1. `lib/screens/home/home_screen.dart` - Home específica para lojistas
2. `lib/screens/sidebars/profile_sidebar.dart` - Menu lateral com dados da API
3. `lib/screens/sidebars/notifications_sidebar.dart` - Notificações da API
4. `lib/widgets/floating_bottom_nav.dart` - Menu adaptativo
5. `lib/screens/main_navigation.dart` - Navegação condicional
6. `lib/screens/delivery/delivery_screen.dart` - Remoção de mocks
7. `lib/services/api_service.dart` - Métodos de alertas
8. `lib/screens/delivery/delivery_detail_modal.dart` - Callback onOrderUpdated

### Backend:
1. `src/routes/alerts.routes.ts` - Endpoint `/me` e permissões ajustadas
2. `src/services/alert.service.ts` - Método `getAlertById()`

## 🚀 Próximos Passos

1. ✅ Home específica para lojistas - **COMPLETO**
2. ✅ Remoção de mocks - **COMPLETO**
3. ✅ Integração com API - **COMPLETO**
4. ✅ Menu lateral com dados reais - **COMPLETO**
5. ✅ Notificações da API - **COMPLETO**
6. ✅ Ocultar funcionalidades de motociclista - **COMPLETO**

## 📝 Notas Técnicas

- A home do lojista recarrega automaticamente após criar um pedido
- As notificações são atualizadas automaticamente após marcar como lida
- O menu lateral busca dados do usuário ao abrir
- Todos os dados são buscados da API real, sem mocks
- A diferenciação entre lojista e motociclista é feita via `user.isPartner` e `user.isRider`

## ⚠️ Observações

- A tela de delivery ainda precisa de ajustes finais para lojistas (filtros, ações específicas)
- Hot zones no mapa foram removidas (precisa implementar via API quando disponível)
- Alguns avisos de deprecação (`withOpacity`) podem ser corrigidos posteriormente
