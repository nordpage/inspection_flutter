import 'package:flutter/material.dart';
import 'package:inspection/provider/client_provider.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/screens/client_screen.dart';
import 'package:inspection/screens/referrer_screen.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ClientProvider clientProvider;
  late SharedPreferencesProvider prefsProvider;
  bool isLocationPermissionGranted = false;
  bool isPermissionChecked = false;
  String orderNumber = '';
  String role = '';

  @override
  void initState() {
    super.initState();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    clientProvider = Provider.of<ClientProvider>(context, listen: false);
    orderNumber = prefsProvider.username!;
    role = prefsProvider.role!;
    checkLocationPermission();
  }

  @override
  void didPopNext() {
    orderNumber = prefsProvider.username!;
    role = prefsProvider.role!;
  }

  Future<void> checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      setState(() {
        isLocationPermissionGranted = true;
        isPermissionChecked = true; // Обновляем флаг после проверки
      });
    } else if (status.isDenied || status.isPermanentlyDenied) {
      PermissionStatus newStatus = await Permission.location.request();
      setState(() {
        isLocationPermissionGranted = newStatus.isGranted;
        isPermissionChecked = true; // Обновляем флаг после запроса
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(role == "client") {
      return ClientScreen(isPermissionChecked: isPermissionChecked, isLocationPermissionGranted: isLocationPermissionGranted, checkLocationPermission: checkLocationPermission);
    } else {
      return ReferrerScreen();
    }
  }


}