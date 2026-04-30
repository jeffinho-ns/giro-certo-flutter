# Fase 2/3 - Progresso de Offline e Fluidez

## Entregue nesta etapa

- Manifesto de regioes offline na API (`GET /api/maps/offline-regions`).
- Configuracao via ambiente para URLs reais de pacote:
  - `OFFLINE_MAP_SP_CAPITAL_URL`
  - `OFFLINE_MAP_CAMPINAS_URL`
  - `OFFLINE_MAP_RIO_CAPITAL_URL`
  - `OFFLINE_MAP_REGIONS_JSON` (override completo)
- Cliente Flutter para listar regioes offline.
- Servico Flutter para download com progresso e persistencia local.
- Tela de configuracoes com entrada para "Mapas Offline".
- Tela dedicada para listar e baixar pacotes por regiao.

## Resultado pratico

- O app ja suporta fluxo de download sob demanda por regiao.
- Sem URL configurada, o botao fica desabilitado e informa indisponibilidade.
- Com URL configurada no backend, o usuario ja consegue baixar e atualizar pacote.

## Proximo passo recomendado (fase seguinte)

- Integrar render offline real no `DeliveryScreen` com `flutter_map`:
  - online: tiles remotos;
  - offline: leitura de tiles/pack local.
- Validar fallback automatico por conectividade (online/offline).
- Implementar limpeza de cache por versao (invalida pack antigo).
