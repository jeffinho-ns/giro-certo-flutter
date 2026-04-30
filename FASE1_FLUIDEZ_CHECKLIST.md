# Fase 1 - Checklist de Fluidez (Flutter + Next)

## Objetivo
Validar eliminacao de flicker/reload agressivo no mapa durante operacao.

## Flutter - Delivery/Home
- [ ] Abrir tela de corridas e confirmar que o mapa nao some a cada update realtime.
- [ ] Aguardar pelo menos 2 ciclos de refresh periodico e confirmar ausencia de "pisca-pisca".
- [ ] Aceitar corrida e acompanhar status sem tela inteira virar loading.
- [ ] Na Home lojista, receber mudanca de status em tempo real sem overlay de loading bloqueante.
- [ ] Em rede ruim (latencia alta), verificar que erros de quote nao derrubam a tela.

## Next - Control Tower
- [ ] Abrir `/dashboard/control-tower` com varias corridas ativas.
- [ ] Confirmar que posicoes dos riders atualizam sem stutter intenso.
- [ ] Confirmar que filtros continuam responsivos durante eventos websocket.
- [ ] Validar que nao ha reconexao de socket a cada mudanca de lista.

## Criterio de aceite da Fase 1
- [ ] Nenhum refresh full-screen recorrente durante atualizacoes normais.
- [ ] Sem flicker perceptivel do mapa em operacao.
- [ ] Realtime consistente com menor carga visual (update incremental).
