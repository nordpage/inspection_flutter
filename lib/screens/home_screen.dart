import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inspection/models/map_content.dart';
import 'package:inspection/models/map_result.dart';
import 'package:inspection/models/map_section.dart';
import 'package:inspection/models/questionnaire_sections.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import 'package:inspection/utils/status_content.dart';
import 'package:provider/provider.dart';

import '../server/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final prefsProvider = Provider.of<SharedPreferencesProvider>(context);
    ApiService apiService = ApiService(prefsProvider);

    return FutureBuilder(
        future: apiService.getMap(),
        builder: (BuildContext context, AsyncSnapshot<MapResult> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Адрес: ", style: TextStyle(fontWeight: FontWeight.w500),),
                      Text(snapshot.data!.address ?? "-"),
                    ],
                  ),
                  SizedBox(height: 12,),
                  Row(
                    children: [
                      Text("Заказ: ", style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(prefsProvider.username ?? "-"),
                    ],
                  ),
                  SizedBox(height: 12,),
                  Row(
                    children: [
                      Text("ФИО: ", style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(snapshot.data!.clientFio ?? "-"),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.sections!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: ListTile(
                            title: Text(snapshot.data!.sections![index].name),
                            trailing: getIcon(snapshot.data!.sections![index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            debugPrint(snapshot.error!.toString());
            return Center(child: Row(
              children: [
                Icon(Icons.error_outline),
                Text(snapshot.error!.toString())
              ],
            ));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}

SvgPicture getIcon(MapSection mapSection) {
  String? imageAsset;
  Color iconColor = Color(0xffaaaaaa);

  if ((mapSection.contentList == null || mapSection.contentList!.isEmpty) && mapSection.minPhoto! > 0) {
    imageAsset = "assets/circle.svg";
  }
  else if (mapSection.contentList != null && mapSection.contentList!.isNotEmpty &&
      mapSection.contentList!.length < mapSection.minPhoto!) {
    imageAsset = "assets/circle.svg";
  }
  else if (mapSection.contentList != null && mapSection.contentList!.length >= mapSection.minPhoto!) {
    bool hasPendingItems = mapSection.contentList!.any((item) =>
    item.status == StatusContent.ADDED || item.status == StatusContent.DEFAULT);

    if (hasPendingItems) {
      imageAsset = "assets/watch_later.svg";
    } else {
      imageAsset = "assets/ok_outline.svg";
    }
  }

  // Если ни одно из условий не выполнено, не отображаем иконку
  if (imageAsset == null) {
    return SvgPicture.asset("assets/circle.svg", height: 24, width: 24, color: Colors.transparent); // Пустая иконка
  }

  return SvgPicture.asset(
    imageAsset,
    height: 24,
    width: 24,
    color: iconColor,
  );
}

