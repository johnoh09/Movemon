import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_diet_app/providers/user_provider.dart';
import 'package:flutter_diet_app/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider allows us to provide multiple objects down the widget tree.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add other providers here, e.g., WorkoutProvider, BadgeProvider
      ],
      child: MaterialApp(
        title: 'Diet & Workout App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[50],
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          // FIX: Changed CardTheme to CardThemeData to match the expected type.
          cardTheme: CardThemeData(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

