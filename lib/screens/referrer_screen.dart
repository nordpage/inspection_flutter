import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../provider/shared_preferences_provider.dart';
import '../server/api_service.dart';
import '../models/osmotr_item.dart'; // Модель для событий

class ReferrerScreen extends StatefulWidget {
  const ReferrerScreen({super.key});

  @override
  State<ReferrerScreen> createState() => _ReferrerScreenState();
}

class _ReferrerScreenState extends State<ReferrerScreen> {
  late ValueNotifier<List<OsmotrItem>> _selectedEvents;
  Map<DateTime, List<OsmotrItem>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    loadOsmotrData();
  }

  Future<void> loadOsmotrData() async {
    try {
      DateTime lastDayOfMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
      );

      String lastDayFormatted =
          '${lastDayOfMonth.day.toString().padLeft(2, '0')}.${lastDayOfMonth.month.toString().padLeft(2, '0')}.${lastDayOfMonth.year}';

      final prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
      final ApiService apiService = ApiService(prefsProvider);

      List<OsmotrItem> osmotrList = await apiService.getOsmotrList(
        '01.12.2021',
        lastDayFormatted,
      );

      setState(() {
        _events = {};
        for (var osmotr in osmotrList) {
          debugPrint(osmotr.toString());

          // Парсим дату и устанавливаем UTC с обнулением времени
          List<String> dateParts = osmotr.osmotrField1.split('.');
          DateTime date = DateTime.utc(
            int.parse(dateParts[2]), // Год
            int.parse(dateParts[1]), // Месяц
            int.parse(dateParts[0]), // День
          );

          _events.putIfAbsent(date, () => []);
          _events[date]!.add(osmotr);
        }

        // Обновляем события для выбранного дня
        DateTime today = DateTime.utc(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        );
        _selectedEvents.value = _events[today] ?? [];
      });

    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;

      // Приводим выбранный день к UTC для поиска в _events
      DateTime selectedDayUtc = DateTime.utc(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );

      _selectedEvents.value = _events[selectedDayUtc] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar<OsmotrItem>(
            locale: 'ru_RU',
            firstDay: DateTime(2021, 12, 01),
            lastDay: DateTime(DateTime.now().year, 12, 31),
            focusedDay: _focusedDay,

            // Убираем выделение сегодняшнего дня
            selectedDayPredicate: (day) => false,

            eventLoader: (day) {
              DateTime dayUtc = DateTime.utc(day.year, day.month, day.day);
              return _events[dayUtc] ?? [];
            },

            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: {
              CalendarFormat.month: "Month"
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, date, event) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(int.parse('0xFF${event.jkColor.substring(1)}')),
                  ),
                  width: 7.0,
                  height: 7.0,
                );
              },
            ),
          ),          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<OsmotrItem>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                return events.isEmpty
                    ? const Center(child: Text('Нет событий'))
                    : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(Icons.home, color: Colors.brown[300]),
                        title: Text('${event.jkName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Эксперт: ${event.ecspertNaOsmotre}'),
                            Text('Время: ${event.osmotrField2}'),
                            Text('Стоимость: ${event.stoimost} руб.'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}