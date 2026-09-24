/// Extrai mensagem legível de erros da API ao aceitar corrida.
String friendlyAcceptDeliveryError(Object error) {
  final raw = error.toString();
  // Preferir JSON {"error":"..."} quando existir.
  final jsonMatch = RegExp(r'\{[^{}]*"error"\s*:\s*"([^"]+)"').firstMatch(raw);
  if (jsonMatch != null) {
    return jsonMatch.group(1)!.replaceAll(r'\n', '\n');
  }
  var msg = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Erro\s+\d+:\s*'), '')
      .trim();
  if (msg.contains('manutenção crítica') || msg.contains('manutencao critica')) {
    return 'Bloqueado por manutenção crítica. Registe a manutenção na Garagem '
        '(marcar como feita) ou contacte o suporte para liberar.';
  }
  if (msg.contains('bloqueado para corridas')) {
    return 'Conta bloqueada para corridas. Contacte o suporte.';
  }
  return msg.isEmpty ? 'Não foi possível aceitar a corrida.' : msg;
}
