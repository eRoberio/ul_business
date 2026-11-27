class AppUser {
  final String uid;
  final String nome;
  final String email;
  final String? fotoUrl;
  final String role;

  const AppUser({
    required this.uid,
    required this.nome,
    required this.email,
    this.fotoUrl,
    required this.role,
  });

  bool get isPending => role == 'pendente';
  bool get isOrador => role == 'orador';
  bool get isActive => !isPending;

  factory AppUser.fromMap(String uid, Map<String, dynamic>? data) {
    return AppUser(
      uid: uid,
      nome: (data?['nome'] ?? 'Usuário').toString(),
      email: (data?['email'] ?? '').toString(),
      fotoUrl: data?['fotoUrl'] as String?,
      role: (data?['role'] ?? 'pendente').toString(),
    );
  }
}
