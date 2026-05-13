/// Experimento Fase 1: Modo Corrida dedicado (`TripNavigationScreen`).
///
/// Rollback imediato: defina [enabled] como `false` e faça hot restart.
/// A Home volta a usar o overlay Mapbox e o fluxo embutido anteriores.
class TripNavigationExperiment {
  TripNavigationExperiment._();

  /// `true` = aceitar corrida abre [TripNavigationScreen] (push).
  /// `false` = comportamento legado na Home (overlay Mapbox + Google).
  static const bool enabled = true;

  /// Sessão ativa na tela dedicada (evita pipcar duplicado na Home).
  static bool activeSessionOpen = false;
}
