import 'package:flutter/material.dart';
import 'shared_preferences_provider.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuth = false;
  SharedPreferencesProvider? sharedPreferencesProvider;

  bool get isAuth => _isAuth;

  AuthProvider();

  void updateSharedPreferencesProvider(SharedPreferencesProvider newProvider) {
    sharedPreferencesProvider = newProvider;
    initializeAuthStatus();
  }

  void initializeAuthStatus() {
    if (sharedPreferencesProvider != null) {
      _checkAuthStatus();
    }
  }

  void _checkAuthStatus() {
    final username = sharedPreferencesProvider?.username;
    final password = sharedPreferencesProvider?.password;

    print('Checking auth status...');
    print('Username: $username');
    print('Password: $password');

    if (username != null && username.isNotEmpty && password != null && password.isNotEmpty) {
      _isAuth = true;
      print('User is authenticated');
    } else {
      _isAuth = false;
      print('User is not authenticated');
    }
    notifyListeners();
  }

  Future<void> login(String username, String password, String role, bool hideAnketa) async {
    _isAuth = true;

    await sharedPreferencesProvider!.saveUsername(username);
    await sharedPreferencesProvider!.savePassword(password);
    await sharedPreferencesProvider!.saveRole(role);
    await sharedPreferencesProvider!.saveHideAnketa(hideAnketa);

    print('User logged in: $username');
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuth = false;

    await sharedPreferencesProvider!.clearUsername();
    await sharedPreferencesProvider!.clearPassword();
    await sharedPreferencesProvider!.clearRole();
    await sharedPreferencesProvider!.clearHideAnketa();

    print('User logged out');
    notifyListeners();
  }

}