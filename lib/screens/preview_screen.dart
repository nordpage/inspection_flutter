import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  final String title;
  final List<XFile> capturedPhotos;

  PreviewScreen({required this.capturedPhotos, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Действие для кнопки "Примеры фото"
              },
              icon: Icon(Icons.photo_camera),
              label: Text('Примеры фото'),
            ),
            Expanded(
              child: GridView.builder(
                itemCount: capturedPhotos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Количество колонок в сетке
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          File(capturedPhotos[index].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Логика удаления фото
                          },
                        ),
                      ),
                    ],
                  );
                },
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
            )
          ],
        ),
      ),
    );
  }
}