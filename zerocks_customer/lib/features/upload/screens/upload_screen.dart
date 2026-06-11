import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../shops/providers/shops_provider.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  final String shopId;

  const UploadScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadNotifierProvider);
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<UploadState>(uploadNotifierProvider, (prev, next) {
      if (next.status == UploadStatus.success && next.createdJobId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document uploaded successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Track',
              textColor: Colors.white,
              onPressed: () {
                context.push('/job/${next.createdJobId}');
              },
            ),
          ),
        );
        context.pop();
      }
      if (next.status == UploadStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Info Card
            shopAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Printing at shop: $shopId',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ),
              data: (shop) => Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.storefront,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop?.name ?? 'Unknown Shop',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (shop != null)
                              Text(
                                '₹${shop.pricePerPage.toStringAsFixed(1)}/page',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Picker Section
            Text(
              'Select Document',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (uploadState.fileName != null) ...[
              // Selected File Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          uploadState.fileType == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              uploadState.fileName!,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              uploadState.fileSizeFormatted,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        onPressed: uploadState.status == UploadStatus.uploading || 
                                   uploadState.status == UploadStatus.analyzing
                            ? null
                            : () => ref
                                .read(uploadNotifierProvider.notifier)
                                .reset(),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (uploadState.status == UploadStatus.analyzing) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Analyzing document...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              if (uploadState.analysis != null && uploadState.status != UploadStatus.analyzing) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.secondaryContainer,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 20,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analysis Results',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAnalysisMetric(
                              context,
                              icon: Icons.description_outlined,
                              value: '${uploadState.analysis!.totalPages}',
                              label: 'Pages',
                            ),
                            _buildAnalysisMetric(
                              context,
                              icon: Icons.palette_outlined,
                              value: '${uploadState.analysis!.colorPages}',
                              label: 'Color',
                            ),
                            _buildAnalysisMetric(
                              context,
                              icon: Icons.invert_colors_off_outlined,
                              value: '${uploadState.analysis!.bwPages}',
                              label: 'B&W',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Action Area: Scan or Pick
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: uploadState.status == UploadStatus.picking
                          ? null
                          : () => ref.read(uploadNotifierProvider.notifier).scanDocument(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 40,
                              color: colorScheme.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scan',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use Camera',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: uploadState.status == UploadStatus.picking
                          ? null
                          : () => ref.read(uploadNotifierProvider.notifier).pickFile(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              size: 40,
                              color: colorScheme.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Upload',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, JPG, PNG',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // Copies Selector
            Text(
              'Number of Copies',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: uploadState.copies > AppConstants.minCopies
                          ? () => ref
                              .read(uploadNotifierProvider.notifier)
                              .setCopies(uploadState.copies - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${uploadState.copies}',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: uploadState.copies < AppConstants.maxCopies
                          ? () => ref
                              .read(uploadNotifierProvider.notifier)
                              .setCopies(uploadState.copies + 1)
                          : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Continue Button
            FilledButton.icon(
              onPressed: uploadState.fileName != null && uploadState.status != UploadStatus.analyzing
                  ? () => context.push('/order/settings/$shopId')
                  : null,
              icon: const Icon(Icons.arrow_forward_outlined),
              label: const Text('Continue to Settings'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisMetric(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
