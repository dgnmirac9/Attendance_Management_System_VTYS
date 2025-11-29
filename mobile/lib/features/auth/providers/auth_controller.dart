import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final UserService _userService;

  AuthController(this._userService) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Login error: ${e.message}');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Login error: $e');
    }
  }

  Future<void> register(String name, String studentId, String email, String password, String role) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save additional user data to Firestore
      // IMPORTANT: Make sure Firestore rules are set to public (test mode) for now.
      if (userCredential.user != null) {
        await _userService.saveUserData(
          uid: userCredential.user!.uid,
          name: name,
          studentId: studentId,
          email: email,
          role: role,
        );
      }

      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Register error: ${e.message}');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Register error: $e');
    }
  }
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('SignOut error: $e');
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(UserService());
});
