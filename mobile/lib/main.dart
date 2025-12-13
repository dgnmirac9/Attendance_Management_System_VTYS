import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Firebase removed for API integration
    // await Firebase.initializeApp();
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'C-LENS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}
