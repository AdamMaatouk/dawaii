import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'history_screen.dart';
import '../services/language_service.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() =>
      _NavigationWrapperState();
}

class _NavigationWrapperState
    extends State<NavigationWrapper> {
  int _currentIndex = 0;
  final LanguageService _languageService =
      LanguageService();

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final navBackground =
        isDark
            ? const Color(0xFF101827)
            : Colors.white;

    final borderColor =
        isDark
            ? const Color(0xFF283548)
            : const Color(0xFFE2E8F0);

    final selectedColor =
        isDark
            ? const Color(0xFFA5B4FC)
            : const Color(0xFF4F46E5);

    final unselectedColor =
        isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF94A3B8);

    final overlayStyle =
        isDark
            ? SystemUiOverlayStyle.light
                .copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    navBackground,
                systemNavigationBarDividerColor:
                    navBackground,
                systemNavigationBarIconBrightness:
                    Brightness.light,
              )
            : SystemUiOverlayStyle.dark
                .copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    navBackground,
                systemNavigationBarDividerColor:
                    navBackground,
                systemNavigationBarIconBrightness:
                    Brightness.dark,
              );

    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              key: ValueKey(
                'home_$_currentIndex',
              ),
            ),
            HistoryScreen(
              key: ValueKey(
                'history_$_currentIndex',
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBackground,
            border: Border(
              top: BorderSide(
                color: borderColor,
              ),
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 10,
                      offset:
                          const Offset(
                        0,
                        -2,
                      ),
                    ),
                  ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex:
                  _currentIndex,
              type:
                  BottomNavigationBarType
                      .fixed,
              selectedItemColor:
                  selectedColor,
              unselectedItemColor:
                  unselectedColor,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
              unselectedLabelStyle:
                  const TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
              elevation: 0,
              backgroundColor:
                  navBackground,
              onTap: (index) {
                setState(() {
                  _currentIndex =
                      index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.today_rounded,
                  ),
                  activeIcon: Icon(
                    Icons
                        .calendar_month_rounded,
                  ),
                  label: _languageService.tr('schedule'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.insights_rounded,
                  ),
                  activeIcon: Icon(
                    Icons.auto_graph_rounded,
                  ),
                  label: _languageService.tr('analytics'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
