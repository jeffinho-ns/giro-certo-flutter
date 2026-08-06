/// Opção/variação escolhida em um item do pedido da loja virtual (snapshot).
class StoreOrderSelectedOption {
  final String groupName;
  final String optionName;
  final double priceDelta;

  const StoreOrderSelectedOption({
    required this.groupName,
    required this.optionName,
    required this.priceDelta,
  });

  factory StoreOrderSelectedOption.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return StoreOrderSelectedOption(
      groupName: (json['groupName'] ?? '').toString(),
      optionName: (json['optionName'] ?? '').toString(),
      priceDelta: toDouble(json['priceDelta']),
    );
  }
}

/// Item do pedido vindo da loja virtual (cardápio com variações).
/// Exibido ao lojista quando o DeliveryOrder originou de um StoreOrder.
class StoreOrderItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final List<StoreOrderSelectedOption> selectedOptions;
  final String? notes;

  const StoreOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.selectedOptions = const [],
    this.notes,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawOptions = json['selectedOptions'];
    final options = <StoreOrderSelectedOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          options.add(StoreOrderSelectedOption.fromJson(o));
        } else if (o is Map) {
          options.add(
            StoreOrderSelectedOption.fromJson(Map<String, dynamic>.from(o)),
          );
        }
      }
    }

    final notes = json['notes']?.toString();

    return StoreOrderItem(
      name: (json['name'] ?? '').toString(),
      quantity: toInt(json['quantity']),
      unitPrice: toDouble(json['unitPrice']),
      lineTotal: toDouble(json['lineTotal']),
      selectedOptions: options,
      notes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }

  /// Resumo curto das variações para exibição em uma linha.
  String get optionsSummary =>
      selectedOptions.map((o) => o.optionName).where((s) => s.isNotEmpty).join(', ');
}
