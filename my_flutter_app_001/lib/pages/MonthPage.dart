import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class MonthPage extends StatefulWidget {
  const MonthPage({super.key});

  @override
  _MonthPageState createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  Map<String, int> categoryData = {};
  List<String> categories = [];
  List<int> amounts = [];

  @override
  void initState() {
    super.initState();
    _loadCsvData();
  }

  // 로컬 디렉토리 경로 가져오기
  Future<String> getLocalFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('이달의 페이지 로컬저장소위치 : $directory');
    return '${directory.path}/$filename';
  }

  // CSV 파일을 읽는 메서드
  Future<void> _loadCsvData() async {
    String csvPath = await getLocalFilePath('records.csv');
    debugPrint('이달의 페이지 $csvPath');

    final file = File(csvPath);
    String csvData = await file.readAsString();

    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
    debugPrint('cheak rows : $rows');

    DateTime now = DateTime.now(); // 현재 날짜와 시간
    final nowyear = now.year;
    final nowmonth = now.month;

    debugPrint('날짜 형식에서 오류가 생긴거 확인 코드 $now');
    for (var row in rows.skip(0)) {
      DateTime date = DateTime.parse(row[0]);
      final dateyear = date.year;
      final datemonth = date.month;
      final dateday = date.day;
      final category = row[2];
      int amount = int.tryParse(row[3].toString()) ?? 0;
      debugPrint('$category,$dateyear :$datemonth : $dateday ,$nowyear : $nowmonth');

      if (dateyear == nowyear && datemonth == nowmonth) {
        categoryData[category] = (categoryData[category] ?? 0) + amount;
      }
    }

    setState(() {
      categories = categoryData.keys.toList();
      amounts = categoryData.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이달의 소비 통계')),
      body: Column(
        children: [
          
          Expanded(
            child: HorizontalBarChart(categoryData: categoryData),
          ),
        ],
      ),
    );
  }
}

// 파스텔톤 색상을 위한 리스트 (30가지)
const List<Color> softPastelPalette = [
  Color(0xFFFFC1CC), Color(0xFFB3E5FC), Color(0xFFFFF9C4),
  Color(0xFFFFCCBC), Color(0xFFC8E6C9), Color(0xFFD1C4E9),
  Color(0xFFFFE0B2), Color(0xFFBBDEFB), Color(0xFFFFF176),
  Color(0xFFFFAB91), Color(0xFFE1BEE7), Color(0xFFFFD54F),
  Color(0xFFFFCDD2), Color(0xFFCFD8DC), Color(0xFFDCEDC8),
  Color(0xFFFFF176), Color(0xFFB2EBF2), Color(0xFFFFCC80),
  Color(0xFFFFF3E0), Color(0xFFC5CAE9), Color(0xFFD7CCC8),
  Color(0xFFB0BEC5), Color(0xFFE0F7FA), Color(0xFFB3E5FC),
  Color(0xFFE6EE9C), Color(0xFFFFD180), Color(0xFFE1BEE7),
  Color(0xFFDCEDC8), Color(0xFFB2DFDB), Color(0xFFBCAAA4)
];





class HorizontalBarChart extends StatelessWidget {
  final Map<String, int> categoryData;

  const HorizontalBarChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const Center(child: Text('데이터가 없습니다.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 부모 위젯의 크기 정보가 제공됩니다
        double availableWidth = constraints.maxWidth;  // 가용 너비

        return Chart(
          data: categoryData.entries
              .map((entry) => {'category': entry.key, 'amount': entry.value})
              .toList(),
          variables: {
            'category': Variable(
              accessor: (Map map) => map['category'] as String,
            ),
            'amount': Variable(
              accessor: (Map map) => map['amount'] as num,
            ),
          },
          marks: [
            IntervalMark(
              position: Varset('category') * Varset('amount'),
              color: ColorEncode(
                variable: 'category',
                values: softPastelPalette,
              ),
            
              
            ),
          ],
          
          coord: RectCoord(
            transposed: true
            ), // 수평 막대 그래프
          axes: [
            Defaults.horizontalAxis, // 수평축
            Defaults.verticalAxis,   // 수직축
          ],
        );
      },
    );
  }
}
