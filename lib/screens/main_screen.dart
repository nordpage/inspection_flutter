import 'package:flutter/material.dart';
import 'package:inspection/screens/auth_screen.dart';
import 'package:inspection/screens/home_screen.dart';
import 'package:inspection/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/auth_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedDrawerIndex = 0;

  List<DrawerItem> _getDrawerItems(bool isAuth) {
    if (isAuth) {
      return [
        DrawerItem("Главная", Icons.home),
        DrawerItem("О приложении", Icons.info),
        DrawerItem("Политика конфиденциальности", Icons.policy),
        DrawerItem("Разработчик", Icons.person),
        DrawerItem("Выход", Icons.exit_to_app),
      ];
    } else {
      return [
        DrawerItem("Авторизация", Icons.login),
        DrawerItem("Регистрация", Icons.app_registration),
        DrawerItem("О приложении", Icons.info),
        DrawerItem("Политика конфиденциальности", Icons.policy),
        DrawerItem("Разработчик", Icons.person),
      ];
    }
  }

  _getDrawerItemWidget(int pos, bool isAuth) {
    switch (pos) {
      case 0:
        return isAuth ? HomeScreen() : AuthScreen();
      case 1:
        return isAuth ? null : RegisterScreen();
      default:
        return Text("Error");
    }
  }

  _onSelectItem(int index, bool isAuth) async {
    if (isAuth && index == 0) {
      setState(() => _selectedDrawerIndex = index);
    } else if (!isAuth && index < 2) {
      setState(() => _selectedDrawerIndex = index);
    } else if (isAuth && index == 4) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout(context);
    } else {
      _handleExternalLink(index, isAuth);
    }
    Navigator.of(context).pop(); // Закрыть Drawer
  }

  Future<void> _handleExternalLink(int index, bool isAuth) async {
    String url;
    if (isAuth) {
      switch (index) {
        case 1:
          url = "https://my.centr-i.ru/app_priemka_about";
          break;
        case 2:
          url = "https://my.centr-i.ru/app_priemka_popd";
          break;
        case 3:
          url = "https://my.centr-i.ru/app_priemka_dev";
          break;
        default:
          return;
      }
    } else {
      switch (index) {
        case 2:
          url = "https://my.centr-i.ru/app_priemka_about";
          break;
        case 3:
          url = "https://my.centr-i.ru/app_priemka_popd";
          break;
        case 4:
          url = "https://my.centr-i.ru/app_priemka_dev";
          break;
        default:
          return;
      }
    }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    bool isAuth = authProvider.isAuth;

    var drawerItems = _getDrawerItems(isAuth);
    List<Widget> drawerOptions = [];

    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(ListTile(
        leading: Icon(
          d.icon,
          color: i == _selectedDrawerIndex ? Color(0xFF0f7692) : Colors.black,
        ),
        title: Text(
          d.title,
          style: TextStyle(
              color: i == _selectedDrawerIndex
                  ? Color(0xFF0f7692)
                  : Colors.black),
        ),
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i, isAuth),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(drawerItems[_selectedDrawerIndex].title),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    child: Image.asset(
                      "assets/priemka_logo.jpg",
                      height: 60,
                      width: 146,
                    ),
                  ),
                ),
              ),
              Column(children: drawerOptions)
            ],
          ),
        ),
      ),
      body: _getDrawerItemWidget(_selectedDrawerIndex, isAuth),
    );
  }
}

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}
