// lib/views/components/bottom_navigation.dart
import 'package:flutter/material.dart';

class BottomNavigator extends StatefulWidget {
  final ValueChanged<int> onTabSelected;
  final int currentIndex;

  const BottomNavigator({super.key, required this.onTabSelected, required this.currentIndex});

  @override
  _BottomNavigatorState createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex, // Set the currently selected tab
      onTap: widget.onTabSelected, // Pass the callback to handle tab change
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
