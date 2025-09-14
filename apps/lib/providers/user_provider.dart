import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  // This would be called after a successful login
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // This would be called on logout
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
