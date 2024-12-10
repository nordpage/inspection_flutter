import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/map_section.dart';
import '../provider/auth_provider.dart';
import '../provider/client_provider.dart';
import '../provider/shared_preferences_provider.dart';
import '../utils/status_content.dart';
import 'content_section_page.dart';

class ClientScreen extends StatefulWidget {
  final bool isPermissionChecked;
  final bool isLocationPermissionGranted;
  final VoidCallback checkLocationPermission;

  const ClientScreen({
    super.key,
    required this.isPermissionChecked,
    required this.isLocationPermissionGranted,
    required this.checkLocationPermission
  });

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  late SharedPreferencesProvider prefsProvider;
  late ClientProvider clientProvider;

  @override
  void initState() {
    super.initState();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    clientProvider = Provider.of<ClientProvider>(context, listen: false);
  }

  Icon getIcon(MapSection mapSection) {
    IconData iconData = Icons.circle_outlined;
    Color iconColor = Color(0xffaaaaaa);

    if ((mapSection.contentList == null || mapSection.contentList!.isEmpty) &&
        (mapSection.minPhoto ?? 0) > 0) {
      iconData = Icons.circle_outlined;
    } else if (mapSection.contentList != null &&
        mapSection.contentList!.isNotEmpty &&
        mapSection.contentList!.length < (mapSection.minPhoto ?? 0)) {
      iconData = Icons.circle_outlined;
    } else if (mapSection.contentList != null &&
        mapSection.contentList!.length >= (mapSection.minPhoto ?? 0)) {
      bool hasPendingItems = mapSection.contentList!.any((item) =>
      item.status == StatusContent.ADDED || item.status == StatusContent.DEFAULT);

      if (hasPendingItems) {
        iconData = Icons.watch_later;
      } else {
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
      }
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (context, provider, child) {
        if (!widget.isPermissionChecked) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.isLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null) {
          return Scaffold(
            body: Center(child: Text(provider.errorMessage!)),
          );
        }

        if (provider.mapResult == null) {
          return Scaffold(
            body: Center(child: Text('Нет данных для отображения')),
          );
        }

        return Scaffold(
          body: !widget.isLocationPermissionGranted
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/priemka_logo.jpg',
                  height: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'Для продолжения работы в модуле «Самоосмотр» необходимо предоставить доступ к данным о местоположении.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.checkLocationPermission,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Предоставить доступ',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Выйти из аккаунта',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: provider.progressPercentage,
                ),
                SizedBox(height: 8),
                Text('${(provider.progressPercentage * 100).toInt()}%'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "Адрес: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(provider.mapResult!.address ?? 'Не указан'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Номер заказа: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(prefsProvider.username!),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "ФИО: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(provider.mapResult!.clientFio ?? 'Не указан'),
                    ),
                  ],
                ),
                if (provider.canSend) ...[
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.sendData,
                    child: Text('Отправить'),
                  ),
                ] else
                  SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await provider.getMap();
                    },
                    child: ListView.builder(
                      itemCount: provider.mapResult!.sections!.length,
                      itemBuilder: (context, index) {
                        MapSection section = provider.mapResult!.sections![index];
                        return Card(
                          child: ListTile(
                            title: Text(section.name ?? ''),
                            trailing: getIcon(section),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContentSectionPage(
                                    sections: provider.mapResult!.sections!,
                                    initialIndex: index,
                                    documents: provider.mapResult!.documents,
                                    isVideo: section.name == "Видео",
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ExpansionTile(
                  title: Text("Обозначения"),
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.access_time, color: Colors.grey),
                      title: Text('Фотографии еще не направлены на проверку'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle_outline, color: Colors.grey),
                      title: Text('Фотографии еще не проверены специалистом'),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('Фотографии проверены специалистом'),
                    ),
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Colors.red),
                      title: Text('Валидация фотографии не прошла'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}