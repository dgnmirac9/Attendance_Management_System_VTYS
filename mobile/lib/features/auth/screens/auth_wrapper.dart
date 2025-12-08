import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';

import '../../classroom/screens/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Auth Loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;

        // 2. User Logged Out -> Login Screen
        if (user == null) {
          return const LoginScreen();
        }

        // 3. User Logged In -> Home Screen
        // We could listen to role here, but HomeScreen handles data fetching.
        // We just need to ensure the user doc exists or handle it gracefully.
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(FirestoreConstants.usersCollection).doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Even if user doc is missing (rare), we send to Home.
            // Home will show empty state or handle errors.
            return const HomeScreen();
          },
        );
      },
    );
  }
}