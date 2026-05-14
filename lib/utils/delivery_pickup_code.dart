/// Normaliza o codigo de retirada informado pelo entregador.
class DeliveryPickupCode {
  DeliveryPickupCode._();

  static String normalize(String input) {
    return input.trim().toUpperCase();
  }

  static bool isValidFormat(String input) {
    return normalize(input).length >= 4;
  }
}
