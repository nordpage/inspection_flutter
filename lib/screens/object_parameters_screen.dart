import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/client_provider.dart';
import '../server/api_service.dart';
import '../models/questionnaire_sections.dart';

class ObjectParametersScreen extends StatefulWidget {
  static const routeName = '/object-parameters';

  @override
  _ObjectParametersScreenState createState() => _ObjectParametersScreenState();
}

class _ObjectParametersScreenState extends State<ObjectParametersScreen> {
  List<QuestionnaireSections> sections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaireData();
  }

  Future<void> _loadQuestionnaireData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Загружаем базовую структуру
      final data = await apiService.getQuestionnaire();

      // Загружаем сохраненные значения
      final anketa = await apiService.getMapAnketa();

      // Обновляем значения в секциях на основе полученных данных из анкеты
      for (var section in data) {
        switch(section.id) {
          case 'komnat':
            section.defValue = anketa.komnat;
            break;
          case 'san_uzel':
            section.defValue = anketa.sanUzel;
            break;
          case 'balkon':
            section.defValue = anketa.balkon;
            break;
          case 'storon_s_oknami':
            section.defValue = anketa.storonSOknami;
            break;
          case 'dop_pomesheniy':
            section.defValue = anketa.dopPomesheniy;
            break;
          case 'is_first_etazh':
            section.defValue = anketa.isFirstEtazh;
            break;
          case 'is_musoroprovod':
            section.defValue = anketa.isMusoroprovod;
            break;
          case 'is_lift':
            section.defValue = anketa.isLift;
            break;
        }

        // Особая обработка для switch-элементов - убедимся что значение будет 0 или 1
        if (section.id == 'is_first_etazh' ||
            section.id == 'is_musoroprovod' ||
            section.id == 'is_lift') {
          section.defValue = section.defValue == 1 ? 1 : 0;
        }
      }

      setState(() {
        sections = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading questionnaire: $e");
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке данных'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildCounter(QuestionnaireSections section) {
    int defValue = section.defValue ?? 0;
    int minValue = section.minValue ?? 0;
    int maxValue = section.maxValue == 0 ? 999 : section.maxValue!;  // Устанавливаем max_value как 999, если 0

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(section.text ?? '', style: const TextStyle(fontSize: 16),),
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (defValue > minValue) {
                        defValue -= 1;
                        section.defValue = defValue;  // Обновляем значение в модели
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.remove),
                ),
              ),
              SizedBox(width: 10),
              Text(defValue.toString(), style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              SizedBox(
                width: 32,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (defValue < maxValue) {
                        defValue += 1;
                        section.defValue = defValue;  // Обновляем значение в модели
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSwitch(QuestionnaireSections section) {
    bool isSwitched = section.defValue == 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(section.text ?? '', style: const TextStyle(fontSize: 16),),
        Switch(
          value: isSwitched,
          activeColor: Color(0xFF0f7692),
          inactiveThumbColor: Color(0xFF0f7692),
          onChanged: (value) {
            setState(() {
              section.defValue = value ? 1 : 0;
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveParameters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);

      Map<String, int> body = {};
      for (var section in sections) {
        body[section.id!.toString()] = section.defValue!;
      }

      await apiService.getMapWithBody(jsonEncode(body));

      // Обновляем данные перед возвратом
      await clientProvider.getMap();

      if (mounted) {
        Navigator.pop(context, true); // Передаем флаг успешного сохранения
      }
    } catch (e) {
      print("Error saving parameters: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении данных'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Параметры объекта'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  if (section.id == 'is_first_etazh' ||
                      section.id == 'is_musoroprovod' ||
                      section.id == 'is_lift') {
                    return buildSwitch(section);
                  } else {
                    return buildCounter(section);
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _saveParameters,
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text('СОХРАНИТЬ'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}