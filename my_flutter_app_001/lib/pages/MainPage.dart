import 'package:flutter/material.dart';
import 'package:my_flutter_app_001/pages/TodayPage.dart';
import 'package:my_flutter_app_001/pages/MonthPage.dart';
import 'package:my_flutter_app_001/pages/CalendarPage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // 선택된 탭 인덱스

  // 각 탭에 대응하는 페이지를 리스트로 저장
  static final List<Widget> _pages = <Widget>[
    const TodayPage(), // Today 페이지
    const MonthPage(), // Month 페이지
    const CalendarPage(), // Calendar 페이지
  ];

  // 탭 선택 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '소비 일기 메인 페이지 ',
          style: TextStyle(
              fontFamily: "schoolfontBold",
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ), // 앱 이름
      ),
      body: _pages[_selectedIndex], // 선택된 페이지를 body에 표시
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30), // 큰 아이콘
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: 30), // 큰 아이콘
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, size: 30), // 큰 아이콘
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 탭 인덱스
        selectedItemColor: Colors.blue, // 선택된 아이템의 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템의 색상
        backgroundColor: Colors.white, // 배경색
        iconSize: 30, // 아이콘 크기 조절
        onTap: _onItemTapped, // 탭 선택 시 호출
        showUnselectedLabels: true, // 선택되지 않은 항목에도 라벨 표시
        type: BottomNavigationBarType.fixed, // 아이템이 고정된 크기로 유지되도록 설정
      ),
    );
  }
}
