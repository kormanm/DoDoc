import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  String? _accessToken;
  bool _isAuthenticated = false;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(String token) {
    _accessToken = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  void setUnauthenticated() {
    _accessToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
