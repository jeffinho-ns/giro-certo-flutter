# Panorama Geral - Giro Certo

## 📋 Visão Geral do Sistema

O Giro Certo é uma plataforma completa de delivery e gestão para motociclistas e lojistas, composta por três principais componentes:

1. **giro-certo-api** (Backend - Node.js/TypeScript)
2. **giro-certo-next** (Admin Panel - Next.js)
3. **giro-certo-flutter** (App Mobile - Flutter)
4. **giro-certo-db** (PostgreSQL - Render)

---

## 🗄️ Banco de Dados (PostgreSQL)

### Principais Tabelas

#### **User** (Usuários)
- **Tipos de Usuário**: 
  - `USER` (padrão) - Motociclista
  - `MODERATOR` - Moderador
  - `ADMIN` - Administrador
- **Campos Principais**:
  - `role`: UserRole (USER, MODERATOR, ADMIN)
  - `pilotProfile`: PilotProfile (FIM_DE_SEMANA, URBANO, TRABALHO, PISTA)
  - `hasVerifiedDocuments`: boolean
  - `verificationBadge`: boolean (Selo de Confiança)
  - `isOnline`: boolean
  - `currentLat`, `currentLng`: Localização em tempo real
  - `isSubscriber`: boolean (Premium/Standard)
  - `subscriptionType`: SubscriptionType

#### **Partner** (Lojistas/Parceiros)
- **Tipos**: `STORE` (Loja) ou `MECHANIC` (Mecânico)
- **Campos Principais**:
  - `cnpj`, `companyName`, `tradingName`: Dados empresariais
  - `maxServiceRadius`: Raio máximo de atendimento
  - `avgPreparationTime`: Tempo médio de preparo
  - `operatingHours`: Horários de funcionamento (JSON)
  - `isBlocked`: boolean (Bloqueado se inadimplente)
  - `payment`: Relacionamento com PartnerPayment

#### **DeliveryOrder** (Pedidos de Entrega)
- **Status**: `pending`, `accepted`, `inProgress`, `completed`, `cancelled`
- **Priority**: `low`, `normal`, `high`, `urgent`
- **Campos Principais**:
  - `storeId`: ID do parceiro
  - `riderId`: ID do motociclista que aceitou
  - `value`: Valor do pedido
  - `deliveryFee`: Taxa de entrega
  - `appCommission`: Comissão do app
  - `distance`, `estimatedTime`: Calculados pelo matching

#### **Bike** (Veículos)
- **vehicleType**: `MOTORCYCLE` ou `BICYCLE`
- **Campos Principais**:
  - `plate`: Placa (nullable para bicicletas)
  - `vehiclePhotoUrl`: Foto do veículo
  - `platePhotoUrl`: Foto da placa (apenas motos)

#### **CourierDocument** (Documentos do Motociclista)
- **documentType**: `RG`, `CNH`, `PASSPORT`
- **status**: `PENDING`, `UPLOADED`, `APPROVED`, `REJECTED`, `EXPIRED`

#### **Dispute** (Central de Disputas)
- **disputeType**: `DELIVERY_ISSUE`, `PAYMENT_ISSUE`, `RIDER_COMPLAINT`, `STORE_COMPLAINT`
- **status**: `OPEN`, `UNDER_REVIEW`, `RESOLVED`, `CLOSED`

#### **Alert** (Sistema de Alertas)
- **type**: `DOCUMENT_EXPIRING`, `MAINTENANCE_CRITICAL`, `PAYMENT_OVERDUE`
- **severity**: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

---

## 🔌 Backend API (giro-certo-api)

### Tecnologias
- **Node.js** + **TypeScript**
- **Express.js**
- **PostgreSQL** (driver nativo `pg`)
- **Socket.io** (WebSockets para tempo real)
- **JWT** (autenticação)
- **bcryptjs** (hash de senhas)

### Principais Endpoints

#### **Autenticação** (`/api/auth`)
- `POST /login` - Login
- `POST /register` - Registro
- `POST /logout` - Logout

#### **Delivery** (`/api/delivery`)
- `POST /orders` - Criar pedido (lojista)
- `GET /orders` - Listar pedidos (com filtros)
- `GET /orders/:id` - Detalhes do pedido
- `PUT /orders/:id/status` - Atualizar status
- `POST /orders/:id/accept` - Aceitar corrida (motociclista)
- `POST /orders/:id/complete` - Concluir corrida
- `GET /matching` - Buscar motociclistas compatíveis (matching inteligente)

#### **Partners** (`/api/partners`)
- `GET /` - Listar parceiros
- `GET /:id` - Detalhes do parceiro
- `POST /` - Criar parceiro (admin)
- `PUT /:id` - Atualizar parceiro
- `PUT /:id/block` - Bloquear/desbloquear

#### **Users** (`/api/users`)
- `GET /me` - Dados do usuário logado
- `PUT /me` - Atualizar perfil
- `PUT /:id/location` - Atualizar localização
- `GET /:id/documents` - Documentos do usuário

#### **Disputes** (`/api/disputes`)
- `GET /` - Listar disputas (com filtros)
- `POST /` - Criar disputa
- `PUT /:id/resolve` - Resolver disputa (admin)

#### **Alerts** (`/api/alerts`)
- `GET /` - Listar alertas
- `PUT /:id/read` - Marcar como lido
- `PUT /read-all` - Marcar todos como lidos

### Matching Inteligente

O algoritmo de matching considera:
1. **Tipo de veículo** (MOTORCYCLE vs BICYCLE)
2. **Distância** da corrida completa
3. **Status de manutenção** (bloqueia se crítico)
4. **Assinatura Premium** (prioriza assinantes)
5. **Proximidade** do motociclista
6. **Reputação** (verificationBadge)

---

## 🖥️ Admin Panel (giro-certo-next)

### Tecnologias
- **Next.js 14+** (App Router)
- **TypeScript**
- **Tailwind CSS**
- **Shadcn/UI**
- **TanStack Query**
- **Recharts** (gráficos)
- **Leaflet/React-Leaflet** (mapas)

### Principais Páginas

#### **Control Tower** (`/dashboard/control-tower`)
- Monitoramento em tempo real
- Filtros: tipo de veículo, status de verificação, status de pedidos
- Mapa interativo com motociclistas e pedidos
- Estatísticas em tempo real

#### **Partner Management** (`/dashboard/partners`)
- Lista de parceiros com busca e filtros
- Modal de criação/edição
- Abas: Informações Gerais, Status Financeiro, Configurações Operacionais
- Bloqueio/desbloqueio automático por inadimplência

#### **Dispute Center** (`/dashboard/disputes`)
- Dashboard com estatísticas
- Lista de disputas com filtros
- Modal de detalhes com mapa de geolocalização
- Resolução de disputas

#### **Reports** (`/dashboard/reports`)
- Parceiros Inadimplentes
- Comissões Pendentes
- Ranking de Confiabilidade dos Motociclistas
- Exportação CSV/JSON

#### **Alerts** (`/dashboard/alerts`)
- Dashboard com estatísticas
- Lista de alertas com filtros
- Marcar como lido (individual ou todos)
- Alertas críticos destacados

---

## 📱 App Mobile (giro-certo-flutter)

### Estrutura Atual

#### **Screens**
- `home/` - Home screen (atualmente genérica)
- `delivery/` - Delivery screen (atualmente com toggle manual)
- `garage/` - Garagem
- `maintenance/` - Manutenção
- `partners/` - Parceiros
- `ranking/` - Ranking
- `community/` - Comunidade
- `settings/` - Configurações
- `login/` - Autenticação e onboarding

#### **Models**
- `User` - Modelo básico (precisa expandir)
- `DeliveryOrder` - Pedidos
- `Partner` - Parceiros
- `Bike` - Veículos

#### **Providers**
- `AppStateProvider` - Estado global
- `ThemeProvider` - Tema
- `NavigationProvider` - Navegação
- `DrawerProvider` - Drawer

#### **Services**
- `MockDataService` - Dados mockados (precisa remover)
- `MotorcycleDataService` - Dados de motos
- `AppPreloadService` - Pré-carregamento

### Estado Atual vs Necessário

#### **Problemas Identificados**
1. ❌ `delivery_screen.dart` tem toggle manual entre motociclista/lojista
2. ❌ `User` model não tem `role` nem indicação se é `Partner`
3. ❌ Dados mockados (`MockDataService`) em vez de API real
4. ❌ `home_screen.dart` genérica, não diferencia por tipo de usuário
5. ❌ Falta serviço de API para integração com backend
6. ❌ Falta autenticação real (JWT)

#### **O Que Precisa Ser Feito**

##### **1. Autenticação e Tipos de Usuário**
- [ ] Adicionar `role` ao modelo `User`
- [ ] Adicionar campo `partnerId` (se for lojista)
- [ ] Implementar serviço de autenticação com JWT
- [ ] Armazenar token no `SharedPreferences`

##### **2. Separar Interfaces por Tipo de Usuário**
- [ ] **Home Screen**: 
  - Motociclista: Dashboard de manutenção, estatísticas, alertas
  - Lojista: Dashboard de pedidos, estatísticas de vendas, alertas financeiros
- [ ] **Delivery Screen**:
  - Motociclista: Mapa de corridas disponíveis, minhas corridas, histórico
  - Lojista: Criar pedidos, acompanhar pedidos, estatísticas
- [ ] **Navegação**: Menu diferente baseado no tipo de usuário

##### **3. Integração com API**
- [ ] Criar `ApiService` para comunicação com backend
- [ ] Remover `MockDataService`
- [ ] Implementar endpoints:
  - Autenticação
  - Delivery Orders
  - Partners
  - Users
  - Alerts
  - Disputes

##### **4. Funcionalidades Específicas**

**Para Motociclistas:**
- [ ] Aceitar corridas
- [ ] Atualizar localização em tempo real
- [ ] Ver histórico de corridas
- [ ] Ver ganhos e carteira
- [ ] Upload de documentos
- [ ] Verificação com selfie

**Para Lojistas:**
- [ ] Criar pedidos de entrega
- [ ] Acompanhar status dos pedidos
- [ ] Ver estatísticas de vendas
- [ ] Gerenciar horários de funcionamento
- [ ] Ver alertas financeiros
- [ ] Ver disputas relacionadas

---

## 🔄 Fluxo de Dados

### Login e Autenticação
```
Flutter App → POST /api/auth/login → Backend
Backend → JWT Token → Flutter App
Flutter App → Armazena token → Usa em todas requisições
```

### Criar Pedido (Lojista)
```
Lojista → Criar pedido no app → POST /api/delivery/orders
Backend → Matching inteligente → Notifica motociclistas via Socket.io
Motociclistas → Veem pedido disponível → Aceitam corrida
```

### Aceitar Corrida (Motociclista)
```
Motociclista → Aceita corrida → POST /api/delivery/orders/:id/accept
Backend → Atualiza status → Notifica lojista via Socket.io
Lojista → Vê status atualizado
```

### Atualização de Localização
```
Motociclista → Atualiza localização → PUT /api/users/:id/location
Backend → Atualiza no banco → Disponibiliza para matching
```

---

## 📝 Próximos Passos

### Fase 1: Estrutura Base
1. ✅ Criar documento de panorama geral
2. [ ] Atualizar modelo `User` com `role` e `partnerId`
3. [ ] Criar `ApiService` base
4. [ ] Implementar autenticação com JWT

### Fase 2: Separar Interfaces
1. [ ] Refatorar `home_screen.dart` para diferenciar por tipo de usuário
2. [ ] Refatorar `delivery_screen.dart` para remover toggle manual
3. [ ] Criar navegação condicional baseada no tipo de usuário

### Fase 3: Integração com API
1. [ ] Remover `MockDataService`
2. [ ] Implementar endpoints de Delivery
3. [ ] Implementar endpoints de Partners
4. [ ] Implementar endpoints de Users
5. [ ] Implementar WebSocket para atualizações em tempo real

### Fase 4: Funcionalidades Específicas
1. [ ] Upload de documentos (motociclista)
2. [ ] Verificação com selfie (motociclista)
3. [ ] Criação de pedidos (lojista)
4. [ ] Acompanhamento de pedidos (lojista)
5. [ ] Sistema de alertas
6. [ ] Sistema de disputas

---

## 🔗 Links Úteis

- **API Base URL**: `https://giro-certo-api.onrender.com`
- **Admin Panel**: `https://giro-certo-next.vercel.app` (ou similar)
- **Database**: PostgreSQL no Render

---

## 📚 Documentação Adicional

- `giro-certo-api/PLANO_IMPLEMENTACAO.md` - Plano completo de implementação
- `giro-certo-api/FASE*_IMPLEMENTADA.md` - Documentação de cada fase
- `giro-certo-api/README_ROLES.md` - Sistema de roles e permissões
