import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/print_service.dart';

/// File preview dialog with signed URL security.
///
/// Security model:
/// - First tries Cloud Function signed URL (production)
/// - Falls back to direct fileUrl (development/MVP)
/// - Files are never saved to disk
class FilePreviewDialog extends StatefulWidget {
  final PrintJobModel job;

  const FilePreviewDialog({super.key, required this.job});

  static void show(BuildContext context, PrintJobModel job) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FilePreviewDialog(job: job),
    );
  }

  @override
  State<FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
  final PrintService _printService = PrintService();
  String? _resolvedUrl;
  bool _isLoadingUrl = true;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _resolveFileUrl();
  }

  Future<void> _resolveFileUrl() async {
    // Try signed URL first (production path)
    try {
      final signedUrl = await _printService.getSignedUrl(widget.job.id);
      if (mounted) {
        setState(() {
          _resolvedUrl = signedUrl;
          _isLoadingUrl = false;
        });
      }
      return;
    } catch (e) {
      ZLogger.warn(
        'Signed URL unavailable, falling back to direct URL: $e',
        tag: 'FilePreview',
      );
    }

    // Fallback to direct URL (development/MVP)
    final directUrl = widget.job.fileUrl;
    if (directUrl != null && directUrl.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedUrl = directUrl;
          _isLoadingUrl = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _urlError = 'File not available';
          _isLoadingUrl = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCompleted = widget.job.status == PrintJobStatus.completed;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.job.fileType == 'pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.fileName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.job.copies} ${widget.job.copies == 1 ? 'copy' : 'copies'} • ${widget.job.fileType.toUpperCase()}'
                          '${widget.job.isColor ? ' • Color' : ''}'
                          '${widget.job.isDuplex ? ' • Duplex' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Print button
                  if (_resolvedUrl != null && !isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.icon(
                        onPressed: () => _printFile(context),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.printingColor,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Preview content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoadingUrl) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating secure link...',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_urlError != null || _resolvedUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_present_outlined,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _urlError ?? 'File not available',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The file may have been deleted after completion',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (widget.job.fileType == 'pdf') {
      return _PdfPreview(fileUrl: _resolvedUrl!);
    } else {
      return _ImagePreview(fileUrl: _resolvedUrl!);
    }
  }

  Future<void> _printFile(BuildContext context) async {
    if (_resolvedUrl == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing file for printing...'),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await _printService.printFromUrl(
        signedUrl: _resolvedUrl!,
        fileName: widget.job.fileName,
        fileType: widget.job.fileType,
        copies: widget.job.copies,
        isColor: widget.job.isColor,
        isDuplex: widget.job.isDuplex,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Print job sent!' : 'Printing cancelled',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e')),
        );
      }
    }
  }
}

class _PdfPreview extends StatelessWidget {
  final String fileUrl;

  const _PdfPreview({required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: SfPdfViewer.network(
        fileUrl,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (details) {
          // Error handled by built-in error widget
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String fileUrl;

  const _ImagePreview({required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            fileUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final progress = loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text(
                      'Loading image...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 56,
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
