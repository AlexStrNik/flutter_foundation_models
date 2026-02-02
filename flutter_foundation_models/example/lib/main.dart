import 'package:flutter/material.dart';
import 'package:flutter_foundation_models_example/my_weather.dart';
import 'package:flutter_foundation_models_example/novel_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    MyWeather(),
    NovelGenerator(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Foundation Models Demo'),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              label: 'Weather',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Novel',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
