import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../upload/providers/upload_provider.dart';

class PrintSettingsScreen extends ConsumerWidget {
  final String shopId;

  const PrintSettingsScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected Document Info
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(
                  uploadState.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                  color: colorScheme.primary,
                ),
                title: Text(
                  uploadState.fileName ?? 'Unknown file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(uploadState.fileSizeFormatted),
              ),
            ),
            const SizedBox(height: 24),

            // Print Settings Form
            Text('Color Mode', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'bw', label: Text('Black & White')),
                ButtonSegment(value: 'color', label: Text('Color')),
              ],
              selected: {uploadState.isColor ? 'color' : 'bw'},
              onSelectionChanged: (values) {
                ref.read(uploadNotifierProvider.notifier).setColor(values.first == 'color');
              },
            ),
            const SizedBox(height: 24),

            Text('Print Sides', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'single', label: Text('Single Sided')),
                ButtonSegment(value: 'double', label: Text('Double Sided')),
              ],
              selected: {uploadState.isDuplex ? 'double' : 'single'},
              onSelectionChanged: (values) {
                ref.read(uploadNotifierProvider.notifier).setDuplex(values.first == 'double');
              },
            ),
            const SizedBox(height: 24),

            Text('Page Size', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              initialSelection: uploadState.pageSize,
              onSelected: (value) {
                if (value != null) {
                  ref.read(uploadNotifierProvider.notifier).setPageSize(value);
                }
              },
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'A4', label: 'A4 (Standard)'),
                DropdownMenuEntry(value: 'A3', label: 'A3 (Large)'),
                DropdownMenuEntry(value: 'Letter', label: 'Letter'),
                DropdownMenuEntry(value: 'Legal', label: 'Legal'),
              ],
            ),
            
            const SizedBox(height: 48),

            FilledButton(
              onPressed: () {
                context.push('/order/services/$shopId');
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Continue to Services'),
            ),
          ],
        ),
      ),
    );
  }
}
