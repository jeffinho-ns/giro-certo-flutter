/// Normalização defensiva para rotas no Brasil (ex.: longitude +46 em vez de -46,6).
/// Não substitui validação de faixa; apenas corrige sinais típicos de erro de cliente/API.
class GeoCoordinatesBrazil {
  static ({double lat, double lng}) normalizeRoutingPair(double lat, double lng) {
    var la = lat;
    var ln = lng;

    if (la > 0 && la <= 30 && ln <= -25 && ln >= -75) {
      la = -la;
    }
    if (la <= -5 && la >= -35 && ln > 0 && ln <= 55) {
      ln = -ln;
    }

    return (lat: la, lng: ln);
  }

  static ({
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  })
      normalizeRouteEndpoints(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    final o = normalizeRoutingPair(originLat, originLng);
    final d = normalizeRoutingPair(destLat, destLng);
    return (
      originLat: o.lat,
      originLng: o.lng,
      destLat: d.lat,
      destLng: d.lng,
    );
  }
}
