import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inspection/provider/auth_provider.dart';
import 'package:inspection/provider/client_provider.dart';
import 'package:inspection/provider/navigation_provider.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/screens/main_screen.dart';
import 'package:inspection/server/api_service.dart';
import 'package:inspection/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(); // Заменяем тут

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notificationsPlugin.initialize(initSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация плагинов
  await Firebase.initializeApp(); // Инициализация Firebase
  await setupNotifications(); // Инициализация уведомлений
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SharedPreferencesProvider()),

        ProxyProvider<SharedPreferencesProvider, ApiService>(
          update: (context, sharedPrefsProvider, _) =>
              ApiService(sharedPrefsProvider),
        ),


        ChangeNotifierProvider(
          create: (context) => ClientProvider(
              Provider.of<SharedPreferencesProvider>(context, listen: false)
          )..getMap(),
        ),

        ChangeNotifierProxyProvider<SharedPreferencesProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (context, sharedPrefsProvider, authProvider) =>
          authProvider!..updateSharedPreferencesProvider(sharedPrefsProvider),
        ),

        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        navigatorObservers: [RouteObserver<PageRoute>()],
        debugShowCheckedModeBanner: false,
        theme: customTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // Английский
          Locale('ru', ''), // Русский
        ],
        home: const MainScreen(),
      ),
    );
  }
}