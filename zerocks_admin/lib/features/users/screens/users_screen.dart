import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/users_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Users',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                usersAsync.whenOrNull(
                      data: (users) => Chip(
                        label: Text('${users.length} total'),
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: usersAsync.when(
                data: (users) => _UsersTable(users: users),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading users: $e',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<UserModel> users;

  const _UsersTable({required this.users});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        columns: const [
          DataColumn(label: Text('UID')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Joined')),
        ],
        rows: users.map((user) {
          return DataRow(cells: [
            DataCell(
              SelectableText(
                user.uid.substring(0, 8),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            DataCell(Text(user.phoneNumber)),
            DataCell(Text(user.displayName ?? '—')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: user.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ),
            DataCell(Text(
              ZDateUtils.timeAgo(user.createdAt),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
