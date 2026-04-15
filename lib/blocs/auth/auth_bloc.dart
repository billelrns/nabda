import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authService.login(
        email: event.email,
        password: event.password,
      );

      if (user \!= null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('فشل تسجيل الدخول'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    if (event.password \!= event.confirmPassword) {
      emit(const AuthError('كلمات المرور غير متطابقة'));
      return;
    }

    try {
      final user = await authService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      if (user \!= null) {
        emit(AuthAuthenticated(user));
        emit(const AuthSuccess('تم إنشاء الحساب بنجاح'));
      } else {
        emit(const AuthError('فشل إنشاء الحساب'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await authService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckStatusRequested(
      AuthCheckStatusRequested event, Emitter<AuthState> emit) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser \!= null) {
        final user = await authService.getCurrentUser(currentUser.uid);
        if (user \!= null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUserUpdated(
      AuthUserUpdated event, Emitter<AuthState> emit) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser \!= null) {
        await authService.updateUserProfile(
          uid: currentUser.uid,
          name: event.name,
          avatar: event.avatar,
          language: event.language,
          mode: event.mode,
        );

        final updatedUser = await authService.getCurrentUser(currentUser.uid);
        if (updatedUser \!= null) {
          emit(AuthAuthenticated(updatedUser));
          emit(const AuthSuccess('تم تحديث البيانات بنجاح'));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
