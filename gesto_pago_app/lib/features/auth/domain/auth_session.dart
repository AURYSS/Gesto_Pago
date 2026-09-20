/// Sesión autenticada en memoria de la aplicación.
class AuthSession {
  const AuthSession({
    required this.email,
    required this.nombre,
    required this.accessToken,
    required this.refreshToken,
    required this.roles,
  });

  final String email;
  final String nombre;
  final String accessToken;
  final String refreshToken;
  final List<String> roles;

  bool get isAuthenticated => accessToken.isNotEmpty;
}