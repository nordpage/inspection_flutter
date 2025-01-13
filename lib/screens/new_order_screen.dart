import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../provider/shared_preferences_provider.dart';
import '../server/api_service.dart';

class NewOrderScreen extends StatefulWidget {
  NewOrderScreen({Key? key}) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {

  List<String>? _jkList;
  List<String>? _timeList;
  String? _selectedRooms;
  String? _selectedJk;
  String? _selectedTime;
  bool _referPriemka = false;
  bool _referOcenka = false;

  List<String> rooms = [
    "-",
    "1",
    "2",
    "3",
    "4",
    "5",
    "Студия",
  ];

  // Добавим контроллер для даты
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _fioController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _fioController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000), // Начальная дата
      lastDate: DateTime(2100),  // Конечная дата
      locale: const Locale("ru", "RU"), // Локализация (русский язык)
    );

    if (picked != null && picked != now) {
      setState(() {
        _dateController.text = "${picked.day}.${picked.month}.${picked.year}"; // Форматируем дату
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadJkList();
    loadTimeList();
  }


  Future<void> loadJkList() async {
    String data = await rootBundle.loadString('assets/jkList.json');
    List<dynamic> jsonData = jsonDecode(data);
    setState(() {
      _jkList = jsonData.map((item) => item['name'].toString()).toList();
    });
  }

  Future<void> loadTimeList() async {
    String data = await rootBundle.loadString('assets/timeList.json');
    List<dynamic> jsonData = jsonDecode(data);
    setState(() {
      _timeList = jsonData.cast<String>();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {

    final prefsProvider = Provider.of<SharedPreferencesProvider>(context);
    final ApiService apiService = ApiService(prefsProvider);


    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _fioController,
                decoration: const InputDecoration(
                  hintText: "ФИО",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: "+7(123)456-78-90",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(''),
                      Checkbox(value: false, onChanged: (value) {}),
                      const Text('Ссылка для\nбыстрого входа'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Услуги в заказе
              const Text(
                'Услуги в заказе:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                value: false,
                onChanged: (value) {
                  _referOcenka = value!;
                },
                title: const Text('Оценка квартиры'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: false,
                onChanged: (value) {
                  _referPriemka = value!;
                },
                title: const Text('Приемка квартиры от застройщика'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),

              // Жилой комплекс
              const Text(
                'Жилищный комплекс:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _jkList == null
                  ? const CircularProgressIndicator() // Показываем индикатор загрузки
                  : DropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                onSelected: (String? value) {
                  setState(() {
                    _selectedJk = value == '-' ? null : value;
                  });
                },
                dropdownMenuEntries: _jkList!
                    .map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Подъезд, секция
              _buildTextField('Подъезд, секция'),
              const SizedBox(height: 12),

              // Адрес
              _buildTextField('Адрес'),
              const SizedBox(height: 16),

              // Дата и время
              const Text(
                'Осмотр:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true, // Запрещаем ручной ввод
                      decoration: const InputDecoration(
                        hintText: 'Дата',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onTap: () => _selectDate(context), // Открываем DatePicker
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _timeList == null
                        ? const CircularProgressIndicator() // Показываем индикатор загрузки
                        : DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (String? value) {
                        setState(() {
                          _selectedTime = value == '-' ? null : value;
                        });
                      },
                      dropdownMenuEntries: _timeList!
                          .map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(
                            value: value, label: value);
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Количество комнат
              const Text(
                'Количество комнат:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                onSelected: (String? value) {
                  setState(() {
                    _selectedRooms = value == '-' ? null : value;
                  });
                },
                dropdownMenuEntries: rooms
                    .map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Фотографии
              const Text(
                'Фотографии:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildPhotoRow('Дом снаружи'),
              _buildPhotoRow('Дом изнутри'),
              _buildPhotoRow('Квартира'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          final data = {
            "client_phone": _phoneController.text,
            "client_fio": _fioController.text,
            "osmotr_field_1": _dateController.text,
            "osmotr_field_2": _selectedTime ?? "",
            "jk_name": _selectedJk ?? "",
            "refer_priemka": _referPriemka ? 1 : 0,
            "refer_ocenka": _referOcenka ? 1 : 0,
            "lid_ocenka": 0,
            "komnat": int.tryParse(_selectedRooms ?? '0') ?? 0,
            "stoimost_priemki": 2500,
            "stoimost": 3500,
          };

          try {

            final result = await apiService.referNew(data);

            // Показываем уведомление об успехе
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Данные успешно отправлены!')),
            );

            print('Результат: $result');
          } catch (e) {
            // Показываем уведомление об ошибке
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: $e')),
            );

            print('Ошибка при отправке данных: $e');
          }
        },
        backgroundColor: const Color(0xFF0f7692),
        child: const Icon(Icons.check),
      ),
    );
  }

  // Поле ввода
  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // Чекбоксы
  Widget _buildCheckboxTile(String title) {
    return CheckboxListTile(
      value: false,
      onChanged: (value) {},
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // Добавление фото
  Widget _buildPhotoRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, size: 30, color: Color(0xFF0f7692)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}