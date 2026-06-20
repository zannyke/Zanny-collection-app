import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class BottomNavScaffold extends StatelessWidget {
  final Widget child;
  const BottomNavScaffold({super.key, required this.child});

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/collections')) return 1;
    if (location.startsWith('/fashion')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
              case 1:
                context.go('/collections');
              case 2:
                context.go('/fashion');
              case 3:
                context.go('/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 22),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_grid_2x2, size: 22),
              activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill, size: 22),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.sparkles, size: 22),
              activeIcon: Icon(CupertinoIcons.sparkles, size: 22),
              label: 'Fashion',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 22),
              activeIcon: Icon(CupertinoIcons.person_fill, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
