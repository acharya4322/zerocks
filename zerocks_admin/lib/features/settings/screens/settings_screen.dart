import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),

            // Admin info
            _SettingsSection(
              title: 'Admin Account',
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Email',
                  subtitle: user?.email ?? '—',
                ),
                _SettingsTile(
                  icon: Icons.key_outlined,
                  title: 'UID',
                  subtitle: user?.uid ?? '—',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Platform settings
            _SettingsSection(
              title: 'Platform',
              children: [
                _SettingsTile(
                  icon: Icons.timer_outlined,
                  title: 'Job Expiry',
                  subtitle: '24 hours (configured in Cloud Functions)',
                ),
                _SettingsTile(
                  icon: Icons.file_upload_outlined,
                  title: 'Max File Size',
                  subtitle: '10 MB (enforced in Storage rules)',
                ),
                _SettingsTile(
                  icon: Icons.link_outlined,
                  title: 'Signed URL Expiry',
                  subtitle: '15 minutes (configured in Cloud Functions)',
                ),
                _SettingsTile(
                  icon: Icons.schedule_outlined,
                  title: 'Cleanup Schedule',
                  subtitle: 'Every 60 minutes (cleanupExpiredJobs)',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Security
            _SettingsSection(
              title: 'Security',
              children: [
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Role-Based Access',
                  subtitle: 'Custom claims: superadmin, admin, shop_owner, customer',
                ),
                _SettingsTile(
                  icon: Icons.lock_outlined,
                  title: 'File Access',
                  subtitle: 'Signed URLs via generateSignedUrl Cloud Function',
                ),
                _SettingsTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Auto-Delete',
                  subtitle: 'Files deleted on job completion via onJobStatusChanged',
                ),
              ],
            ),

            const Spacer(),

            // Danger zone
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Platform settings are configured in Cloud Functions and Firebase Console. '
                      'Changes require a redeploy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
