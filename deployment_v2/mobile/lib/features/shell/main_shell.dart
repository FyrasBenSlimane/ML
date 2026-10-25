import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pressable.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../modules/module_registry.dart';
import '../modules/module_slot_screen.dart';
import '../modules/team_screen.dart';
import '../teemo/screens/assessment_screen.dart';
import '../teemo/screens/teemo_profile_screen.dart';

/// Four tabs + a floating "new assessment" button, in a frosted nav bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  void _openTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  void _openModule(ModelModule m) {
    if (m.id == 'teemo') {
      _openTab(1);
    } else if (m.entry != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: m.entry!));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleSlotScreen(module: m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _openTab, onOpenModule: _openModule),
      const TeemoProfileScreen(),
      const HistoryScreen(),
      TeamScreen(onOpenModule: _openModule),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _tab == 2 || _tab == 3 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            for (var i = 0; i < pages.length; i++)
              // Only the visible tab takes part in Hero flights (several tabs
              // show Teemo with the same hero tag).
              HeroMode(
                enabled: i == _tab,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  opacity: i == _tab ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: i != _tab,
                    child: TickerMode(enabled: i == _tab, child: pages[i]),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _NavBar(index: _tab, onTap: _openTab),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.face_3_rounded, 'Teemo'),
    (Icons.history_rounded, 'History'),
    (Icons.hub_rounded, 'Team'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: SizedBox(
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 2; i++) _item(i),
                      const SizedBox(width: 72),
                      for (var i = 2; i < 4; i++) _item(i),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -22,
              child: Pressable(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AssessmentScreen())),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: AppColors.glow(AppColors.teal, strength: 0.5),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(int i) {
    final selected = i == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 0, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 300),
                child: Icon(_items[i].$1, color: selected ? AppColors.tealDeep : AppColors.muted),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.tealDeep : AppColors.muted,
              ),
              child: Text(_items[i].$2),
            ),
          ],
        ),
      ),
    );
  }
}
