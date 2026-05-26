import '../models/bike.dart';
import '../models/maintenance.dart';
import '../models/vehicle_type.dart';
import 'api_service.dart';

/// Definição de um item recomendado de manutenção para um determinado tipo de
/// veículo. O ciclo (em km) define o intervalo recomendado entre trocas.
class MaintenanceItemDefinition {
  final String id;
  final String partName;
  final String category;
  final int cycleKm;
  final bool bicycleOnly;
  final bool motorcycleOnly;

  const MaintenanceItemDefinition({
    required this.id,
    required this.partName,
    required this.category,
    required this.cycleKm,
    this.bicycleOnly = false,
    this.motorcycleOnly = false,
  });

  bool applicableTo(AppVehicleType type) {
    if (bicycleOnly) return type == AppVehicleType.bicycle;
    if (motorcycleOnly) return type == AppVehicleType.motorcycle;
    return true;
  }
}

/// Cálculos e integração com a API para a manutenção real do veículo do usuário.
///
/// Estratégia:
/// 1. Tenta carregar os logs de manutenção da API (`/bikes/:id/maintenance`).
/// 2. Para cada item recomendado, procura o último log e calcula desgaste real
///    com base na quilometragem atual da bike.
/// 3. Para itens sem log, parte-se do princípio que estão "novos" desde o
///    cadastro da moto e calcula-se desgaste com base em `currentKm`.
/// 4. Em caso de falha de rede, devolve a lista calculada apenas com base em
///    `currentKm` (todos os itens partindo do zero).
class MaintenanceService {
  /// Itens padrão para motos.
  static const List<MaintenanceItemDefinition> _motorcycleItems = [
    MaintenanceItemDefinition(
      id: 'oil',
      partName: 'Óleo do Motor',
      category: 'Óleo',
      cycleKm: 5000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'oil_filter',
      partName: 'Filtro de Óleo',
      category: 'Filtros',
      cycleKm: 10000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'air_filter',
      partName: 'Filtro de Ar',
      category: 'Filtros',
      cycleKm: 15000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'tires',
      partName: 'Pneus Dianteiro e Traseiro',
      category: 'Pneus',
      cycleKm: 20000,
    ),
    MaintenanceItemDefinition(
      id: 'brake_pads',
      partName: 'Pastilhas de Travão',
      category: 'Travões',
      cycleKm: 12000,
    ),
    MaintenanceItemDefinition(
      id: 'brake_fluid',
      partName: 'Fluido de Travão',
      category: 'Travões',
      cycleKm: 20000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'chain',
      partName: 'Corrente e Coroa',
      category: 'Transmissão',
      cycleKm: 25000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'spark_plug',
      partName: 'Vela de Ignição',
      category: 'Motor',
      cycleKm: 15000,
      motorcycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'coolant',
      partName: 'Fluido de Arrefecimento',
      category: 'Motor',
      cycleKm: 40000,
      motorcycleOnly: true,
    ),
  ];

  /// Itens padrão para bicicletas (delivery em bike).
  static const List<MaintenanceItemDefinition> _bicycleItems = [
    MaintenanceItemDefinition(
      id: 'bike_chain',
      partName: 'Corrente',
      category: 'Transmissão',
      cycleKm: 2500,
      bicycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'bike_brake_pads',
      partName: 'Pastilhas de Travão',
      category: 'Travões',
      cycleKm: 1500,
      bicycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'bike_tires',
      partName: 'Pneus',
      category: 'Pneus',
      cycleKm: 5000,
      bicycleOnly: true,
    ),
    MaintenanceItemDefinition(
      id: 'bike_cables',
      partName: 'Cabos e Conduítes',
      category: 'Travões',
      cycleKm: 3000,
      bicycleOnly: true,
    ),
  ];

  static List<MaintenanceItemDefinition> definitionsFor(AppVehicleType type) {
    return type == AppVehicleType.bicycle ? _bicycleItems : _motorcycleItems;
  }

  /// Carrega manutenções calculadas para a bike, mesclando logs da API com
  /// definições padrão. Nunca lança: em caso de erro devolve apenas o cálculo
  /// local baseado em `currentKm`.
  static Future<List<Maintenance>> loadMaintenances(Bike bike) async {
    final defs = definitionsFor(bike.vehicleType);
    Map<String, _LastLog> lastLogByPart = const {};

    try {
      final logs = await ApiService.getBikeMaintenanceLogs(bike.id);
      lastLogByPart = _aggregateLastLogs(logs);
    } catch (_) {
      lastLogByPart = const {};
    }

    return defs
        .where((d) => d.applicableTo(bike.vehicleType))
        .map((def) {
          final last = _findLogForDefinition(def, lastLogByPart);
          final lastChangeKm = last?.lastChangeKm ?? 0;
          final cycle = last?.recommendedCycleKm ?? def.cycleKm;
          final used = (bike.currentKm - lastChangeKm).clamp(0, cycle);
          final wear = cycle <= 0 ? 0.0 : (used / cycle).clamp(0.0, 1.0);
          final status = _statusFor(wear);
          return Maintenance(
            id: def.id,
            partName: def.partName,
            category: def.category,
            lastChangeKm: lastChangeKm,
            recommendedChangeKm: cycle,
            currentKm: bike.currentKm,
            wearPercentage: wear,
            status: status,
          );
        })
        .toList();
  }

  /// Resumo geral: quantos itens estão críticos / em atenção / ok.
  static MaintenanceSummary buildSummary(List<Maintenance> items) {
    int ok = 0;
    int warning = 0;
    int critical = 0;
    for (final m in items) {
      switch (m.status) {
        case 'OK':
          ok++;
          break;
        case 'Atenção':
          warning++;
          break;
        case 'Crítico':
          critical++;
          break;
      }
    }
    return MaintenanceSummary(
      okCount: ok,
      warningCount: warning,
      criticalCount: critical,
      totalCount: items.length,
    );
  }

  /// Atualiza a quilometragem da bike na API e retorna a bike atualizada.
  static Future<Bike> updateBikeKm(Bike bike, int newKm) async {
    return ApiService.updateBike(bike.id, currentKm: newKm);
  }

  /// Registra manutenção feita: o item passa a ter `lastChangeKm = currentKm`.
  /// Em caso de falha, lança para que a UI possa exibir mensagem.
  static Future<void> registerMaintenance({
    required Bike bike,
    required Maintenance maintenance,
  }) async {
    await ApiService.createBikeMaintenanceLog(
      bike.id,
      partName: maintenance.partName,
      category: maintenance.category,
      lastChangeKm: bike.currentKm,
      recommendedChangeKm: maintenance.recommendedChangeKm,
      currentKm: bike.currentKm,
      status: 'OK',
    );
  }

  static String _statusFor(double wear) {
    if (wear >= 0.85) return 'Crítico';
    if (wear >= 0.6) return 'Atenção';
    return 'OK';
  }

  static Map<String, _LastLog> _aggregateLastLogs(
      List<Map<String, dynamic>> logs) {
    final out = <String, _LastLog>{};
    for (final raw in logs) {
      final partName = (raw['partName'] as String? ?? '').trim();
      if (partName.isEmpty) continue;
      final key = partName.toLowerCase();
      final lastChangeKm = (raw['lastChangeKm'] as num?)?.toInt() ?? 0;
      final cycle = (raw['recommendedChangeKm'] as num?)?.toInt() ?? 0;
      final updatedAt = raw['updatedAt'] ?? raw['createdAt'];
      DateTime? when;
      if (updatedAt is String && updatedAt.isNotEmpty) {
        when = DateTime.tryParse(updatedAt);
      }
      final candidate = _LastLog(
        partName: partName,
        lastChangeKm: lastChangeKm,
        recommendedCycleKm: cycle,
        updatedAt: when,
      );
      final existing = out[key];
      if (existing == null) {
        out[key] = candidate;
      } else {
        final existingTs = existing.updatedAt?.millisecondsSinceEpoch ?? 0;
        final candidateTs = candidate.updatedAt?.millisecondsSinceEpoch ?? 0;
        if (candidateTs >= existingTs &&
            candidate.lastChangeKm >= existing.lastChangeKm) {
          out[key] = candidate;
        }
      }
    }
    return out;
  }

  static _LastLog? _findLogForDefinition(
    MaintenanceItemDefinition def,
    Map<String, _LastLog> logsByPart,
  ) {
    final exact = logsByPart[def.partName.toLowerCase()];
    if (exact != null) return exact;
    for (final entry in logsByPart.entries) {
      if (entry.key.contains(def.partName.toLowerCase()) ||
          def.partName.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}

class _LastLog {
  final String partName;
  final int lastChangeKm;
  final int recommendedCycleKm;
  final DateTime? updatedAt;

  const _LastLog({
    required this.partName,
    required this.lastChangeKm,
    required this.recommendedCycleKm,
    this.updatedAt,
  });
}

class MaintenanceSummary {
  final int okCount;
  final int warningCount;
  final int criticalCount;
  final int totalCount;

  const MaintenanceSummary({
    required this.okCount,
    required this.warningCount,
    required this.criticalCount,
    required this.totalCount,
  });

  bool get hasCritical => criticalCount > 0;
  bool get hasWarning => warningCount > 0;
  double get overallHealth {
    if (totalCount == 0) return 1.0;
    final weighted = okCount * 1.0 + warningCount * 0.55 + criticalCount * 0.15;
    return weighted / totalCount;
  }
}
