  import 'package:flutter/material.dart';
  import 'package:my_flutter_app_001/pages/MainPage.dart'; // MainPage import
  import 'package:my_flutter_app_001/pages/TodayPage.dart'; // TodayPage import
  import 'package:my_flutter_app_001/pages/MonthPage.dart'; // MonthPage import
  import 'package:my_flutter_app_001/pages/CalendarPage.dart'; // CalendarPage import

  import 'package:path_provider/path_provider.dart';
  import 'dart:io';
  import 'package:intl/intl.dart';

  void main() {

    runApp(const MyApp());
    backupCsvFile();
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        initialRoute: '/', // 시작 경로
        routes: {
          '/': (context) => const MainPage(), // 메인 페이지
          '/today': (context) => const TodayPage(), // Today 페이지
          '/month': (context) => const MonthPage(), // Month 페이지
          '/calendar': (context) => const CalendarPage(), // Calendar 페이지
        },
      );
    }
  }

  /// 매달 1일에 백업 파일 생성 (백업 파일이 없는 경우에만)
Future<void> backupCsvFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final currentFilePath = '${directory.path}/records.csv';
    final now = DateTime.now();

    // 현재 날짜가 1일인지 확인
    if (now.day == 1) {
      // 이전 달의 백업 파일명 생성 (yyyy_MM 형식)
      final backupFileName = DateFormat('yyyy_MM').format(now.subtract(const Duration(days: 1)));
      final backupFilePath = '${directory.path}/${backupFileName}_records.csv';

      final backupFile = File(backupFilePath);
      final currentFile = File(currentFilePath);

      
      if (!await backupFile.exists()) {
        if (await currentFile.exists()) {
          await currentFile.copy(backupFilePath); // 백업 파일 생성
          await currentFile.writeAsString(''); // 현재 파일 초기화
          debugPrint('이전 달 파일을 $backupFilePath 로 백업하고 초기화했습니다.');
        } else {
          debugPrint('records.csv 파일이 존재하지 않습니다. 백업하지 않습니다.');
        }
      } else {
        debugPrint('백업 파일 $backupFilePath 이 이미 존재합니다. 중복 백업을 방지합니다.');
      }
    } else {
      debugPrint('오늘은 1일이 아니므로 백업하지 않습니다.');
      debugPrint(currentFilePath);

    }
  } catch (e) {
    debugPrint('CSV 백업 중 오류 발생: $e');
  }
}

