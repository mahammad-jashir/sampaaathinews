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
    final currentIndex = _currentIndex;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
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
      items: [
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.home_outlined, false),
          activeIcon: _buildAnimatedIcon(Icons.home, true),
          label: 'ಮುಖಪುಟ',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.article_outlined, false),
          activeIcon: _buildAnimatedIcon(Icons.article, true),
          label: 'ಇತ್ತೀಚಿನ ಸುದ್ದಿ',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.person_outline, false),
          activeIcon: _buildAnimatedIcon(Icons.person, true),
          label: 'ಪ್ರೊಫೈಲ್',
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(IconData icon, bool isActive) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isActive ? 0.8 : 1.0, end: isActive ? 1.15 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primaryColor : Colors.grey,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
