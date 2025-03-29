// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tickiting/utils/database_helper.dart';
// import 'package:tickiting/models/booking.dart';
// import 'package:tickiting/models/user.dart';

// Notification model class
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final String type; // 'booking', 'payment', 'user', etc.
  final String recipient; // 'admin', 'user'
  final int? userId; // Optional: ID of the user if recipient is 'user'
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
    required this.recipient,
    this.userId,
  });
  
  // Convert notification to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'type': type,
      'recipient': recipient,
      'userId': userId,
    };
  }
  
  // Create a notification from a map (from database)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      time: map['time'] != null ? DateTime.parse(map['time']) : DateTime.now(),
      isRead: map['isRead'] == 1,
      type: map['type'] ?? '',
      recipient: map['recipient'] ?? '',
      userId: map['userId'],
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Controller for broadcasting notification events
  final StreamController<NotificationModel> _notificationController = StreamController<NotificationModel>.broadcast();
  
  // Stream to listen for new notifications
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  // Timer for checking new bookings
  Timer? _notificationTimer;
  
  // Settings
  bool _enableNotifications = true;
  bool _enableBookingConfirmation = true;
  bool _enablePaymentReminders = true;
  
  // Private constructor
  NotificationService._internal();
  
  // Factory constructor to return the same instance
  factory NotificationService() {
    return _instance;
  }
  
  // Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
    _startNotificationTimer();
  }
  
  // Load notification settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enableNotifications = prefs.getBool('enable_notifications') ?? true;
    _enableBookingConfirmation = prefs.getBool('enable_booking_confirmation') ?? true;
    _enablePaymentReminders = prefs.getBool('enable_payment_reminders') ?? true;
  }
  
  // Save notification settings
  Future<void> saveSettings({
    required bool enableNotifications,
    required bool enableBookingConfirmation,
    required bool enablePaymentReminders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', enableNotifications);
    await prefs.setBool('enable_booking_confirmation', enableBookingConfirmation);
    await prefs.setBool('enable_payment_reminders', enablePaymentReminders);
    
    _enableNotifications = enableNotifications;
    _enableBookingConfirmation = enableBookingConfirmation;
    _enablePaymentReminders = enablePaymentReminders;
    
    // Restart notification timer with new settings
    _startNotificationTimer();
  }
  
  // Start notification timer
  void _startNotificationTimer() {
    // Cancel any existing timer
    _notificationTimer?.cancel();
    
    // Check for new bookings every 30 seconds if notifications are enabled
    if (_enableNotifications) {
      _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkForNewBookings();
      });
    }
  }
  
  // Check for new bookings
  Future<void> _checkForNewBookings() async {
    try {
      // Get recent bookings that might need notifications
      final bookings = await _databaseHelper.getAllBookings();
      
      // Filter for new bookings in the last hour that need notifications
      final now = DateTime.now();
      final recentBookings = bookings.where((booking) {
        if (booking.createdAt == null) return false;
        
        final bookingTime = DateTime.parse(booking.createdAt!);
        final timeDifference = now.difference(bookingTime);
        
        // Only process bookings from the last hour that have Pending status
        return timeDifference.inHours <= 1 && 
               booking.bookingStatus == 'Pending' &&
               !booking.notificationSent;
      }).toList();
      
      // Create notifications for new bookings
      for (var booking in recentBookings) {
        // Get user info
        final user = await _databaseHelper.getUserById(booking.userId);
        if (user != null) {
          // Notification for admin
          await createNotification(
            title: 'New Booking',
            message: '${user.name} booked a ticket from ${booking.fromLocation} to ${booking.toLocation}',
            type: 'booking',
            recipient: 'admin',
          );
          
          // Notification for user
          await createNotification(
            title: 'Booking Received',
            message: 'Your booking from ${booking.fromLocation} to ${booking.toLocation} has been received and is being processed.',
            type: 'booking_confirmation',
            recipient: 'user',
            userId: booking.userId,
          );
          
          // Mark booking as notified
          await _databaseHelper.updateBookingNotificationStatus(booking.id, true);
        }
      }
    } catch (e) {
      debugPrint('Error checking for new bookings: $e');
    }
  }
  
  // Dispose the service
  void dispose() {
    _notificationTimer?.cancel();
    _notificationController.close();
  }
  
  // Create a new notification
  Future<NotificationModel> createNotification({
    required String title,
    required String message,
    required String type,
    required String recipient,
    int? userId,
  }) async {
    final notification = NotificationModel(
      id: 0, // This will be auto-incremented by the database
      title: title,
      message: message,
      time: DateTime.now(),
      isRead: false,
      type: type,
      recipient: recipient,
      userId: userId,
    );
    
    // Prepare notification data for database
    final notificationMap = {
      'title': notification.title,
      'message': notification.message,
      'time': notification.time.toIso8601String(),
      'isRead': notification.isRead ? 1 : 0,
      'type': notification.type,
      'recipient': notification.recipient,
      'userId': notification.userId,
    };
    
    // Insert into database
    final id = await _databaseHelper.insertNotification(notificationMap);
    
    // Create a new notification with the generated ID
    final createdNotification = NotificationModel(
      id: id,
      title: notification.title,
      message: notification.message,
      time: notification.time,
      isRead: notification.isRead,
      type: notification.type,
      recipient: notification.recipient,
      userId: notification.userId,
    );
    
    // Broadcast the new notification
    _notificationController.add(createdNotification);
    
    return createdNotification;
  }
  
  // Get all notifications for a specific recipient
  Future<List<NotificationModel>> getNotifications({
    required String recipient,
    int? userId,
  }) async {
    final List<Map<String, dynamic>> maps = await _databaseHelper.getNotifications(
      recipient: recipient,
      userId: userId,
    );
    
    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }
  
  // Get unread notifications count
  Future<int> getUnreadCount({
    required String recipient,
    int? userId,
  }) async {
    return await _databaseHelper.getUnreadNotificationsCount(
      recipient: recipient,
      userId: userId,
    );
  }
  
  // Mark a notification as read
  Future<void> markAsRead(int id) async {
    await _databaseHelper.markNotificationAsRead(id);
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead({
    required String recipient,
    int? userId,
  }) async {
    await _databaseHelper.markAllNotificationsAsRead(
      recipient: recipient,
      userId: userId,
    );
  }
  
  // Delete a notification
  Future<void> deleteNotification(int id) async {
    await _databaseHelper.deleteNotification(id);
  }
  
  // Delete all notifications for a recipient
  Future<void> deleteAllNotifications({
    required String recipient,
    int? userId,
  }) async {
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (userId != null) {
      whereClause = 'recipient = ? AND userId = ?';
      whereArgs = [recipient, userId];
    } else {
      whereClause = 'recipient = ?';
      whereArgs = [recipient];
    }
    
    final db = await _databaseHelper.database;
    await db.delete(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
    );
  }
  
  // Create a booking notification for admin
  Future<NotificationModel> createBookingNotificationForAdmin({
    required int userId,
    required String userName,
    required String origin,
    required String destination,
  }) async {
    if (!_enableNotifications || !_enableBookingConfirmation) return Future.error('Notifications disabled');
    
    final title = 'New Booking';
    final message = '$userName booked a ticket from $origin to $destination';
    
    return createNotification(
      title: title,
      message: message,
      type: 'booking',
      recipient: 'admin',
    );
  }
  
  // Create a payment notification for admin
  Future<NotificationModel> createPaymentNotificationForAdmin({
    required int userId,
    required String userName,
    required double amount,
    String currency = 'RWF', // Changed from required to optional with default value
  }) async {
    if (!_enableNotifications || !_enablePaymentReminders) return Future.error('Notifications disabled');
    
    final title = 'Payment Received';
    final message = 'Payment of $amount $currency received from $userName';
    
    return createNotification(
      title: title,
      message: message,
      type: 'payment',
      recipient: 'admin',
    );
  }
  
  // Create a booking confirmation notification for user
  Future<NotificationModel> createBookingConfirmationForUser({
    required int userId,
    required String userName,
    required String origin,
    required String destination,
    required DateTime travelDate,
  }) async {
    if (!_enableNotifications || !_enableBookingConfirmation) return Future.error('Notifications disabled');
    
    final title = 'Booking Confirmed';
    final message = 'Your ticket from $origin to $destination on ${_formatDate(travelDate)} has been confirmed.';
    
    return createNotification(
      title: title,
      message: message,
      type: 'booking_confirmation',
      recipient: 'user',
      userId: userId,
    );
  }
  
  // Create a payment confirmation notification for user
  Future<NotificationModel> createPaymentConfirmationForUser({
    required int userId,
    required String userName,
    required double amount,
    String currency = 'RWF', // Changed from required to optional with default value
  }) async {
    if (!_enableNotifications || !_enablePaymentReminders) return Future.error('Notifications disabled');
    
    final title = 'Payment Confirmed';
    final message = 'Your payment of $amount $currency has been received. Thank you!';
    
    return createNotification(
      title: title,
      message: message,
      type: 'payment_confirmation',
      recipient: 'user',
      userId: userId,
    );
  }
  
  // Create booking status update notification for user
  Future<NotificationModel> createBookingStatusUpdateForUser({
    required int userId,
    required String bookingId,
    required String status,
    required String origin,
    required String destination,
  }) async {
    if (!_enableNotifications) return Future.error('Notifications disabled');
    
    String title, message;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Booking Confirmed';
        message = 'Your booking from $origin to $destination has been confirmed.';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        message = 'Your booking from $origin to $destination has been cancelled.';
        break;
      case 'completed':
        title = 'Trip Completed';
        message = 'Your trip from $origin to $destination has been completed. Thank you for traveling with us!';
        break;
      default:
        title = 'Booking Update';
        message = 'Your booking from $origin to $destination has been updated to $status.';
    }
    
    return createNotification(
      title: title,
      message: message,
      type: 'booking_status',
      recipient: 'user',
      userId: userId,
    );
  }
  
  // Format date helper function
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}