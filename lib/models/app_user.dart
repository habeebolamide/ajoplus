class AppUser {
  final String id, fullName, email, phone;
  final DateTime createdAt;
  const AppUser(this.id, this.fullName, this.email, this.phone, this.createdAt);
  factory AppUser.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return AppUser(
      m['id'] as String,
      m['fullName'] as String,
      m['email'] as String,
      m['phone'] as String,
      DateTime.parse(m['createdAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };
}
