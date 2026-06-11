import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shops/screens/nearby_shops_screen.dart';
import '../../print_job/screens/my_jobs_screen.dart';
import 'home_dashboard.dart';
import '../widgets/bottom_nav_bar.dart';

/// Tracks the currently selected bottom nav tab.
class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabNotifier, int>(HomeTabNotifier.new);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: switch (currentIndex) {
        0 => const HomeDashboard(),
        1 => const MyJobsScreen(),
        2 => const Scaffold(body: Center(child: Text('Scan Screen Placeholder'))), // Route handling typically done via GoRouter, but for tab we show placeholder
        3 => const NearbyShopsScreen(),
        _ => const HomeDashboard(),
      },
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 2) {
            // If they click scan tab, immediately push scanner route rather than switching tab
            context.push('/scanner');
          } else {
            ref.read(homeTabIndexProvider.notifier).setTab(index);
          }
        },
      ),
    );
  }
}

