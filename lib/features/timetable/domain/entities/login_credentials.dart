class LoginCredentials {
  const LoginCredentials({required this.username, required this.password});

  final String username;
  final String password;

  bool get isEmpty => username.trim().isEmpty || password.isEmpty;
}
