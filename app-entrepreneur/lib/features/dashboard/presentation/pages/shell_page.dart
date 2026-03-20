import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/top_navbar_widget.dart';

/// Shell layout — sidebar + top navbar + content area.
/// Semua halaman dalam app (kecuali login) menggunakan shell ini.
class ShellPage extends StatefulWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _routeToIndex = {
    '/dashboard': 0,
    '/learning': 1,
    '/business-ideation': 2,
    '/launchpad': 3,
    '/operations': 4,
    '/administration': 5,
    '/marketing': 6,
    '/hr': 7,
    '/finance': 8,
  };

  static const _indexToRoute = [
    '/dashboard',
    '/learning',
    '/business-ideation',
    '/launchpad',
    '/operations',
    '/administration',
    '/marketing',
    '/hr',
    '/finance',
  ];

  int get _selectedIndex {
    final location = GoRouterState.of(context).uri.path;
    for (final entry in _routeToIndex.entries) {
      if (location.startsWith(entry.key)) return entry.value;
    }
    return 0;
  }

  void _onItemSelected(int index) {
    if (index < _indexToRoute.length) {
      context.go(_indexToRoute[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              child: SidebarWidget(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  Navigator.pop(context);
                  _onItemSelected(index);
                },
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            SidebarWidget(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          Expanded(
            child: Column(
              children: [
                TopNavbarWidget(
                  onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
