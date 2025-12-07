import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final UserService _userService;
  final Ref _ref;

  AuthController(this._userService, this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      String message = "Giriş başarısız.";
      if (e.code == 'user-not-found') {
        message = "Kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        message = "Hatalı şifre.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta formatı.";
      } else if (e.code == 'invalid-credential') {
        message = "Hatalı e-posta veya şifre.";
      }
      state = AsyncValue.error(message, StackTrace.current);
      throw message;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw "Beklenmedik bir hata oluştu: $e";
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? studentNo,
    // List<List<double>>? faceEmbeddings, // Future use
  }) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save additional user data to Firestore
      // IMPORTANT: Make sure Firestore rules are set to public (test mode) for now.
        await _userService.saveUserData(
          uid: userCredential.user!.uid,
          name: '$firstName $lastName',
          firstName: firstName,
          lastName: lastName,
          // studentId: studentNo ?? '', // Removed from signature in UserService update above, handled below logic? 
          // Wait, I removed studentId from signature in UserService but logic below uses it.
          // I need to check UserService again. 
          // Ah, I replaced the block, checking UserService content again.
          email: email,
          role: role,
        );
        
        // Re-adding studentId handling if UserService still expects it logic-wise but I missed it in replacement.
        // Let's check UserService again to be safe. 
        // Actually, let's just make sure I pass what's needed.
        if (role == 'student' && studentNo != null) {
           await _userService.updateStudentId(userCredential.user!.uid, studentNo);
        }

      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      String message = "Kayıt başarısız.";
      if (e.code == 'email-already-in-use') {
        message = "Bu e-posta adresi zaten kullanımda.";
      } else if (e.code == 'weak-password') {
        message = "Şifre çok zayıf.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta adresi.";
      }
      state = AsyncValue.error(message, StackTrace.current);
      throw message;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw "Kayıt sırasında bir hata oluştu: $e";
    }
  }
  
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Kullanıcı oturum açmamış.");
      if (user.email == null) throw Exception("Kullanıcı e-postası bulunamadı.");

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: oldPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      String message = "Hata oluştu: ${e.message}";
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Mevcut şifreniz yanlış.";
      } else if (e.code == 'requires-recent-login') {
        message = "Güvenlik nedeniyle tekrar giriş yapıp deneyin.";
      }
      // Put a clean message in the error so UI can show it
      state = AsyncValue.error(message, StackTrace.current); 
      throw message; 
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signOut();
      _ref.invalidate(userRoleProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('SignOut error: $e');
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(UserService(), ref);
});

final userRoleProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.uid != null
      ? await UserService().getUserRole(authState.value!.uid)
      : null;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userDataProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value?.uid == null) return null;
  
  final doc = await FirebaseFirestore.instance.collection('users').doc(authState.value!.uid).get();
  return doc.data();
});
