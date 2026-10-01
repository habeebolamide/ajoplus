import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService service;
  AppUser? user;
  bool busy = false;
  int sessionGeneration = 0;
  VoidCallback? onSignedOut;
  AuthProvider({required ApiClient api, AuthService? service}) : service = service ?? AuthService(api) {
    api.onUnauthorized = () {
      user = null;
      onSignedOut?.call();
      sessionGeneration++;
      notifyListeners();
    };
  }
  Future<void> restore() async {
    busy = true;
    notifyListeners();
    try {
      user = await service.restore();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    busy = true;
    notifyListeners();
    try {
      user = await service.register(name, email, phone, password);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    busy = true;
    notifyListeners();
    try {
      user = await service.login(email, password);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await service.logout();
    user = null;
    onSignedOut?.call();
    sessionGeneration++;
    notifyListeners();
  }
}
