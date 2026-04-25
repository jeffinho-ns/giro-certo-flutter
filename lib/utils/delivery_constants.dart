/// Regras de matching de corridas (alinhado a [giro-certo-api]/src/services/delivery.service.ts)
class DeliveryMatchRules {
  static const int maxKmBicycle = 3;
  static const int maxKmMotorcycle = 10;

  static String radiusMessage({required bool isBicycle}) {
    if (isBicycle) {
      return 'Pedidos até $maxKmBicycle km: o app só oferece corridas curtas compatíveis com bike.';
    }
    return 'Pedidos até $maxKmMotorcycle km: corresponde à regra de distância para entregas de moto.';
  }
}

class PreRideCheckItem {
  final String title;
  final String hint;
  const PreRideCheckItem({required this.title, required this.hint});
}

class PreRideChecklistBike {
  static const List<PreRideCheckItem> items = [
    PreRideCheckItem(
      title: 'Pneu e câmara',
      hint: 'Calibragem e sem cortes aparentes',
    ),
    PreRideCheckItem(
      title: 'Iluminação traseira',
      hint: 'Luz visível para trás',
    ),
    PreRideCheckItem(
      title: 'Capacete',
      hint: 'Obrigatório no trânsito',
    ),
    PreRideCheckItem(
      title: 'Água',
      hint: 'Hidratação em dias quentes',
    ),
  ];
}

class PreRideChecklistMoto {
  static const List<PreRideCheckItem> items = [
    PreRideCheckItem(
      title: 'Pneus e freios',
      hint: 'Conferir antes de rodar',
    ),
    PreRideCheckItem(
      title: 'Luzes e setas',
      hint: 'Visibilidade e segurança',
    ),
    PreRideCheckItem(
      title: 'Capacete',
      hint: 'EPI obrigatório',
    ),
    PreRideCheckItem(
      title: 'Documentação',
      hint: 'Habilitação e CRLV acessíveis se precisar',
    ),
  ];
}
