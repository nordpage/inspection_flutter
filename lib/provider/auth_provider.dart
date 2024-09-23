import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared_preferences_provider.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuth = false;

  bool get isAuth => _isAuth;

  AuthProvider();

  Future<void> initializeAuthStatus(BuildContext context) async {
    await _checkAuthStatus(context);
  }

  Future<void> _checkAuthStatus(BuildContext context) async {
    final sharedPreferencesProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    final username = sharedPreferencesProvider.username;
    final password = sharedPreferencesProvider.password;

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

  Future<void> login(String username, String password, String role, bool hideAnketa, BuildContext context) async {
    _isAuth = true;

    final sharedPreferencesProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    await sharedPreferencesProvider.saveUsername(username);
    await sharedPreferencesProvider.savePassword(password);
    await sharedPreferencesProvider.saveRole(role);
    await sharedPreferencesProvider.saveHideAnketa(hideAnketa);

    print('User logged in: $username');
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    _isAuth = false;

    final sharedPreferencesProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    await sharedPreferencesProvider.clearUsername();
    await sharedPreferencesProvider.clearPassword();
    await sharedPreferencesProvider.clearRole();
    await sharedPreferencesProvider.clearHideAnketa();

    print('User logged out');
    notifyListeners();
  }
}
