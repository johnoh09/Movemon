import 'package:flutter/material.dart';
import 'package:flutter_diet_app/api/api_client.dart';
import 'home/home_screen.dart';
import 'workout/workout_screen.dart';
import 'progress/my_progress_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final ApiClient api; 
  const MainScreen({super.key, required this.api});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions; // state가 변경되므로 const 제거

  @override
  void initState() {
    super.initState();
    // 홈 화면에 탭 이동 함수를 전달하기 위해 initState에서 리스트 초기화
    _widgetOptions = <Widget>[
      HomeScreen(onNavigate: _onItemTapped), // 홈 화면에 함수 전달
      const WorkoutScreen(),
      const MyProgressScreen(),
      SettingsScreen(api: widget.api),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

