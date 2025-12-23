import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../classroom/screens/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text('Bir hata oluştu: $error'),
               const SizedBox(height: 20),
               ElevatedButton(
                 onPressed: () {
                   // Retry by re-creating the controller or a simpler refresh mechanism
                   // For now, just invalidate provider to restart check
                   ref.invalidate(authControllerProvider);
                 }, 
                 child: const Text('Tekrar Dene')
               )
             ]
          ),
        ),
      ),
    );
  }
}