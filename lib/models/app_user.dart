import '../services/api_data.dart';

class AppUser {
  final String id, fullName, email, phone;
  final DateTime createdAt;
  const AppUser(this.id, this.fullName, this.email, this.phone, this.createdAt);
  factory AppUser.fromApi(Object? raw) {
    final data = ApiData.object(raw);
    return AppUser(
      ApiData.id(data, 'id'),
      ApiData.string(data, 'name'),
      ApiData.string(data, 'email'),
      ApiData.optionalString(data, 'phone'),
      ApiData.date(data, 'created_at'),
    );
  }
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
