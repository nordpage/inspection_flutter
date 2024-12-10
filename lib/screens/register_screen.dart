import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../server/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  List<String>? _bankList;
  String? _selectedBank;
  String? _selectedRooms;
  bool _isLoading = false;
  bool _bankValidate = false;
  bool _roomsValidate = false;

  var maskFormatter = MaskTextInputFormatter(
    mask: '###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  TextEditingController addressInputFormatter = TextEditingController();
  bool _addressValidate = false;
  TextEditingController nameInputFormatter = TextEditingController();
  bool _nameValidate = false;
  TextEditingController phoneInputFormatter = TextEditingController();
  bool _phoneValidate = false;
  TextEditingController emailInputFormatter = TextEditingController();
  bool _emailValidate = false;

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
      });
    });
  }

  @override
  void dispose() {
    nameInputFormatter.dispose();
    addressInputFormatter.dispose();
    phoneInputFormatter.dispose();
    emailInputFormatter.dispose();
    super.dispose();
  }

  Future<List<String>> loadBanksFromAssets(String filePath) async {
    String jsonString = await rootBundle.loadString(filePath);
    List<dynamic> jsonResponse = jsonDecode(jsonString);
    return jsonResponse.cast<String>();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _register() async {
    setState(() {
      _addressValidate = addressInputFormatter.text.isEmpty;
      _emailValidate = emailInputFormatter.text.isEmpty ||
          !isValidEmail(emailInputFormatter.text);
      _phoneValidate = phoneInputFormatter.text.isEmpty ||
          phoneInputFormatter.text.length < 2;
      _nameValidate = nameInputFormatter.text.isEmpty;
      _bankValidate = _selectedBank == null || _selectedBank == "-";
      _roomsValidate = _selectedRooms == null || _selectedRooms == "-";
    });

    if (!_nameValidate &&
        !_phoneValidate &&
        !_emailValidate &&
        !_addressValidate &&
        !_bankValidate &&
        !_roomsValidate) {

      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);

        String phoneNumber = '7${phoneInputFormatter.text
            .replaceAll(')', '')
            .replaceAll(" ", "")
            .replaceAll("-", '')}';

        Map<String, dynamic> body = {
          'address': addressInputFormatter.text,
          'komnat': _selectedRooms!,
          'client_phone': phoneNumber,
          'email': emailInputFormatter.text,
          'client_fio': nameInputFormatter.text,
          'otchet_dlya': _selectedBank!,
        };

        await apiService.register(jsonEncode(body));

        if(!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Регистрация завершена'),
              content: const Text('Скоро вам на телефон придет смс сообщение.\nВ нем будет логин и пароль для авторизации'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ОК'),
                ),
              ],
            );
          },
        ).whenComplete(() {
          Navigator.of(context, rootNavigator: true).pushReplacementNamed('/auth');
        });

      } catch (error) {
        debugPrint('Error during registration: $error');
        if(!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Произошла ошибка при регистрации'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      List<String> errors = [];
      if (_bankValidate) errors.add('выберите банк');
      if (_roomsValidate) errors.add('укажите количество комнат');
      if (_nameValidate) errors.add('введите ФИО');
      if (_phoneValidate) errors.add('введите корректный номер телефона');
      if (_emailValidate) {
        errors.add(emailInputFormatter.text.isEmpty
            ? 'введите email'
            : 'введите корректный email');
      }
      if (_addressValidate) errors.add('введите адрес');

      String errorMessage = 'Пожалуйста, ${errors.join(', ')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFF0f7692),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: _bankList == null
                  ? const CircularProgressIndicator()
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
                      const SizedBox(height: 10),
                      const Text("ФИО:"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: nameInputFormatter,
                        decoration: InputDecoration(
                          errorText: _nameValidate ? "Поле 'ФИО' не может быть пустым" : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Моб. телефон:"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: phoneInputFormatter,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "000) 000-00-00",
                          hintStyle: const TextStyle(color: Colors.grey),
                          errorText: _phoneValidate ? "Поле 'Моб. телефон' не может быть пустым" : null,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 10, top: 12, bottom: 12),
                            child: Text(
                              '+7 (',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        inputFormatters: [maskFormatter],
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      const Text("Email:"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: emailInputFormatter,
                        decoration: InputDecoration(
                          errorText: _emailValidate
                              ? emailInputFormatter.text.isEmpty
                              ? "Поле 'Email' не может быть пустым"
                              : "Некорректный формат email"
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Банк:"),
                      const SizedBox(height: 5),
                      DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        errorText: _bankValidate ? "Выберите банк" : null,
                        onSelected: (String? value) {
                          setState(() {
                            _selectedBank = value == "-" ? null : value;
                          });
                        },
                        dropdownMenuEntries: _bankList!
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      const Text("Полный адрес:"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: addressInputFormatter,
                        decoration: InputDecoration(
                          errorText: _addressValidate ? "Поле 'Полный адрес' не может быть пустым" : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Количество комнат:"),
                      const SizedBox(height: 5),
                      DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        errorText: _roomsValidate ? "Выберите количество комнат" : null,
                        onSelected: (String? value) {
                          setState(() {
                            _selectedRooms = value == "-" ? null : value;
                          });
                        },
                        dropdownMenuEntries: rooms
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  SizedBox(
                    height: 45,
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text("Зарегистрироваться"),
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