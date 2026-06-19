import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'features/rail/rail_search_page.dart';

/// App 外殼：底部三運具分頁。目前鐵路已實作，公車/YouBike 為後續。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 1; // 預設開在鐵路頁

  static const _pages = <Widget>[
    _ComingSoon(title: '公車到站', icon: Icons.directions_bus),
    RailSearchPage(),
    _ComingSoon(title: 'YouBike 車位', icon: Icons.directions_bike),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined),
              selectedIcon: Icon(Icons.directions_bus),
              label: '公車'),
          NavigationDestination(
              icon: Icon(Icons.train_outlined),
              selectedIcon: Icon(Icons.train),
              label: '鐵路'),
          NavigationDestination(
              icon: Icon(Icons.directions_bike_outlined),
              selectedIcon: Icon(Icons.directions_bike),
              label: 'YouBike'),
        ],
      ),
    );
  }
}

/// 尚未實作的分頁佔位。
class _ComingSoon extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ComingSoon({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.inkSoft),
            const SizedBox(height: 12),
            const Text('施工中', style: TextStyle(color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
