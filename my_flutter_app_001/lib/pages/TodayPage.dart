import 'dart:io'; // 파일 처리를 위해 추가
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 형식 및 금액 포맷을 위해 사용
import 'package:csv/csv.dart'; // CSV 파일 처리를 위해 사용
import 'package:path_provider/path_provider.dart'; // 파일 경로 제공 패키지

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  _TodayPageState createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  List<Map<String, dynamic>> records = []; // 소비 기록을 저장하는 리스트
  List<String>categoryList = [];
  List<String> defaultCategoriyList = ['식비', '교통비','통신비', '여과생활비', '기타'];
  String selectedCategory = ""; // 선택된 카테고리 저장 변수
  final TextEditingController _amountController = TextEditingController(); // 금액 입력 컨트롤러
  final TextEditingController _descriptionController = TextEditingController(); // 설명 입력 컨트롤러
  final TextEditingController _categoryController = TextEditingController(); // 카테고리 컨트롤러
  


  @override
  void initState() {
    super.initState();
    //debugPrint('구동');
    loadandcreatecategories();// 초기 카테고리 생성
    //debugPrint('초기 카테고리 생성 코드 실행 완료 ');
    loadCategories(); // 초기 카테고리 로드
    //debugPrint('초기 카테고리 로드 실행 완료 ');
    loadRecordsFromCSV();// 로드 및 파싱하는 코드 
    //debugPrint('로드 및 파싱하는  코드 실행 완료 ');
  }


  // 로컬 디렉토리 경로 가져오기
  Future<String> getLocalFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    //debugPrint('로컬저장소위치 : $directory');
    return '${directory.path}/$filename';
  }

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


 // CSV 파일에서 레코드를 로드하고 파싱하는 함수
Future<void> loadRecordsFromCSV() async {
    String filePath = await getLocalFilePath('records.csv'); // CSV 파일 경로 가져오기
   // debugPrint('로드및 파싱하는 함수 실행 : $filePath');
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('CSV 파일이 존재하지 않습니다: $filePath');
        file.create();
        debugPrint('csv파일이 존재 하지 않아 생성합니다');
      } else{
        debugPrint('csv 파일이 있음');
      }

      String csvData = await file.readAsString(); // 파일 내용을 읽어옴
      parseCSVData(csvData); // 읽어온 CSV 데이터를 파싱
    } catch (e) {
      debugPrint('CSV 로드 오류: $e'); // 오류 발생 시 디버그 출력
    }
  }

  // CSV 데이터를 파싱하고 records에 저장
  void parseCSVData(String csvData) {
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData); // CSV 데이터 변환
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 오늘 날짜
    //debugPrint('csv 데이터를 파싱하고 레코드에 저장하는 함수 : $today');
    setState(() {
      records = csvTable.where((row) { // 오늘 날짜와 일치하는 레코드 필터링
        String recordDate = row[0].toString();
        return recordDate == today;
      }).map((row) { // 각 레코드를 맵으로 변환
        return {
          "date": row[0].toString(), // 날짜
          "time": row[1].toString(), // 시간
          "category": row[2].toString(), // 카테고리
          "amount": row[3], // 금액
          "description": row[4].toString(), // 설명
        };
      }).toList();
    });
    
     //debugPrint('CSV 파일에 저장');
  }


  // 소비 기록을 CSV 파일에 저장하는 함수
  Future<void> saveRecordsToCSV() async {
    String filePath = await getLocalFilePath('records.csv');
    final file = File(filePath);

    List<List<dynamic>> csvData = records.map((record) {
      return [
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        record["time"],
        record["category"],
        record["amount"],
        record["description"],
      ];
    }).toList();

    String csvString = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString,mode:FileMode.append,flush: true);
    
    //debugPrint('CSV 파일에 저장 완료: $filePath');
   
  }
/// 레코드 CSV 파일에 새로운 데이터를 추가하는 함수
/// String time, String category, int amount, String description
Future<void> addRecordToCSV() async {
  String filePath = await getLocalFilePath('records.csv'); // 레코드 CSV 파일의 경로를 가져옴

  File file = File(filePath); // 파일 객체 생성
  if (!await file.exists()) { // 파일이 존재하지 않으면
    await file.create(); // 파일 생성
  }
  List<List<dynamic>> csvData = records.map((record) {
      return [
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        record["time"],
        record["category"],
        record["amount"],
        record["description"],
      ];
    }).toList();


  // CSV 형식으로 변환
  String csv = '${const ListToCsvConverter().convert(csvData)}\n';
  //String csv = const ListToCsvConverter().convert(csvData);
  
  await file.writeAsString(csv, mode: FileMode.write, flush: true);
}


// 소비 기록을 추가하고 CSV 파일에 저장
  void addRecord() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    final amount = int.tryParse(_amountController.text) ?? 0;
    final description = _descriptionController.text;

    if (selectedCategory.isEmpty || amount == 0 || description.isEmpty) {
     // debugPrint('입력값이 비어있어서 추가가 안됩니다');
      return;
    }

    final newRecord = {
      "time": time,
      "category": selectedCategory,
      "amount": amount,
      "description": description,
    };

    setState(() {
      records.add(newRecord);
      addRecordToCSV();
      //addRecordToCSV(time,selectedCategory,amount,description); // 새로운 기록을 CSV 파일에 저장
      //clearFields(); // 필드 초기화
      Navigator.of(context).pop(); // 다이얼로그 닫기
    });
  }

  // 필드 초기화
  void clearFields() {
    _amountController.clear(); // 금액 입력 필드 비우기
    _descriptionController.clear(); // 설명 입력 필드 비우기
    setState(() {
      selectedCategory = ""; // 선택된 카테고리 초기화
    });
  }

  // 소비 기록을 출력하는 함수
  Widget buildRecordList() {
    if (records.isEmpty) {
      return const Center(child: Text('오늘의 소비 기록이 없습니다.'));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return ListTile(
            title: Text(
              '${record["time"]} - ${record["category"]}: ${formatCurrency(record["amount"])}원',
            ),
            subtitle: Text(record["description"]),
          );
        },
      ),
    );
  }

  String formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  // 소비 기록 추가 다이얼로그 열기
  void openRecordEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('오늘 소비 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                hint: const Text('카테고리 선택'),
                value: selectedCategory.isEmpty ? null : selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: categoryList.map<DropdownMenuItem<String>>((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '금액 입력'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: '설명 입력'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedCategory.isNotEmpty && _amountController.text.isNotEmpty) {
                    addRecord();
                    clearFields(); // 필드 초기화
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카테고리와 금액을 선택하세요.')),
                    );
                  }
                },
                child: const Text('오늘 소비 기록 추가'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Future<void> loadandcreatecategories() async {
  String filePath = await getLocalFilePath('categories.csv');
  final file = File(filePath);
 // debugPrint('카테고리 로드 및 생성 함수 : $filePath');
  
  if (!await file.exists()) {

    categoryList.add(defaultCategoriyList as String);
    List<List<dynamic>> csvData = defaultCategoriyList.map((category) => [category]).toList();
    
    String csvString = const ListToCsvConverter().convert(csvData);
   // debugPrint('$csvData');
    await file.writeAsString(csvString, mode: FileMode.write, flush: true);
    //debugPrint('기본 카테고리 생성 완료');
  } else {
    //debugPrint('categories.csv 파일이 이미 존재합니다.');
  }
}
 
// 카테고리를 CSV 파일에서 로드하는 함수
  Future<void> loadCategories() async {
    //debugPrint('카테고리 csv 파일 로드 하는 함수');
      try{
      String filePath = await getLocalFilePath('categories.csv');
      final file = File(filePath);
     // debugPrint('파일위치 : $filePath');
      

      if (!await file.exists()) {
        // 파일이 없으면 기본 카테고리를 세팅
       // debugPrint('categories.csv 파일이 없습니다 ');
       //debugPrint('categories.csv 파일을 새로 생성합니다!! ');
       for (int i = 0 ; i < defaultCategoriyList.length; i++){
        categoryList.add(defaultCategoriyList[i]);
        //debugPrint('$defaultCategoriyList[i]');
        }
      }
      String csvData = await file.readAsString();
        final csvTable = const CsvToListConverter().convert(csvData);
       // List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
        setState(() {
//          selectedCategories = csvTable.map((row) => row[0].toString()).toList();
          categoryList = csvTable.map((row) => row[0].toString()).toSet().toList();
        });
    } catch (e) {
      //debugPrint("Error loading categories: $e");
    }
  }
  

  

    // 카테고리를 CSV 파일에 저장하는 함수
  Future<void> saveCategoriesToCSV() async { 
  try {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/categories.csv';
    final file = File(path);
    // 카테고리를 CSV 형식으로 변환
    List<List<dynamic>> csvData = categoryList.map((category) => [category]).toList();
    String csvString = const ListToCsvConverter().convert(csvData);
    //debugPrint('$csvData');
    await file.writeAsString(csvString, mode: FileMode.write, flush: true);

    //debugPrint('카테고리가  $path에 저장되었습니다.');

  } catch (e) {
    //debugPrint('CSV 저장 오류: $e');
  }
}



// 카테고리 수정 및 추가 다이얼로그 호출//
void openCategoryEditDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('카테고리 추가'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView( // 스크롤 가능한 위젯으로 변경
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
               //const Text('카테고리 목록', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.builder(
                shrinkWrap: true,
                itemCount: categoryList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(categoryList[index]),
                  );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (){
                    Navigator.of(context).pop();
                    openAddCategoryDialog();
                    },
                  child: const Text('카테고리 추가'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.of(context).pop(); // 다이얼로그 닫기
            openDeleteCategoryDialog();
            },
            child: const Text('카테고리 삭제'),
          ),
          TextButton(
            child: const Text('닫기'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}







//카테고리 추가 다이얼로그 열기 
void openAddCategoryDialog() {
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('카테고리 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 카테고리 수정 UI 추가
            TextField(
              controller: _categoryController, // 카테고리 수정용 텍스트 필드
              decoration: const InputDecoration(hintText: '새로운 카테고리 입력'),
            ),
            // 추가 UI 요소 ...
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 카테고리 수정 로직
              try {
                // 카테고리 수정 코드 추가
                String newCategory = _categoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  // 수정 로직 (예: selectedCategories에 새로운 카테고리 추가 등)
                  setState(() {
                    categoryList.add(newCategory); // 예시로 새로운 카테고리 추가
                    saveCategoriesToCSV();                  
          
                  });
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카테고리를 입력하세요.')),
                  );
                }
              } catch (e) {
               // debugPrint('오류 발생: $e'); // 오류 발생 시 로그 출력
              }
            },
            child: const Text('추가'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
            child: const Text('닫기'),
          ),
        ],
      );
    },
  );
}


// 카테고리 삭제 다이얼로그 열기
void openDeleteCategoryDialog() {
    String? categoryToDelete;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('카테고리 삭제'),
          content: DropdownButton<String>(
            hint: const Text('삭제할 카테고리를 선택하세요'),
            value: categoryToDelete,
            onChanged: (String? newValue) {
              setState(() {
                categoryToDelete = newValue;
              });
            },
            items: categoryList.map<DropdownMenuItem<String>>((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (categoryToDelete != null) {
                  //deleteCategory(categoryToDelete!).then((_) {
                    categoryList.remove(categoryToDelete);
                    saveCategoriesToCSV();   
                    Navigator.of(context).pop();
                  //});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제할 카테고리를 선택하세요.')),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Todaytitle(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            buildRecordList(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: openRecordEditDialog,
                    child: const Text('오늘 소비 기록 추가'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: openCategoryEditDialog, // 카테고리 수정
                    child: const Text('카테고리 수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Todaytitle extends StatelessWidget {
  const Todaytitle({super.key});

  @override
  Widget build(BuildContext context) {
    var today = DateTime.now();
    var formattedDate = DateFormat('yy-MM-dd').format(today);
    return Text('$formattedDate 의 소비 기록');
  }
}
