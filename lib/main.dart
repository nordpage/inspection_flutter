import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inspection/provider/auth_provider.dart';
import 'package:inspection/provider/client_provider.dart';
import 'package:inspection/provider/navigation_provider.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/screens/main_screen.dart';
import 'package:inspection/server/api_service.dart';
import 'package:inspection/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация плагинов
  await Firebase.initializeApp(); // Инициализация Firebase
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Инициализируем SharedPreferencesProvider
        ChangeNotifierProvider(create: (_) => SharedPreferencesProvider()),

        // ApiService зависит от SharedPreferencesProvider
        ProxyProvider<SharedPreferencesProvider, ApiService>(
          update: (context, sharedPrefsProvider, _) =>
              ApiService(sharedPrefsProvider),
        ),

        // ClientProvider зависит от ApiService
        ChangeNotifierProxyProvider<ApiService, ClientProvider>(
          create: (_) => ClientProvider(apiService: null),
          update: (context, apiService, clientProvider) =>
          clientProvider!..updateApiService(apiService),
        ),

        // AuthProvider зависит от SharedPreferencesProvider
        ChangeNotifierProxyProvider<SharedPreferencesProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (context, sharedPrefsProvider, authProvider) =>
          authProvider!..updateSharedPreferencesProvider(sharedPrefsProvider),
        ),

        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: customTheme,
        home: MainScreen(),
      ),
    );
  }
}