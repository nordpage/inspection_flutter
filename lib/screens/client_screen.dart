import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inspection/screens/preview_screen.dart';
import 'package:inspection/screens/video_preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/map_section.dart';
import '../provider/auth_provider.dart';
import '../provider/client_provider.dart';
import '../provider/shared_preferences_provider.dart';
import '../services/database_service.dart';
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

class _ClientScreenState extends State<ClientScreen> with RouteAware{
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();
  late SharedPreferencesProvider prefsProvider;
  late ClientProvider clientProvider;
  DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    clientProvider = Provider.of<ClientProvider>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  didPopNext() {
    clientProvider.checkCanSend();
    clientProvider.getMap();
  }

  @override
  dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<Duration?> _getVideoDuration(File videoFile) async {
    try {
      final video = await VideoPlayerController.file(videoFile);
      await video.initialize();
      final duration = video.value.duration;
      await video.dispose();
      return duration;
    } catch (e) {
      return null;
    }
  }

  Widget? _getSectionSubtitle(MapSection section, bool hasFilesToUpload, bool isVideo) {
    bool hasUnsentPhotos = (section.contentList != null &&
        section.contentList!.isNotEmpty &&
        section.contentList!.any((item) =>
            item.status == StatusContent.DEFAULT)) &&
        hasFilesToUpload;

    if (hasUnsentPhotos) {
      return Text(
        isVideo == true ? 'новые (не отправленные) видео' : 'новые (не отправленные) фото',
        style: TextStyle(color: Colors.red),
      );
    }
    return null;
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
                Consumer<ClientProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 26,
                            child: LinearProgressIndicator(
                              value: provider.progressPercentage / 100,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF02BBA3)),
                              backgroundColor: Colors.grey[200],
                            )),
                        const SizedBox(height: 8),
                        Text('${(provider.progressPercentage).toInt()}%', style: const TextStyle(color: Color(0xFF02BBA3), fontWeight: FontWeight.bold, fontSize: 16),),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
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
                    const Text(
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await provider.getMap();
                    },
                    child: Consumer<ClientProvider>(
                      builder: (context, provider, child) => ListView.builder(
                        itemCount: provider.mapResult!.sections!.length,
                        itemBuilder: (context, index) {
                          MapSection section = provider.mapResult!.sections![index];
                           bool isUploading = provider.uploadProgress.containsKey(section.id.toString());
                          bool hasFilesToUpload = provider.filesToUpload[section.id] ?? false;

                          return Card(
                            child: ListTile(
                              title: Text(section.name ?? ''),
                              subtitle: _getSectionSubtitle(section, hasFilesToUpload, section.name == "Видео"),
                              trailing: isUploading
                                  ? const CircularProgressIndicator()
                                  : provider.getIcon(section),
                              onTap: () async {
                                if (provider.isUploading) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Дождитесь завершения загрузки'))
                                  );
                                  return;
                                }
                                final hasContent = section.contentList?.isNotEmpty ?? false;
                                final isVideo = section.name == "Видео";

                                if (hasContent) {
                                  if (isVideo) {
                                    final content = await _dbService.getContentsForSection(section.id!);
                                    if (content.isEmpty) return;

                                    final videoFile = File(content.first.fileName!);
                                    if (!videoFile.existsSync()) return;

                                    final duration = await _getVideoDuration(videoFile);
                                    if (duration == null) return;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPreviewScreen(
                                          capturedVideo: videoFile,
                                          sectionId: section.id!, duration: duration!,
                                        ),
                                      ),
                                    );
                                  } else {
                                    final contents = await _dbService.getContentsForSection(section.id!);
                                    final files = contents
                                        .map((c) => File(c.fileName!))
                                        .where((f) => f.existsSync())
                                        .toList();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PreviewScreen(
                                          capturedPhotos: files,
                                          title: section.name ?? '',
                                          sectionId: section.id!,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => ContentSectionPage(
                                      sections: provider.mapResult!.sections!,
                                      initialIndex: index,
                                      documents: provider.mapResult!.documents,
                                      isVideo: isVideo,
                                    ),
                                  ));
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ClientProvider>(
                  builder: (context, provider, child) {
                    return SizedBox(
                      width: 320,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: provider.canSend ? provider.sendData : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: provider.canSend ? const Color(0xFF02BBA3) : Colors.grey[300],
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: provider.canSend ? 2 : 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'НАПРАВИТЬ НА ПРОВЕРКУ',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: provider.canSend ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Когда сделаны все фотографии и видео",
                              style: TextStyle(
                                fontSize: 12.0,
                                color: provider.canSend ? Colors.white70 : Colors.grey[500],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
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