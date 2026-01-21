import 'delivery_order.dart';

/// Estatísticas e ganhos do entregador
class RiderStats {
  // Ganhos financeiros
  final double todayEarnings; // Ganhos hoje
  final double weekEarnings; // Ganhos na semana
  final double monthEarnings; // Ganhos no mês
  final double totalEarnings; // Total geral
  
  // Estatísticas de corridas
  final int todayDeliveries; // Corridas hoje
  final int weekDeliveries; // Corridas na semana
  final int monthDeliveries; // Corridas no mês
  final int totalDeliveries; // Total de corridas
  
  // Avaliações
  final double averageRating; // Nota média
  final int totalRatings; // Total de avaliações
  
  // Tempos
  final double averageDeliveryTime; // Tempo médio de entrega (minutos)
  final int totalKmTraveled; // Total de km percorridos
  
  // Corridas em andamento
  final int activeDeliveries; // Corridas aceitas/em progresso
  final List<DeliveryOrder> activeOrders; // Lista de corridas ativas
  
  // Meta diária
  final double dailyGoal; // Meta de ganhos diária
  final double? weeklyGoal; // Meta semanal (opcional)
  
  RiderStats({
    this.todayEarnings = 0.0,
    this.weekEarnings = 0.0,
    this.monthEarnings = 0.0,
    this.totalEarnings = 0.0,
    this.todayDeliveries = 0,
    this.weekDeliveries = 0,
    this.monthDeliveries = 0,
    this.totalDeliveries = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.averageDeliveryTime = 0.0,
    this.totalKmTraveled = 0,
    this.activeDeliveries = 0,
    this.activeOrders = const [],
    this.dailyGoal = 200.0,
    this.weeklyGoal,
  });
  
  // Progresso da meta diária (0.0 a 1.0)
  double get dailyGoalProgress {
    if (dailyGoal == 0) return 0.0;
    return (todayEarnings / dailyGoal).clamp(0.0, 1.0);
  }
  
  // Porcentagem da meta diária
  double get dailyGoalPercentage => dailyGoalProgress * 100;
  
  // Ganho médio por corrida hoje
  double get averageEarningPerDelivery {
    if (todayDeliveries == 0) return 0.0;
    return todayEarnings / todayDeliveries;
  }
  
  // Previsão de ganhos no final do dia (baseado na média atual)
  double get projectedEarningsToday {
    final now = DateTime.now();
    final hoursWorked = now.hour + (now.minute / 60.0);
    if (hoursWorked == 0) return 0.0;
    final earningPerHour = todayEarnings / hoursWorked;
    final remainingHours = 24 - hoursWorked;
    return todayEarnings + (earningPerHour * remainingHours);
  }
  
  // Tempo médio em string formatada
  String get averageDeliveryTimeFormatted {
    final minutes = averageDeliveryTime.toInt();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }
  
  // Status baseado na meta
  String get goalStatus {
    if (dailyGoalProgress >= 1.0) return 'Meta Atingida! 🎉';
    if (dailyGoalProgress >= 0.8) return 'Quase lá! 💪';
    if (dailyGoalProgress >= 0.5) return 'Na metade 📈';
    if (dailyGoalProgress >= 0.25) return 'Começando 🚀';
    return 'Vamos começar! 💼';
  }
  
  RiderStats copyWith({
    double? todayEarnings,
    double? weekEarnings,
    double? monthEarnings,
    double? totalEarnings,
    int? todayDeliveries,
    int? weekDeliveries,
    int? monthDeliveries,
    int? totalDeliveries,
    double? averageRating,
    int? totalRatings,
    double? averageDeliveryTime,
    int? totalKmTraveled,
    int? activeDeliveries,
    List<DeliveryOrder>? activeOrders,
    double? dailyGoal,
    double? weeklyGoal,
  }) {
    return RiderStats(
      todayEarnings: todayEarnings ?? this.todayEarnings,
      weekEarnings: weekEarnings ?? this.weekEarnings,
      monthEarnings: monthEarnings ?? this.monthEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      weekDeliveries: weekDeliveries ?? this.weekDeliveries,
      monthDeliveries: monthDeliveries ?? this.monthDeliveries,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      averageDeliveryTime: averageDeliveryTime ?? this.averageDeliveryTime,
      totalKmTraveled: totalKmTraveled ?? this.totalKmTraveled,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      activeOrders: activeOrders ?? this.activeOrders,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }
  
  // Calcula estatísticas a partir de uma lista de pedidos
  static RiderStats fromOrders(List<DeliveryOrder> orders, {
    double dailyGoal = 200.0,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Filtrar pedidos
    final todayOrders = orders.where((o) => 
      o.completedAt != null && o.completedAt!.isAfter(today)
    ).toList();
    
    final weekOrders = orders.where((o) => 
      o.completedAt != null && o.completedAt!.isAfter(weekStart)
    ).toList();
    
    final monthOrders = orders.where((o) => 
      o.completedAt != null && o.completedAt!.isAfter(monthStart)
    ).toList();
    
    final activeOrders = orders.where((o) => 
      o.status == DeliveryStatus.accepted || 
      o.status == DeliveryStatus.inProgress
    ).toList();
    
    // Calcular ganhos
    final todayEarnings = todayOrders.fold<double>(
      0.0, (sum, o) => sum + o.deliveryFee
    );
    final weekEarnings = weekOrders.fold<double>(
      0.0, (sum, o) => sum + o.deliveryFee
    );
    final monthEarnings = monthOrders.fold<double>(
      0.0, (sum, o) => sum + o.deliveryFee
    );
    final totalEarnings = orders.where((o) => 
      o.status == DeliveryStatus.completed
    ).fold<double>(
      0.0, (sum, o) => sum + o.deliveryFee
    );
    
    // Calcular estatísticas
    final completedOrders = orders.where((o) => 
      o.status == DeliveryStatus.completed
    ).toList();
    
    double avgTime = 0.0;
    if (completedOrders.isNotEmpty) {
      final totalMinutes = completedOrders.where((o) => 
        o.acceptedAt != null && o.completedAt != null
      ).fold<double>(0.0, (sum, o) {
        final duration = o.completedAt!.difference(o.acceptedAt!);
        return sum + duration.inMinutes.toDouble();
      });
      avgTime = totalMinutes / completedOrders.length;
    }
    
    return RiderStats(
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      monthEarnings: monthEarnings,
      totalEarnings: totalEarnings,
      todayDeliveries: todayOrders.length,
      weekDeliveries: weekOrders.length,
      monthDeliveries: monthOrders.length,
      totalDeliveries: completedOrders.length,
      averageDeliveryTime: avgTime,
      activeDeliveries: activeOrders.length,
      activeOrders: activeOrders,
      dailyGoal: dailyGoal,
    );
  }
}
