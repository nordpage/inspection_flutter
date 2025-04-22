import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:inspection/provider/auth_provider.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/widgets/progress_dialog.dart';
import 'package:provider/provider.dart';

import '../server/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  static const routeName = '/auth';


  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late ApiService apiService;

  TextEditingController loginController = TextEditingController();
  bool _loginValidate = false;
  TextEditingController passwordController = TextEditingController();
  bool _passwordValidate = false;

  @override
  void initState() {
    super.initState();
    final prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    apiService = ApiService(prefsProvider);
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    void _login(String username, String password) {
      apiService.login(username, password, (status, code, response) {
        if (status == 'OK') {
          ProgressDialog.show(context, "Пожалуйста подождите ...", 3, () {
            authProvider.login(username, password, response!.role, response.hideAnketa);
          });
        } else if (status == 'INTERNET') {
          print('Internet connection problem.');
          // Обработка проблем с интернетом
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Проблема с авторизацией")),
          );
          // Обработка ошибки входа
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/priemka_auth_logo.jpg",
                          width: 300,
                          height: 100,
                        ),
                        SizedBox(height: 40),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: loginController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: "Логин",
                                errorText: _loginValidate ? "Поле \'Логин\' не может быть пустым" : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: InputDecoration(
                                labelText: "Пароль",
                                errorText: _passwordValidate ? "Поле \'Пароль\' не может быть пустым" : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 34),
                        SizedBox(
                          height: 60,
                          width: 180,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loginValidate = loginController.text.isEmpty;
                                _passwordValidate = passwordController.text.isEmpty;
                              });
                              if (!_loginValidate && !_passwordValidate) {
                                _login(loginController.text, passwordController.text);
                              }
                            },
                            child: Text("войти в систему"),
                          ),
                        ),
                        SizedBox(height: 70),
                        SizedBox(
                          height: 100,
                          width: 300,
                          child: OutlinedButton.icon(
                            icon: Image.asset(
                              "assets/ic_question_answer.png",
                              width: 32,
                              height: 32,
                            ),
                            onPressed: () {},
                            label: Text(
                              "описание возможностей приложения\nи чат со специалистом",
                              textAlign: TextAlign.center,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(width: 1.0, color: Color(0xFF0f7692)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
