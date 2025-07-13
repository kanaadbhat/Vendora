import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'vendor', // Default to vendor role
  });

  @override
  Widget build(BuildContext context) {
    final items =
        role == 'vendor'
            ? const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: 'Features',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            ]
            : const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: 'Features',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: items,
    );
  }
}
