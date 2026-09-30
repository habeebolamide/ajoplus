class AppNotification {
  final String id, title, message, type;
  final DateTime createdAt;
  final bool isRead;
  const AppNotification(
    this.id,
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
      m['title'] as String,
      m['message'] as String,
      m['type'] as String,
      DateTime.parse(m['createdAt'] as String),
      m['isRead'] as bool,
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };
  AppNotification read() =>
      AppNotification(id, title, message, type, createdAt, true);
}
