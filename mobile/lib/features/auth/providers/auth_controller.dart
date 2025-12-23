import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../core/services/auth_service.dart';

// State: Contains the current authenticated user (or null) and loading/error state
class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final user = await _authService.getUserProfile();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // If error (e.g. token expired), logout
      await _authService.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    // Note: We don't set global loading here to prevent AuthWrapper from unmounting LoginScreen
    // The UI should handle local loading state
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      // Revert to unauthenticated state on error, allow UI to handle the exception
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? studentNo,
    String? faceImagePath,
  }) async {
    // Note: We don't set global loading here to prevent AuthWrapper from unmounting RegisterScreen
    try {
      await _authService.register(
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
        studentNo: studentNo,
        faceImagePath: faceImagePath,
      );
      // Don't auto-login! Keep state as null so user is redirected to login screen
      // User must manually login with their new credentials
      state = const AsyncValue.data(null);
    } catch (e) {
      // Revert to unauthenticated state on error, allow UI to handle the exception
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e) {
      // Even if logout fails (e.g. network), we should probably clear local state locally
      // For now, allow UI to decide, but force null state to "logout" locally
      state = const AsyncValue.data(null); 
    }
  }

  Future<void> updatePassword({required String oldPassword, required String newPassword}) async {
    // state = const AsyncValue.loading(); // Optional: don't block whole UI, just dialog
    try {
      await _authService.updatePassword(oldPassword, newPassword);
      // state remains same (user is still logged in)
    } catch (e) {
      // Don't change global state to error, just rethrow to dialog
      rethrow;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

final userRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value?.role;
});

final userDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value?.toJson();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value;
});
