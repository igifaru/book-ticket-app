import 'package:flutter/foundation.dart';
import '../utils/database_helper.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  List<Notification> _notifications = [];
  bool _loading = false;

  NotificationService({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  List<Notification> get notifications => _notifications;
  bool get loading => _loading;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    try {
      await _fixExistingNotifications();
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationService: Error during initialization: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _fixExistingNotifications() async {
    final db = await _databaseHelper.database;
    
    // Get all notifications with "Admin User" in the message
    final notifications = await db.query(
      'notifications',
      where: 'message LIKE ?',
      whereArgs: ['%Admin User%'],
    );

    for (var notification in notifications) {
      final int id = notification['id'] as int;
      final String message = notification['message'] as String;
      final String updatedMessage = message.replaceAll('Admin User', 'System Administrator');
      
      await db.update(
        'notifications',
        {'message': updatedMessage},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<Notification> sendNotification({
    required int userId,
    required String message,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final notification = Notification(
        userId: userId,
        message: message,
      );
      final id = await _databaseHelper.insert('notifications', notification.toMap());
      final createdNotification = notification.copyWith(id: id);
      _notifications.add(createdNotification);
      notifyListeners();
      return createdNotification;
    } catch (e) {
      debugPrint('NotificationService: Error sending notification: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Notification>> getNotificationsForUser(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      final notifications = await _databaseHelper.query(
        'notifications',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      _notifications = notifications.map((map) => Notification.fromMap(map)).toList();
      return _notifications;
    } catch (e) {
      debugPrint('NotificationService: Error getting notifications: $e');
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _databaseHelper.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationService: Error marking notification as read: $e');
      rethrow;
    }
  }
} 