import 'package:carbon_tracker/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:carbon_tracker/core/config/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();

  try {
    await _checkAndResetMonthlyData(dbHelper);
  } catch (e) {
    debugPrint('Error during initialization: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _checkAndResetMonthlyData(DatabaseHelper dbHelper) async {
  final user = await dbHelper.queryUser();
  if (user == null) return; // no user yet, nothing to reset

  final now = DateTime.now();
  final needsReset =
      user.lastResetMonth != now.month || user.lastResetYear != now.year;

  if (needsReset) {
    await dbHelper.resetMonthlyData(user, now.month, now.year);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Carbon Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      routerConfig: router,
    );
  }
}
