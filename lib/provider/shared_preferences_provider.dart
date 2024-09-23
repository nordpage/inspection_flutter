import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesProvider with ChangeNotifier {
  SharedPreferences? _preferences;

  String? _username;
  String? _password;
  String? _role;
  bool? _hideAnketa;

  String? get username => _username;
  String? get password => _password;
  String? get role => _role;
  bool? get hideAnketa => _hideAnketa;

  SharedPreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    _username = _preferences?.getString('username') ?? '';
    _password = _preferences?.getString('password') ?? '';
    _role = _preferences?.getString('role') ?? '';
    _hideAnketa = _preferences?.getBool('hide_anketa') ?? false;

    // Отладочный вывод
    print('Loaded preferences:');
    print('Username: $_username');
    print('Password: $_password');
    print('Role: $_role');
    print('Hide Anketa: $_hideAnketa');

    notifyListeners();
  }

  Future<void> saveUsername(String username) async {
    _username = username;
    await _preferences?.setString('username', username);
    notifyListeners();
  }

  Future<void> savePassword(String password) async {
    _password = password;
    await _preferences?.setString('password', password);
    notifyListeners();
  }

  Future<void> saveRole(String role) async {
    _role = role;
    await _preferences?.setString('role', role);
    notifyListeners();
  }

  Future<void> saveHideAnketa(bool hideAnketa) async {
    _hideAnketa = hideAnketa;
    await _preferences?.setBool('hide_anketa', hideAnketa);
    notifyListeners();
  }

  Future<void> clearUsername() async {
    _username = null;
    await _preferences?.remove('username');
    notifyListeners();
  }

  Future<void> clearPassword() async {
    _password = null;
    await _preferences?.remove('password');
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = null;
    await _preferences?.remove('role');
    notifyListeners();
  }

  Future<void> clearHideAnketa() async {
    _hideAnketa = null;
    await _preferences?.remove("hide_anketa");
    notifyListeners();
  }
}