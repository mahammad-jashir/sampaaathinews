import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_theme.dart';

/// Persistent bottom navigation shown on the mobile main tabs (Home, Latest
/// News, Profile). Each tab is a normal route (not a nested navigator), so
/// switching tabs is just `context.go(...)` — simple and safe to add to an
/// existing GoRouter setup without restructuring routing.
class AppBottomNav extends StatelessWidget {
  final String currentPath;

  const AppBottomNav({super.key, required this.currentPath});

  int get _currentIndex {
    if (currentPath.startsWith('/latest')) return 1;
    if (currentPath.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/latest');
            break;
          case 2:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'ಮುಖಪುಟ'),
        BottomNavigationBarItem(icon: Icon(Icons.article_outlined), activeIcon: Icon(Icons.article), label: 'ಇತ್ತೀಚಿನ ಸುದ್ದಿ'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'ಪ್ರೊಫೈಲ್'),
      ],
    );
  }
}
