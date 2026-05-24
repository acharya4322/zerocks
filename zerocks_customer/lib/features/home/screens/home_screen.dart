import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
import '../../shops/screens/nearby_shops_screen.dart';
import '../../print_job/screens/my_jobs_screen.dart';
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
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: switch (currentIndex) {
          0 => const NearbyShopsScreen(),
          1 => const MyJobsScreen(),
          2 => _ProfileTab(
            colorScheme: colorScheme,
            textTheme: textTheme,
            authState: authState,
            ref: ref,
          ),
          _ => const NearbyShopsScreen(),
        },
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(homeTabIndexProvider.notifier).setTab(index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scanner'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AsyncValue authState;
  final WidgetRef ref;

  const _ProfileTab({
    required this.colorScheme,
    required this.textTheme,
    required this.authState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final user = authState.value;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 50,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.phoneNumber ?? 'Customer',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zerocks Customer',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            // Menu Items
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Print History',
                    onTap: () {
                      ref.read(homeTabIndexProvider.notifier).setTab(1);
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact support@zerocks.in'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Zerocks',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Zerocks',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text(
                            'Zerocks is a secure document printing platform '
                            'that connects you with nearby print shops for '
                            'quick, reliable printing.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sign Out
            Card(
              elevation: 0,
              color: colorScheme.errorContainer.withValues(alpha: 0.4),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                iconColor: colorScheme.error,
                titleColor: colorScheme.error,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content:
                          const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authServiceProvider).signOut();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
