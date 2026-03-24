import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../model/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final repo = ref.read(authRepositoryProvider);
    final isLoggedIn = await repo.isLoggedIn();
    if (isLoggedIn) {
      final user = await repo.getCurrentUser();
      state = state.copyWith(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email, password);
    if (result.error != null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: result.error);
      return false;
    }
    state = state.copyWith(status: AuthStatus.authenticated, user: result.user);
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(email, password);
    if (result.error != null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: result.error);
      return false;
    }
    state = state.copyWith(status: AuthStatus.authenticated, user: result.user);
    return true;
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
