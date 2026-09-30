import '../models/models.dart';
import '../utils/id.dart';
import 'password_hash.dart';
import 'storage_service.dart';

class AuthService {
  AppUser? get active {
    final id = StorageService.prefs.getString('session');
    if (id == null) return null;
    final storedUser = StorageService.users.get(id);
    return storedUser == null ? null : AppUser.from(storedUser);
  }

  Future<AppUser> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (StorageService.read(
      StorageService.users,
      AppUser.from,
    ).any((u) => u.email.toLowerCase() == normalized)) {
      throw StateError('An account already uses this email.');
    }
    final user = AppUser(
      newId(),
      name.trim(),
      normalized,
      phone.trim(),
      DateTime.now(),
    );
    await StorageService.users.put(user.id, {
      ...user.toMap(),
      'passwordHash': await hashPassword(password),
    });
    await StorageService.prefs.setString('session', user.id);
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    for (final raw in StorageService.users.values) {
      final user = AppUser.from(raw);
      if (user.email.toLowerCase() != normalized) continue;

      final stored = Map<String, Object?>.from(raw as Map);
      final hash = stored['passwordHash'] as String?;
      final legacyPassword = stored['password'] as String?;
      final matches = hash != null
          ? await verifyPassword(password, hash)
          : legacyPassword == password;
      if (!matches) break;

      if (hash == null) {
        await StorageService.users.put(user.id, {
          ...user.toMap(),
          'passwordHash': await hashPassword(password),
        });
      }
      await StorageService.prefs.setString('session', user.id);
      return user;
    }
    throw StateError('Email or password is incorrect.');
  }

  Future<void> logout() => StorageService.prefs.remove('session');
}
