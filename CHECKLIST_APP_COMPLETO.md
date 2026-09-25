# Giro Certo - Checklist Completo de Fluxos

Este checklist cobre os fluxos principais do app Flutter (`giro-certo-flutter`) para validacao funcional e QA manual.

## 1) Autenticacao e onboarding

- [ ] Splash abre e avanca por gesto
- [ ] Login com email/senha
- [ ] Login com biometria (quando credenciais salvas)
- [ ] Registro de nova conta
- [ ] Retomada de onboarding interrompido
- [ ] Logout e retorno ao fluxo inicial

## 2) Tipos de cadastro/perfil

- [ ] Rider `Casual`
- [ ] Rider `Diario`
- [ ] Rider `Racing`
- [ ] Delivery moto
- [ ] Delivery bike (somente perfil Delivery)
- [ ] Lojista (conta criada/vinculada no backend)

## 3) Fluxo rider comum (Casual/Diario/Racing)

- [ ] Home social com feed e stories
- [ ] Criar post (texto e imagem)
- [ ] Curtir e comentar post
- [ ] Criar story
- [ ] Buscar usuarios
- [ ] Follow request (enviar/aceitar/rejeitar)
- [ ] Abrir chat particular/comunidade
- [ ] Acessar notificacoes

## 4) Fluxo Delivery (moto e bike)

- [ ] Cadastro delivery com documentos obrigatorios
- [ ] Status de moderacao: `PENDING`, `UNDER_REVIEW`, `APPROVED`, `REJECTED`
- [ ] Alternar online/offline
- [ ] Receber oferta de corrida
- [ ] Aceitar/recusar corrida
- [ ] Navegacao de corrida (coleta -> entrega)
- [ ] Codigo de retirada
- [ ] PIN de comprovacao na entrega
- [ ] Historico de corridas

## 5) Fluxo Lojista

- [ ] Dashboard de pedidos
- [ ] Criar novo pedido
- [ ] Cotacao de entrega
- [ ] Dispatch para entregadores
- [ ] Acompanhar status em tempo real
- [ ] Ajustes de pagamento e repasse

## 6) Modulos de apoio

- [ ] Garagem (dados da moto/bike)
- [ ] Manutencao (registros e alertas)
- [ ] Rotas
- [ ] Parceiros
- [ ] Eventos e comunidades
- [ ] Conquistas
- [ ] Configuracoes (tema/perfil)

## 7) Realtime e notificacoes

- [ ] Socket conecta apos login
- [ ] Mensagem de chat recebida em tempo real
- [ ] Badge de notificacao atualiza
- [ ] Notificacao com app em foreground
- [ ] Notificacao com app em background
- [ ] Notificacao com tela bloqueada

## 8) Painel admin (`giro-certo-next`) - validacao cruzada

- [ ] Usuario delivery aparece com tipo correto no dashboard de usuarios
- [ ] Registro delivery aparece na fila de aprovacao
- [ ] Aprovar/rejeitar cadastro com refletor no app
- [ ] Torre de controle e pedidos atualizam em tempo real
- [ ] Financeiro, parceiros e disputas carregam dados

## 9) Casos de borda recomendados

- [ ] Falha de rede durante login/onboarding
- [ ] Token expirado (relogin)
- [ ] Cadastro delivery incompleto (validacoes de documento)
- [ ] Corrida aceita por outro rider (conflito)
- [ ] App retomado do background durante corrida ativa

