import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:inspection/screens/referrer_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../provider/shared_preferences_provider.dart';
import '../server/api_service.dart';
import '../utils/utils.dart';
import '../widgets/custom_checkbox.dart';
import '../models/osmotr_item.dart';

/// Вспомогательный класс для ЖК, содержащий название и цвет.
/// Пример JSON элемента: {"name":"Бутово парк 2", "category":"комфорт", "summa_plus":0, "color":"#602d72"}
class JkItem {
  final String name;
  final String color;

  JkItem({required this.name, required this.color});

  factory JkItem.fromJson(Map<String, dynamic> json) {
    return JkItem(
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }
}

class NewOrderScreen extends StatefulWidget {
  final OsmotrItem? orderToEdit;

  const NewOrderScreen({Key? key, this.orderToEdit}) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  List<JkItem>? _jkItems;
  List<String>? _bankList;
  List<String>? _timeList;

  // Cached dropdown entries for ЖК items
  List<DropdownMenuEntry<JkItem>> _jkEntries = [];

  JkItem? _selectedJkItem;
  String? _selectedBank;
  String? _selectedTime;
  String? _selectedRooms;

  bool _referPriemka = false;
  bool _referOcenka = false;
  bool _lidOcenka = false;
  bool _getMoney = false;

  Map<String, List<File>> _photosByCategory = {
    'Дом снаружи': [],
    'Дом изнутри': [],
    'Квартира': [],
  };
  String _currentPhotoCategory = 'Дом снаружи';

  // Список вариантов количества комнат
  List<String> rooms = ["-", "1", "2", "3", "4", "5", "Студия"];

  // Контроллеры для текстовых полей
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fioController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // Дата осмотра (osmotr_field_1)
  final TextEditingController _priceController = TextEditingController();  // Стоимость приемки
  final TextEditingController _noteController = TextEditingController();   // Примечания для приемки (notes)
  final TextEditingController _priceOcenkaController = TextEditingController(); // Стоимость оценки
  final TextEditingController _noteOcenkaController = TextEditingController();  // Примечание к оценке (expert или iliteViewName)
  final TextEditingController _sectionController = TextEditingController();  // Подъезд/секция
  final TextEditingController _addressController = TextEditingController();  // Адрес осмотра
  late SharedPreferencesProvider prefsProvider;

  // Форматтер для маски телефона +7(###) ###-##-##
  final MaskTextInputFormatter _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7(###) ###-##-##',
    filter: { '#': RegExp(r'\d') },
  );

  // Режим редактирования
  bool _isEditMode = false;
  int? _orderId;

  @override
  void initState() {
    super.initState();
    loadJkList();
    loadTimeList();
    loadBankList();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);

    if (widget.orderToEdit != null) {
      _isEditMode = true;
      _orderId = widget.orderToEdit!.id;
      _loadOrderData(widget.orderToEdit!);
    }
  }

  // Заполнение данных заказа при редактировании
  void _loadOrderData(OsmotrItem order) {
    _phoneController.text = order.clientPhone;
    _fioController.text = order.clientFio;
    _dateController.text = order.osmotrField1;
    _selectedTime = order.osmotrField2;
    if (_jkItems != null) {
      try {
        _selectedJkItem = _jkItems!.firstWhere((item) => item.name == order.jkName);
      } catch (e) {
        _selectedJkItem = null;
      }
    }
    _referPriemka = order.referPriemka == 1;
    _referOcenka = order.referOcenka == 1;
    _lidOcenka = order.lidOcenka == 1;
    _getMoney = order.moneyExpert == 1;
    _selectedRooms = order.komnat.toString();

    // Prefill address and section fields
    _addressController.text = order.address ?? '';
    _sectionController.text = order.section ?? '';

    if (_referPriemka) {
      _priceController.text = order.stoimostPriemki.toString();
      _noteController.text = order.primechaniya;
    }

    if (_referOcenka) {
      _priceOcenkaController.text = order.stoimost.toString();
      _noteOcenkaController.text = order.ecspertNaOsmotreTxt;
      _selectedBank = order.otchetDlya;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fioController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _priceOcenkaController.dispose();
    _noteOcenkaController.dispose();
    _sectionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Загрузка списка ЖК из assets, парсинг JSON в объекты JkItem
  Future<void> loadJkList() async {
    String data = await rootBundle.loadString('assets/jkList.json');
    List<dynamic> jsonData = jsonDecode(data);
    setState(() {
      _jkItems = jsonData.map((item) => JkItem.fromJson(item)).toList();
      // Populate cached dropdown entries for ЖК items
      _jkEntries = _jkItems!.map<DropdownMenuEntry<JkItem>>((item) {
        return DropdownMenuEntry<JkItem>(value: item, label: item.name);
      }).toList();
      if (widget.orderToEdit != null) {
        try {
          _selectedJkItem = _jkItems!.firstWhere(
                  (item) => item.name == widget.orderToEdit!.jkName);
        } catch (e) {
          _selectedJkItem = null;
        }
      }
    });
  }

  // Загрузка списка банков из assets
  Future<void> loadBankList() async {
    String data = await rootBundle.loadString('assets/bankList.json');
    List<dynamic> jsonData = jsonDecode(data);
    setState(() {
      _bankList = jsonData.cast<String>();
    });
  }

  // Загрузка списка времени из assets
  Future<void> loadTimeList() async {
    String data = await rootBundle.loadString('assets/timeList.json');
    List<dynamic> jsonData = jsonDecode(data);
    setState(() {
      _timeList = jsonData.cast<String>();
    });
  }

  // Выбор даты через DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("ru", "RU"),
    );
    if (picked != null) {
      setState(() {
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        _dateController.text = "$day.$month.${picked.year}";
      });
    }
  }

  // Функция обработки изображения: декодирование, изменение размера, опциональный поворот, сохранение
  Future<File> _processAndSaveImage({
    required File originalFile,
    required String newFileName,
    int targetWidth = 1080,
    int quality = 80,
    int rotateAngle = 0,
  }) async {
    // Чтение байтов исходного файла
    Uint8List imageBytes = await originalFile.readAsBytes();

    // Декодирование изображения с помощью пакета image
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Не удалось декодировать изображение');
    }

    // Поворот, если требуется
    img.Image processedImage = rotateAngle != 0
        ? img.copyRotate(originalImage, rotateAngle)
        : originalImage;

    // Изменение размера до targetWidth с сохранением пропорций
    processedImage = img.copyResize(processedImage, width: targetWidth);

    // Кодирование изображения в JPEG с заданным качеством
    List<int> jpgBytes = img.encodeJpg(processedImage, quality: quality);

    // Получение директории для сохранения
    Directory directory = await getApplicationDocumentsDirectory();
    String newPath = '${directory.path}/$newFileName.jpg';

    // Создание нового файла и запись JPEG-данных
    File newFile = File(newPath);
    await newFile.writeAsBytes(jpgBytes);
    return newFile;
  }

  // Выбор фото с камеры с обработкой изображения
  Future<void> _pickImageFromCamera() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      File originalFile = File(image.path);
      String fileName =
          'photo_${DateTime.now().millisecondsSinceEpoch}_${_currentPhotoCategory}';
      try {
        File processedFile = await _processAndSaveImage(
          originalFile: originalFile,
          newFileName: fileName,
          rotateAngle: 0, // Задайте нужный угол поворота, если необходимо
        );
        setState(() {
          _photosByCategory[_currentPhotoCategory]!.add(processedFile);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обработки фото: $e')),
        );
      }
    }
  }

  // Выбор фото из галереи с обработкой изображения
  Future<void> _pickImageFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      File originalFile = File(image.path);
      String fileName =
          'photo_${DateTime.now().millisecondsSinceEpoch}_${_currentPhotoCategory}';
      try {
        File processedFile = await _processAndSaveImage(
          originalFile: originalFile,
          newFileName: fileName,
          rotateAngle: 0,
        );
        setState(() {
          _photosByCategory[_currentPhotoCategory]!.add(processedFile);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обработки фото: $e')),
        );
      }
    }
  }

  // Диалог выбора источника фото
  void _showPhotoDialog(BuildContext context, String category) {
    _currentPhotoCategory = category;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Фотография'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Другие заказы в ЖК'),
              onTap: () {
                if (_selectedJkItem == null) {
                  _showJkError();
                } else {
                  Navigator.pop(context);
                  _loadJkPhotos();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Ошибка: ЖК не выбран
  void _showJkError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ошибка"),
          content: const Text("Для добавления фото из ЖК необходимо выбрать ЖК."),
          actions: <Widget>[
            TextButton(
              child: const Text("ОК"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Заглушка для загрузки фото из выбранного ЖК
  void _loadJkPhotos() {
    // TODO: Реализовать загрузку фотографий из выбранного ЖК
    print("Загружаем фото из ЖК: ${_selectedJkItem?.name}");
  }

  // Виджет для отображения ряда фотографий по категории
  Widget _buildPhotoRow(String category) {
    List<File> photos = _photosByCategory[category] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showPhotoDialog(context, category),
                icon: const Icon(Icons.add_circle_outline, size: 24, color: Color(0xFF0f7692)),
              ),
              Text(
                category,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: photos.isNotEmpty ? 100 : 0,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.file(photos[index], fit: BoxFit.cover),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photosByCategory[category]!.removeAt(index);
                          });
                        },
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Формирование и отправка данных заказа
  Future<void> _submitOrder(ApiService apiService) async {
    // Валидация: хотя бы один чекбокс должен быть выбран
    if (!(_referOcenka || _lidOcenka || _referPriemka || _getMoney)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите хотя бы одну опцию')),
      );
      return;
    }
    final Map<String, dynamic> data = {
      if (_isEditMode) "id": _orderId,
      "client_phone": _phoneController.text,
      "client_fio": _fioController.text,
      "osmotr_field_1": _dateController.text,
      "osmotr_field_2": _selectedTime ?? "",
      "jk_name": _selectedJkItem?.name ?? "",
      "jk_color": _selectedJkItem?.color ?? "",
      "address": _addressController.text,
      "section": _sectionController.text,
      "primechaniya": _referPriemka ? _noteController.text : "",
      "refer_priemka": _referPriemka ? 1 : 0,
      "refer_ocenka": _referOcenka ? 1 : 0,
      "lid_ocenka": _lidOcenka ? 1 : 0,
      "komnat": int.tryParse(_selectedRooms ?? "0") ?? 0,
      "stoimost_priemki": _referPriemka ? int.tryParse(_priceController.text) ?? 0 : 0,
      "stoimost": _referOcenka ? int.tryParse(_priceOcenkaController.text) ?? 0 : 0,
      "ecspert_na_osmotre_txt": _referOcenka ? _noteOcenkaController.text : "",
      "otchet_dlya": _selectedBank ?? "",
      "money_expert": _getMoney ? 1 : 0,
    };

    try {
      dynamic result;
      if (_isEditMode) {
        // Use referNew endpoint for update as well
        result = await apiService.referNew(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно обновлен!')),
        );
      } else {
        result = await apiService.referNew(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно создан!')),
        );
      }

      String orderId = _isEditMode ? _orderId.toString() : result['id'].toString();

      final Map<String, int> categoryMapping = {
        'Дом снаружи': 1,
        'Дом изнутри': 2,
        'Квартира': 3,
      };

      for (String category in _photosByCategory.keys) {
        int typeSector = categoryMapping[category] ?? 0;
        if (_photosByCategory[category]!.isNotEmpty) {
          for (File photo in _photosByCategory[category]!) {
            final uid = generateUniqueUid(photo.path);
            Response response = await apiService.sendFile(
              photo.path,
              'photos',
              prefsProvider.username ?? '',
              uid: uid,
              mapPhotoId: typeSector
            );
            if (response.statusCode == 200) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReferrerScreen(), // Переход на экран с заказами
                ),
              );
            } else {

            }
          }
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReferrerScreen(), // Переход на экран с заказами
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

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
              // ФИО
              TextField(
                controller: _fioController,
                decoration: const InputDecoration(
                  hintText: "ФИО",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              // Телефон и опция "Ссылка для быстрого входа"
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneMaskFormatter],
                      decoration: const InputDecoration(
                        hintText: "+7(123)456-78-90",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
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
              Row(
                children: [
                  CustomCheckbox(
                    value: _referOcenka,
                    onChanged: (newValue) {
                      setState(() {
                        _referOcenka = newValue!;
                      });
                    },
                    label: 'Оценка квартиры',
                  ),
                  if (_referOcenka)
                    CustomCheckbox(
                      value: _lidOcenka,
                      onChanged: (value) {
                        setState(() {
                          _lidOcenka = value!;
                        });
                      },
                      label: 'Передаю лид\n(осмотр не провожу)',
                    ),
                ],
              ),
              CustomCheckbox(
                value: _referPriemka,
                onChanged: (value) {
                  setState(() {
                    _referPriemka = value!;
                  });
                },
                label: 'Приемка квартиры от застройщика',
              ),
              if (_referPriemka) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    hintText: "Стоимость приемки",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: "Объем работ, примечания",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Жилищный комплекс
              const Text(
                'Жилищный комплекс:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _jkItems == null
                  ? const CircularProgressIndicator()
                  : SizedBox(
                height: 48,
                child: DropdownMenu<JkItem>(
                  initialSelection: _selectedJkItem,
                  expandedInsets: EdgeInsets.zero,
                  onSelected: (JkItem? value) {
                    setState(() {
                      _selectedJkItem = value;
                    });
                  },
                  dropdownMenuEntries: _jkEntries,
                ),
              ),
              const SizedBox(height: 12),
              // Подъезд / секция
              TextField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  hintText: "Подъезд, секция",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              // Адрес
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: "Адрес",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              // Дата и время осмотра
              const Text(
                'Осмотр:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Дата',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _timeList == null
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      height: 48,
                      child: DropdownMenu<String>(
                        initialSelection: _selectedTime,
                        expandedInsets: EdgeInsets.zero,
                        onSelected: (String? value) {
                          setState(() {
                            _selectedTime = value == '-' ? null : value;
                          });
                        },
                        dropdownMenuEntries: _timeList!
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_referOcenka) ...[
                const SizedBox(height: 16),
                const Text(
                  'Банк:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _bankList == null
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  height: 48,
                  child: DropdownMenu<String>(
                    initialSelection: _selectedBank,
                    expandedInsets: EdgeInsets.zero,
                    onSelected: (String? value) {
                      setState(() {
                        _selectedBank = value == '-' ? null : value;
                      });
                    },
                    dropdownMenuEntries: _bankList!
                        .map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Количество комнат
              const Text(
                'Количество комнат:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: DropdownMenu<String>(
                  initialSelection: _selectedRooms,
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
              ),
              if (_referOcenka) ...[
                const SizedBox(height: 16),
                const Text(
                  "Стоимость оценки для клиента:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _priceOcenkaController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Комментарий к оценке:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteOcenkaController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomCheckbox(
                  value: _getMoney,
                  onChanged: (value) {
                    setState(() {
                      _getMoney = value!;
                    });
                  },
                  label: "Деньги от клиента получены на осмотре",
                ),
              ],
              const SizedBox(height: 24),
              // Фотографии
              const Text(
                'Фотографии:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              for (String category in _photosByCategory.keys)
                _buildPhotoRow(category),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _submitOrder(apiService),
        backgroundColor: const Color(0xFF0f7692),
        child: const Icon(Icons.check),
      ),
    );
  }
}