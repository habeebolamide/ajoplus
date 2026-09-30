class AppNotification {
  final String id, userId, title, message, type;
  final DateTime createdAt;
  final bool isRead;
  const AppNotification(
    this.id,
    this.userId,
    this.title,
    this.message,
    this.type,
    this.createdAt,
    this.isRead,
  );
  factory AppNotification.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return AppNotification(
      m['id'] as String,
      m['userId'] as String,
      m['title'] as String,
      m['message'] as String,
      m['type'] as String,
      DateTime.parse(m['createdAt'] as String),
      m['isRead'] as bool,
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };
  AppNotification read() =>
      AppNotification(id, userId, title, message, type, createdAt, true);
}
