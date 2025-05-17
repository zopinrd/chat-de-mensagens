import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Widget principal com navegação por abas usando BottomNavigationBar e IndexedStack.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Lista de telas para cada aba
  final List<Widget> _screens = const [
    HomeScreen(),
    MessagesScreen(),
    FriendsScreen(), // Substitui ContactsScreen por FriendsScreen
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
