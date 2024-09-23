import 'package:flutter/material.dart';

final ThemeData customTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF0f7692), // Основной цвет (синий)
    onPrimary: Colors.white, // Цвет текста и иконок на primary
    secondary: Color(0xFFFF9800), // Акцентный цвет (оранжевый)
    onSecondary: Colors.white, // Цвет текста и иконок на secondary
    surface: Colors.white, // Цвет поверхности (фон карточек, AppBar и т.д.)
    onSurface: Color(0xFF025565), // Цвет текста на поверхности
    background: Colors.white, // Основной цвет фона
    error: Color(0xFFff0000), // Цвет ошибок
    onError: Colors.white, // Цвет текста на фоне ошибок
  ),
  useMaterial3: true, // Включение использования Material 3
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF0f7692), // Цвет AppBar
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF025565)), // Основной цвет текста
    bodyMedium: TextStyle(color: Color(0xFF025565)),
    headlineLarge: TextStyle(color: Color(0xFF0f7692), fontWeight: FontWeight.bold), // Цвет заголовков
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // <-- Radius
      ),
      backgroundColor: Color(0xFF0f7692), // Цвет кнопки
      foregroundColor: Colors.white, // Цвет текста на кнопке
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // <-- Radius
      ),
      backgroundColor: Colors.white, // Цвет текста на кнопке
      foregroundColor: Color(0xFF0f7692), // Цвет кнопки
    )
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFF9800), // Цвет FAB
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white, // Цвет заливки текстовых полей
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF0f7692)),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF0f7692)),
      borderRadius: BorderRadius.circular(8.0),
    ),
    labelStyle: TextStyle(color: Color(0xFF025565)), // Цвет текста в полях ввода
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.black,
  ),
  listTileTheme: ListTileThemeData(
    iconColor: Color(0xFF0f7692), // Цвет иконок в Drawer
    textColor: Color(0xFF025565), // Цвет текста в Drawer
  ),
);