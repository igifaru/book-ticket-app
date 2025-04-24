import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/bus_service.dart';
import 'services/booking_service.dart';
import 'services/route_service.dart';
import 'services/settings_service.dart';
import 'app.dart';
import 'utils/database_helper.dart';

class AppLoader extends StatefulWidget {
  final Widget child;

  const AppLoader({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isInitializing = false;
  String _initializationStatus = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid initialization during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  Future<void> _startInitialization() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _error = null;
      _initializationStatus = 'Starting initialization...';
    });

    try {
      // Initialize services sequentially with microtasks
      await Future(() async {
        // Auth service
        await _initializeService(
          'Initializing authentication...',
          () => context.read<AuthService>().initialize(),
        );

        // Route service
        await _initializeService(
          'Loading routes...',
          () => context.read<RouteService>().initialize(),
        );

        // Bus service
        await _initializeService(
          'Loading buses...',
          () => context.read<BusService>().initialize(),
        );

        // Booking service
        await _initializeService(
          'Loading bookings...',
          () => context.read<BookingService>().initialize(),
        );

        // Settings service
        await _initializeService(
          'Loading settings...',
          () => context.read<SettingsService>().initialize(),
        );
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationStatus = 'Initialization complete';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _initializeService(String status, Future<void> Function() initFunction) async {
    if (mounted) {
      setState(() => _initializationStatus = status);
    }
    await initFunction();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error during initialization:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startInitialization,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isInitializing) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RepaintBoundary(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _initializationStatus,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
} 