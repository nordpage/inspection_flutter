import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  List<String>? _bankList;
  String? _selectedBank;
  String? _selectedRooms;

  Future<List<String>> loadBanksFromAssets(String filePath) async {
    String jsonString = await rootBundle.loadString(filePath);
    List<dynamic> jsonResponse = jsonDecode(jsonString);
    return jsonResponse.cast<String>();
  }

  List<String> rooms = [
    "-",
    "1",
    "2",
    "3",
    "4",
    "5",
    "Студия",
  ];

  @override
  void initState() {
    super.initState();
    loadBanksFromAssets("assets/bankList.json").then((bankList) {
      setState(() {
        _bankList = bankList;
        _selectedBank = _bankList!.isNotEmpty ? _bankList![0] : null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var maskFormatter = MaskTextInputFormatter(
      mask: '###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: _bankList == null
                  ? CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image.asset(
                      "assets/priemka_auth_logo.jpg",
                      height: 100,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text("ФИО:"),
                      SizedBox(height: 5),
                      TextField(),
                      SizedBox(height: 10),
                      Text("Моб. телефон:"),
                      SizedBox(height: 5),
                      TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "000) 000-00-00",
                          hintStyle: TextStyle(color: Colors.grey), // Цвет хинта
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10, top: 12, bottom: 12), // Убедитесь, что padding минимален
                            child: Text(
                              '+7 (',
                              style: TextStyle(color: Colors.black), // Цвет префикса
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        inputFormatters: [maskFormatter],
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 10),
                      Text("Email:"),
                      SizedBox(height: 5),
                      TextField(),
                      SizedBox(height: 10),
                      Text("Банк:"),
                      SizedBox(height: 5),
                      DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: _bankList!.first,
                        onSelected: (String? value) {
                          setState(() {
                            _selectedBank = value!;
                          });
                        },
                        dropdownMenuEntries: _bankList!
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                              value: value, label: value);
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      Text("Полный адрес:"),
                      SizedBox(height: 5),
                      TextField(),
                      SizedBox(height: 10),
                      Text("Количество комнат:"),
                      SizedBox(height: 5),
                      DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: rooms.first,
                        onSelected: (String? value) {
                          setState(() {
                            _selectedRooms = value!;
                          });
                        },
                        dropdownMenuEntries: rooms
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                              value: value, label: value);
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  SizedBox(
                    height: 45,
                    width: 220,
                    child: ElevatedButton(
                      onPressed: () {
                        // Действие при нажатии на кнопку
                      },
                      child: Text("Зарегистрироваться"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
