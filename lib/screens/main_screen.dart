import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/auth_provider.dart';
import '../provider/shared_preferences_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'new_order_screen.dart';
import 'object_parameters_screen.dart';
import 'register_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedDrawerIndex = 0;

  // Список заголовков для AppBar
  final List<String> _titles = [
    "Главная",
    "Новый заказ",
    "Настройки",
    "О приложении",
    "Политика конфиденциальности",
    "Разработчик",
  ];

  void _onSelectItem(int index, bool isAuth, String role) async {
    Navigator.of(context).pop(); // Close the Drawer

    setState(() {
      _selectedDrawerIndex = index;
    });

    if (!isAuth) {
      // Guest mode
      if (index >= 2) {
        _handleExternalLink(index, isAuth);
      }
    } else {
      // Authenticated mode
      if (role == "client") {
        if (index == 4) {
          // Handle logout for client
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          _selectedDrawerIndex = 0;
          await authProvider.logout();
        } else if (index >= 1) {
          _handleExternalLink(index, isAuth);
        }
      } else if (role == "CARETAKER") {
        if (index == 3) {
          // Handle logout for caretaker
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          _selectedDrawerIndex = 0;
          await authProvider.logout();
        } else if (index >= 2) {
          _handleExternalLink(index, isAuth);
        }
      }
    }
  }

  Future<void> _handleExternalLink(int index, bool isAuth) async {
    String url = isAuth
        ? {
      1: "https://my.centr-i.ru/app_priemka_about",
      2: "https://my.centr-i.ru/app_priemka_popd",
      3: "https://my.centr-i.ru/app_priemka_dev",
    }[index]!
        : {
      2: "https://my.centr-i.ru/app_priemka_about",
      3: "https://my.centr-i.ru/app_priemka_popd",
      4: "https://my.centr-i.ru/app_priemka_dev",
    }[index]!;

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _getDrawerItemWidget(int pos, bool isAuth, String role) {
    if (!isAuth) {
      // Гостевой режим
      if (pos == 0) {
        return const AuthScreen();
      } else if (pos == 1) {
        return const RegisterScreen();
      }
    } else {
      // Авторизованный режим
      if (role == "client") {
        switch (pos) {
          case 0: // Главная
            return const HomeScreen();
          default:
            return Container(); // Пустой экран по умолчанию
        }
      } else if (role == "CARETAKER") {
        switch (pos) {
          case 0: // Главная
            return const HomeScreen();
          case 1: // Новый заказ
            return NewOrderScreen();
          case 2: // Настройки
            return const SettingsScreen();
          default:
            return Container(); // Пустой экран по умолчанию
        }
      }
    }

    return Container(); // Пустой экран по умолчанию
  }

  /// Возвращает список действий (actions) для AppBar на основе выбранного индекса
  List<Widget> _getAppBarActions(int index, String role, bool hideAnketa) {
    if (role == "client" && !hideAnketa) {
      switch (index) {
        case 0: // Главная
          return [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ObjectParametersScreen(), // Экран с параметрами объекта
                  ),
                );
              },
            ),
          ];
        default:
          return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final prefProvider = Provider.of<SharedPreferencesProvider>(context);
    bool isAuth = authProvider.isAuth;
    String role = prefProvider.role ?? "guest";
    bool hideAnketa = prefProvider.hideAnketa ?? false;

    var drawerWidget = isAuth
        ? (role == "CARETAKER")
        ? ProfessionalDrawer(
      selectedIndex: _selectedDrawerIndex,
      onSelectItem: (index) => _onSelectItem(index, isAuth, role),
    )
        : ClientDrawer(
      selectedIndex: _selectedDrawerIndex,
      onSelectItem: (index) => _onSelectItem(index, isAuth, role),
    )
        : GuestDrawer(
      selectedIndex: _selectedDrawerIndex,
      onSelectItem: (index) => _onSelectItem(index, isAuth, role),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedDrawerIndex]), // Меняем заголовок AppBar
        actions: _getAppBarActions(_selectedDrawerIndex, role, hideAnketa), // Добавляем actions
      ),
      drawer: drawerWidget,
      body: _getDrawerItemWidget(_selectedDrawerIndex, isAuth, role),
    );
  }
}

class ClientDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;

  const ClientDrawer({required this.selectedIndex, required this.onSelectItem});

  @override
  Widget build(BuildContext context) {
    final items = [
      DrawerItem("Главная", Icons.home),
      DrawerItem("О приложении", Icons.info),
      DrawerItem("Политика конфиденциальности", Icons.policy),
      DrawerItem("Разработчик", Icons.person),
      DrawerItem("Выход", Icons.exit_to_app),
    ];

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildDrawerItems(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
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
    );
  }

  Widget _buildDrawerItems(List<DrawerItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;

        return ListTile(
          leading: Icon(
            item.icon,
            color: isSelected ? const Color(0xFF0f7692) : Colors.black,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0f7692) : Colors.black,
            ),
          ),
          selected: isSelected,
          onTap: () => onSelectItem(index),
        );
      },
    );
  }
}

class ProfessionalDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;

  const ProfessionalDrawer({
    required this.selectedIndex,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      DrawerItem("Главная", Icons.home),
      DrawerItem("Новый заказ", Icons.note_add),
      DrawerItem("Настройки", Icons.settings),
      DrawerItem("Выход", Icons.exit_to_app),
    ];

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildDrawerItems(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
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
    );
  }

  Widget _buildDrawerItems(List<DrawerItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;

        return ListTile(
          leading: Icon(
            item.icon,
            color: isSelected ? const Color(0xFF0f7692) : Colors.black,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0f7692) : Colors.black,
            ),
          ),
          selected: isSelected,
          onTap: () => onSelectItem(index),
        );
      },
    );
  }
}

class GuestDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;

  const GuestDrawer({required this.selectedIndex, required this.onSelectItem});

  @override
  Widget build(BuildContext context) {
    final items = [
      DrawerItem("Авторизация", Icons.login),
      DrawerItem("Регистрация", Icons.app_registration),
      DrawerItem("О приложении", Icons.info),
      DrawerItem("Политика конфиденциальности", Icons.policy),
      DrawerItem("Разработчик", Icons.person),
    ];

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildDrawerItems(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
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
    );
  }

  Widget _buildDrawerItems(List<DrawerItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;

        return ListTile(
          leading: Icon(
            item.icon,
            color: isSelected ? const Color(0xFF0f7692) : Colors.black,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0f7692) : Colors.black,
            ),
          ),
          selected: isSelected,
          onTap: () => onSelectItem(index),
        );
      },
    );
  }
}

class DrawerItem {
  final String title;
  final IconData icon;

  DrawerItem(this.title, this.icon);
}