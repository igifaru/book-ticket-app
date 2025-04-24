import 'package:flutter/material.dart';
import '../utils/performance_utils.dart';
import '../services/auth_service.dart';
import '../services/route_service.dart';
import '../services/bus_service.dart';
import '../services/booking_service.dart';
import '../services/settings_service.dart';
import '../utils/database_helper.dart';
import 'package:provider/provider.dart';

class AppLoader extends StatefulWidget {
  final Widget child;

  const AppLoader({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isLoading = true;
  String _status = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeRemainingServices();
  }

  Future<void> _initializeRemainingServices() async {
    try {
      final routeService = context.read<RouteService>();
      final busService = context.read<BusService>();
      final bookingService = context.read<BookingService>();

      // Initialize remaining services in parallel
      setState(() => _status = 'Initializing services...');
      await Future.wait([
        routeService.initialize(),
        busService.initialize(),
        bookingService.initialize(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Ready';
        });
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _isLoading
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : widget.child,
    );
  }
} 