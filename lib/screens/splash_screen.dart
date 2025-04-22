import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;
  bool _isRetrying = false;
  late Future<bool> _initializationFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: Initializing...');
    _initializationFuture = _initialize();
  }

  Future<bool> _initialize() async {
    try {
      setState(() {
        _error = null;
        _isRetrying = false;
      });

      debugPrint('SplashScreen: Getting AuthService...');
      final authService = Provider.of<AuthService>(context, listen: false);

      // Add a minimum delay for splash screen
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('SplashScreen: Checking if first launch...');
      final isFirstLaunch = await _isFirstLaunch();
      
      if (isFirstLaunch) {
        return true;
      }

      debugPrint('SplashScreen: Checking login status...');
      final isLoggedIn = await authService.isLoggedIn();
      debugPrint('SplashScreen: Login status - $isLoggedIn');
      
      return isLoggedIn;
    } catch (e) {
      debugPrint('SplashScreen: Error during initialization: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
      rethrow;
    }
  }

  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }
    return isFirstLaunch;
  }

  void _retry() {
    setState(() {
      _isRetrying = true;
      _initializationFuture = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<bool>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bus Ticket Booking',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (!_isRetrying)
                    ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                ],
              );
            }

            if (snapshot.hasData) {
              final isFirstLaunch = snapshot.data!;
              
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (isFirstLaunch) {
                  debugPrint('SplashScreen: Navigating to WelcomeScreen');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  );
                } else {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  final isLoggedIn = await authService.isLoggedIn();
                  debugPrint('SplashScreen: Navigating to ${isLoggedIn ? 'HomeScreen' : 'LoginScreen'}');
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          isLoggedIn ? const HomeScreen() : const LoginScreen(),
                    ),
                  );
                }
              });
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bus Ticket Booking',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }
}
