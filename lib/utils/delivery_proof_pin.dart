/// Normaliza o PIN informado pelo entregador na prova de entrega.
class DeliveryProofPin {
  DeliveryProofPin._();

  static const int length = 4;

  static String normalize(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValidFormat(String input) {
    return normalize(input).length == length;
  }
}
