import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebulon_main_app/screens/dashboard_screen.dart';
import 'package:nebulon_main_app/screens/analytics_screen.dart';
import 'package:nebulon_main_app/screens/add_transaction_screen.dart';
import 'package:nebulon_main_app/screens/ai_assistant_screen.dart';
import 'package:nebulon_main_app/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const AddTransactionScreen(),
    const AiAssistantScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Scaffold(
          body: Row(
            children: [
              if (isWide) _buildSidebar(),
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),
          bottomNavigationBar: isWide ? null : _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
      unselectedIconTheme: IconThemeData(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      selectedLabelTextStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        fontSize: 12,
      ),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Image.asset(
          'assets/logo.png',
          width: 32,
          errorBuilder: (_, __, ___) => Icon(
            Icons.rocket_launch,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: Text('Add'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: Text('Assistant'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 36),
            activeIcon: Icon(Icons.add_circle, size: 36),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
