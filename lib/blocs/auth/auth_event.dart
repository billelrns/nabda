abstract class AuthEvent {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

class AuthUserUpdated extends AuthEvent {
  final String name;
  final String? avatar;
  final String? language;
  final String? mode;

  const AuthUserUpdated({
    required this.name,
    this.avatar,
    this.language,
    this.mode,
  });
}






