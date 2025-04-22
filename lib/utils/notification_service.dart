import 'package:bus_ticket_booking/utils/database_helper.dart';

class NotificationService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> initialize() async {
    await _fixExistingNotifications();
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

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _databaseHelper.insert('notifications', {
      'title': title,
      'message': body,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isRead': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getNotificationsForUser(int userId) async {
    final db = await _databaseHelper.database;
    return await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }
} 