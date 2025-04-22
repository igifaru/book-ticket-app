// lib/main.dart (updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'screens/splash_screen.dart';
import 'utils/database_helper.dart';
import 'services/bus_service.dart';
import 'services/booking_service.dart';
import 'services/payment_service.dart';
import 'services/auth_service.dart';
import 'services/route_service.dart';
import 'services/notification_service.dart';
import 'models/user.dart';
import 'models/booking.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  try {
    debugPrint('Main: Starting app initialization...');
    
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Main: Flutter binding initialized');
    
    // Create and initialize database helper
    debugPrint('Main: Creating DatabaseHelper...');
    final databaseHelper = DatabaseHelper();
    
    debugPrint('Main: Getting database instance...');
    final db = await databaseHelper.database;
    debugPrint('Main: Database initialized successfully');

    // Create services in dependency order
    debugPrint('Main: Creating services...');
    final authService = AuthService(databaseHelper: databaseHelper);
    final busService = BusService(databaseHelper: databaseHelper);
    final routeService = RouteService(databaseHelper: databaseHelper);
    final bookingService = BookingService(
      databaseHelper: databaseHelper,
      busService: busService,
    );
    final paymentService = PaymentService(databaseHelper, bookingService);
    final notificationService = NotificationService(databaseHelper: databaseHelper);

    // Initialize core services first
    debugPrint('Main: Initializing core services...');
    await Future.wait<void>([
      authService.initialize(),
      busService.initialize(),
      routeService.initialize(),
    ]).catchError((error) {
      debugPrint('Main: Error initializing core services: $error');
      throw error;
    });

    // Initialize dependent services
    debugPrint('Main: Initializing dependent services...');
    await Future.wait<void>([
      bookingService.initialize(),
      paymentService.initialize(),
      notificationService.initialize(),
    ]).catchError((error) {
      debugPrint('Main: Error initializing dependent services: $error');
      throw error;
    });
    
    debugPrint('Main: All services initialized successfully');

    debugPrint('Main: Setting up providers...');
    runApp(
      MultiProvider(
        providers: [
          Provider<DatabaseHelper>.value(value: databaseHelper),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<RouteService>.value(value: routeService),
          ChangeNotifierProvider<BusService>.value(value: busService),
          ChangeNotifierProvider<BookingService>.value(value: bookingService),
          ChangeNotifierProvider<PaymentService>.value(value: paymentService),
          ChangeNotifierProvider<NotificationService>.value(value: notificationService),
        ],
        child: Builder(
          builder: (context) {
            debugPrint('Main: Building MyApp...');
            return const MyApp();
          },
        ),
      ),
    );
    debugPrint('Main: App initialization completed successfully');
  } catch (e, stackTrace) {
    debugPrint('Main: Error during app initialization: $e');
    debugPrint('Main: Stack trace: $stackTrace');
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.dark(
            primary: Colors.deepPurple,
            secondary: Colors.deepPurpleAccent,
            surface: Colors.grey[900]!,
            background: Colors.black,
          ),
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Starting App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Details: ${stackTrace.toString().split('\n').take(3).join('\n')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await main();
                      } catch (retryError) {
                        debugPrint('Main: Error during retry: $retryError');
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _fixExistingNotifications() async {
  final databaseHelper = DatabaseHelper();
  final db = await databaseHelper.database;

  print("Starting to fix Admin User notifications...");

  // First, get all available users to find a suitable replacement
  final users = await databaseHelper.getAllUsers();
  final realUsers = users.map((map) => User.fromMap(map))
      .where((user) => user.name != 'Admin User')
      .toList();

  // Default replacement name if no match is found
  String defaultName = "Real User";
  if (realUsers.isNotEmpty) {
    defaultName = realUsers.first.name;
  }

  // Get all notifications with "Admin User" in the message
  final notifications = await db.query(
    'notifications',
    where: 'message LIKE ?',
    whereArgs: ['%Admin User%'],
  );

  print("Found ${notifications.length} notifications to fix");

  for (var notification in notifications) {
    final int id = notification['id'] as int;
    final String message = notification['message'] as String;
    final int? userId = notification['userId'] as int?;
    String updatedMessage = message;
    bool wasFixed = false;

    // STRATEGY 1: Try to extract user info using the booking information
    if (message.contains("booked a ticket from")) {
      final pattern = RegExp(r'Admin User booked a ticket from (\w+) to (\w+)');
      final match = pattern.firstMatch(message);

      if (match != null) {
        final fromLocation = match.group(1);
        final toLocation = match.group(2);

        // Try to find a matching booking
        final bookings = await databaseHelper.getAllBookings();
        final matchingBooking = bookings
            .map((map) => Booking.fromMap(map))
            .where(
              (b) => b.fromLocation == fromLocation && b.toLocation == toLocation,
            )
            .toList();

        if (matchingBooking.isNotEmpty) {
          // Use the user ID from the booking
          final bookingUserId = matchingBooking.first.userId;
          final userMap = await databaseHelper.getUserById(bookingUserId);
          if (userMap != null) {
            final user = User.fromMap(userMap);
            if (user.name != "Admin User") {
              updatedMessage = message.replaceAll("Admin User", user.name);
              wasFixed = true;

              await db.update(
                'notifications',
                {'message': updatedMessage},
                where: 'id = ?',
                whereArgs: [id],
              );

              print("Fixed notification #$id: '$message' -> '$updatedMessage'");
            }
          }
        }
      }
    }

    // STRATEGY 2: For other notification types, try using the userId if available
    if (!wasFixed && userId != null) {
      final userMap = await databaseHelper.getUserById(userId);
      if (userMap != null) {
        final user = User.fromMap(userMap);
        if (user.name != "Admin User") {
          updatedMessage = message.replaceAll("Admin User", user.name);
          wasFixed = true;

          await db.update(
            'notifications',
            {'message': updatedMessage},
            where: 'id = ?',
            whereArgs: [id],
          );

          print(
            "Fixed notification #$id using userId: '$message' -> '$updatedMessage'",
          );
        }
      }
    }

    // STRATEGY 3: If still not fixed, use the default name
    if (!wasFixed) {
      if (userId != null) {
        // If we have a userId but couldn't get a name, use "User #ID"
        updatedMessage = message.replaceAll("Admin User", "User #$userId");
      } else {
        // Otherwise use the default real user name
        updatedMessage = message.replaceAll("Admin User", defaultName);
      }

      await db.update(
        'notifications',
        {'message': updatedMessage},
        where: 'id = ?',
        whereArgs: [id],
      );

      print(
        "Fixed notification #$id using default approach: '$message' -> '$updatedMessage'",
      );
    }
  }

  print("Completed fixing Admin User notifications");

  // Finally, update the Admin User name in the users table
  try {
    await db.update(
      'users',
      {'name': 'System Administrator'},
      where: 'name = ? AND email = ?',
      whereArgs: ['Admin User', 'admin@rwandabus.com'],
    );
    print("Updated admin user name to 'System Administrator'");
  } catch (e) {
    print("Error updating admin user name: $e");
  }
}
