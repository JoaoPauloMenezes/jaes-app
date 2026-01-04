import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'flashcard_page.dart';
import 'config_page.dart';
import 'library.dart'; // Add this import
import '/assets/constants.dart' as Constants;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    FlashcardPage(),
    LibraryPage(),
    // CalendarPage(),
    ConfigScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.developer_mode, color: Constants.primaryColor),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library, color: Constants.primaryColor),
            label: 'Library',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.calendar_month, color: Constants.primaryColor),
          //   label: 'Calendar',
          // ),
          NavigationDestination(
            icon: Icon(Icons.account_circle, color: Constants.primaryColor),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}