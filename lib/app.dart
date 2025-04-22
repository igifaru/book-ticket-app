import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: Building app...');
    
    // Set up global error widget handler
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      debugPrint('MyApp: Caught error: ${errorDetails.exception}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${errorDetails.exception}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    };

    return MaterialApp(
      title: 'Bus Ticket Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
          background: Colors.black,
        ),
      ),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        debugPrint('MyApp: Building with error handler...');
        return MediaQuery(
          // Disable debug banner at MediaQuery level
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (context) {
          debugPrint('MyApp: Building SplashScreen...');
          return const SplashScreen();
        },
      ),
    );
  }
} 