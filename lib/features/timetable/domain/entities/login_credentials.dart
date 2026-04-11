import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_credentials.freezed.dart';
part 'login_credentials.g.dart';

@freezed
abstract class LoginCredentials with _$LoginCredentials {
  const factory LoginCredentials({
    required String username,
    required String password,
  }) = _LoginCredentials;

  const LoginCredentials._();

  factory LoginCredentials.fromJson(Map<String, dynamic> json) =>
      _$LoginCredentialsFromJson(json);

  bool get isEmpty => username.trim().isEmpty || password.isEmpty;
}
