class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final String? photoUrl;
  final String pilotProfile; // Fim de Semana, Urbano, Trabalho, Pista

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.photoUrl,
    required this.pilotProfile,
  });
}
