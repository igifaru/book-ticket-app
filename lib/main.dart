// lib/main.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'services/settings_service.dart';
import 'utils/performance_utils.dart';
import 'widgets/app_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core dependencies
  final prefs = await SharedPreferences.getInstance();
  final databaseHelper = DatabaseHelper();
  
  // Initialize database first
  await databaseHelper.database;

  // Create services
  final authService = AuthService(databaseHelper: databaseHelper, prefs: prefs);
  final routeService = RouteService(databaseHelper: databaseHelper);
  final busService = BusService(databaseHelper: databaseHelper);
  final bookingService = BookingService(databaseHelper: databaseHelper, busService: busService);
  final settingsService = SettingsService(prefs);

  // Pre-initialize critical services
  await Future.wait([
    authService.initialize(),
    settingsService.initialize(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: databaseHelper),
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<RouteService>.value(value: routeService),
        ChangeNotifierProvider<BusService>.value(value: busService),
        ChangeNotifierProvider<BookingService>.value(value: bookingService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
      ],
      child: const AppLoader(
        child: App(),
      ),
    ),
  );
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        platform: TargetPlatform.android,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      builder: (context, child) {
        // Add error boundary
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${details.exception}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        };
        
        return MediaQuery(
          // Prevent text scaling
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: child,
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
