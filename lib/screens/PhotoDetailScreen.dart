import 'package:flutter/material.dart';

class PhotoDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Фото дома')),
      body: Column(
        children: [
          // Здесь ваш UI для показа фото и деталей
          Image.network('URL_ВАШЕГО_ФОТО'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Сфотографировать нужно так, чтобы видно было сколько в доме этажей. Если в доме есть паркинг - сфотографируйте въезд.'),
          ),
        ],
      ),
    );
  }
}