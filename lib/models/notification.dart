class Notification {
  final int? id;
  final int userId;
  final String message;
  final bool isRead;
  final String createdAt;

  Notification({
    this.id,
    required this.userId,
    required this.message,
    this.isRead = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      message: map['message'] as String,
      isRead: (map['isRead'] as int) == 1,
      createdAt: map['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  Notification copyWith({
    int? id,
    int? userId,
    String? message,
    bool? isRead,
    String? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 