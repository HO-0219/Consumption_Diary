import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Map<String, dynamic>>> dailyData = {};
  Map<DateTime, int> dailyTotal = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final formatter = NumberFormat('#,##0');
  @override
  void initState() {
    super.initState();
    _loadCsvData(_focusedDay);
  }
  Future<void> _loadCsvData(DateTime date) async {
  try {
    String fileName;
    DateTime now = DateTime.now();

    // 현재 달이면 records.csv, 아니면 yyyy-MM_records.csv
    if (date.year == now.year && date.month == now.month) {
      fileName = 'records.csv';
    } else {
      String formattedDate = DateFormat('yyyy-MM').format(date);
      fileName = '${formattedDate}_records.csv';
    }

    String path = await getLocalFilePath(fileName);
    debugPrint('파일 확인 중: $path');

    // 파일이 존재하지 않으면 메시지 출력하고 리턴
    bool fileExists = await File(path).exists();
    if (!fileExists) {
      debugPrint('[경고] $fileName 파일이 존재하지 않습니다. 데이터 로드를 생략합니다.');
      setState(() {
        dailyData.clear();
        dailyTotal.clear();
      });
      return;
    } else {
      debugPrint('[성공] $fileName 파일을 찾았습니다. 데이터를 로드합니다.');
    }

    final input = File(path).openRead();
    final csvData = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    // 데이터 초기화
    dailyData.clear();
    dailyTotal.clear();

    // CSV 파싱
    for (int i = 0; i < csvData.length; i++) {
      try {
        DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(csvData[i][0]);
        DateTime dateOnly = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        String time = csvData[i][1].toString();
        String category = csvData[i][2].toString();
        int amount = int.tryParse(csvData[i][3].toString()) ?? 0;
        String description = csvData[i][4].toString();

        if (!dailyData.containsKey(dateOnly)) {
          dailyData[dateOnly] = [];
          dailyTotal[dateOnly] = 0;
        }
        dailyData[dateOnly]?.add({
          'time': time,
          'category': category,
          'amount': amount,
          'description': description,
        });
        dailyTotal[dateOnly] = dailyTotal[dateOnly]! + amount;
      } catch (e) {
        debugPrint('데이터 파싱 오류 발생: $e at line $i');
      }
    }

    setState(() {});
    debugPrint('[성공] $fileName 데이터 로드 완료');
  } catch (e) {
    debugPrint('CSV 데이터를 로드하는 중 오류 발생: $e');
  }
}

  // 로컬 디렉토리 경로 가져오기
  Future<String> getLocalFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  // 날짜 클릭 시 상세 데이터 표시
  void _showDetails(BuildContext context, DateTime selectedDate) {
    // 날짜의 시간 정보를 제외하고 연, 월, 일만 비교
    DateTime dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final records = dailyData[dateOnly] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: records.isEmpty
              ? const Center(
                  child: Text(
                    "해당 일에는 소비 내역이 없습니다",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    Text(
                      "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}의 소비 내역",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          var record = records[index];
                          return ListTile(
                            title: Text(
                                '${record['category']} - ₩${record['amount']}'),
                            subtitle: Text(
                                '${record['time']} - ${record['description']}'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더 페이지')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDetails(context, selectedDay);
              _loadCsvData(selectedDay);
              
            },
            onPageChanged: (focusedDay)async {
            setState(() {
              _focusedDay = focusedDay;
            });
            await _loadCsvData(focusedDay);  
            setState(() {});
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                DateTime dateOnly = DateTime(day.year, day.month, day.day);
                int? total = dailyTotal[dateOnly];
                return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: total != null
                        ? Colors.blueAccent.withOpacity(0.5)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day.day.toString() +
                        (total != null ? '\n₩${formatter.format(total)}' : ''),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
