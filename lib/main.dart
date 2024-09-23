import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inspection/provider/auth_provider.dart';
import 'package:inspection/provider/navigation_provider.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/screens/auth_screen.dart';
import 'package:inspection/screens/main_screen.dart';
import 'package:inspection/utils/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Обеспечивает инициализацию необходимых плагинов перед запуском приложения
  await Firebase.initializeApp(); // Инициализация Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SharedPreferencesProvider()),
        ChangeNotifierProxyProvider<SharedPreferencesProvider, AuthProvider>(
          create: (context) => AuthProvider(),
          update: (context, sharedPreferencesProvider, authProvider) {
            authProvider!.initializeAuthStatus(context);
            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: customTheme,
        home: MainScreen(),
      ),

      // MaterialApp(
      //     debugShowCheckedModeBanner: false,
      //     home: ChatMainScreen(),
      // )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return AuthScreen();
  }
}
