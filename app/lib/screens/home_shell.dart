import 'package:flutter/material.dart';

import 'ai_chat_screen.dart';
import 'dashboard_screen.dart';
import 'log_menu_screen.dart';
import 'microscope_screen.dart';
import 'more_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    LogMenuScreen(),
    MicroscopeScreen(),
    AiChatScreen(),
    MoreScreen(),
  ];

  static const _nav = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_box_outlined),
      activeIcon: Icon(Icons.add_box),
      label: 'Log',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.biotech_outlined),
      activeIcon: Icon(Icons.biotech),
      label: 'Scope',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.smart_toy_outlined),
      activeIcon: Icon(Icons.smart_toy),
      label: 'AI',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_outlined),
      activeIcon: Icon(Icons.menu),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: [
          for (final item in _nav)
            NavigationDestination(
              icon: item.icon,
              selectedIcon: item.activeIcon,
              label: item.label!,
            ),
        ],
      ),
    );
  }
}
