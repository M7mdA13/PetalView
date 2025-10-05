import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petalview/home/tabs/account.dart';
import 'package:petalview/home/tabs/community.dart';
import 'package:petalview/home/tabs/explor.dart';
import 'package:petalview/home/tabs/map.dart';
import 'package:petalview/home/tabs/predection.dart';

const Color kGreen = Color(0xFF2E7D32);
const Color kBarGreen = Color(0xFF2E7D32); // أخضر أدكن شوية لشريط التنقل
const Color kIndicator = Color(0xFFFFE0B2); // بيج فاتح للمؤشر
const Color kLabel = Colors.white;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _index = 2; // خليه يبدأ على Map مثلاً
  final _pages = const [
    ExploreScreen(),
    PredectionScreen(),
    MapScreen(),
    CommunityScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BloomBottomBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BloomItem(icon: Icons.search, label: 'Explore'),
          BloomItem(icon: Icons.analytics_outlined, label: 'Prediction'),
          BloomItem(icon: Icons.place_rounded, label: 'Map'),
          BloomItem(icon: Icons.groups_rounded, label: 'Community'),
          BloomItem(icon: Icons.person_outline_rounded, label: 'Account'),
        ],
      ),
    );
  }
}

/// عنصر (أيقونة + نص)
class BloomItem {
  final IconData icon;
  final String label;

  const BloomItem({required this.icon, required this.label});
}

/// Bottom bar مخصّص مع مؤشر متحرك
class BloomBottomBar extends StatelessWidget {
  final List<BloomItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BloomBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(color: kBarGreen),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          const indicatorWidth = 60.0;
          final indicatorLeft =
              currentIndex * itemWidth + (itemWidth - indicatorWidth) / 2;

          return Stack(
            children: [
              // عناصر الأيقونات والنصوص
              Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => onTap(i),
                        splashColor: Colors.white10,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(items[i].icon, color: i == currentIndex
                                  ? kIndicator
                                  : kLabel,),
                              const SizedBox(height: 2),
                              Text(
                                items[i].label,
                                style: TextStyle(
                                  color: i == currentIndex
                                      ? kIndicator
                                      : kLabel,
                                  fontWeight: i == currentIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // المؤشر المتحرك أسفل التب النشط
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: indicatorLeft,
                right: constraints.maxWidth - indicatorLeft - indicatorWidth,
                bottom: 24,
                child: Container(
                  height: 6,
                  width: indicatorWidth,
                  decoration: BoxDecoration(
                    color: kIndicator,
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


