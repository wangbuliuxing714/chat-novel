import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String? _userId;
  String? _username;
  bool _isLoggedIn = false;

  String? get userId => _userId;
  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;

  void login(String userId, String username) {
    _userId = userId;
    _username = username;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    notifyListeners();
  }
} 