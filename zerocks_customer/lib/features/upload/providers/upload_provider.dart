import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../services/document_analysis_service.dart';
import '../../scanner/services/document_scanner_service.dart';

// ── Upload State ──────────────────────────────────────────

enum UploadStatus { idle, picking, analyzing, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final String? filePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String? fileType;
  final DocumentAnalysisModel? analysis;
  final int copies;
  final bool isColor;
  final bool isDuplex;
  final String pageSize;
  final double uploadProgress;
  final String? errorMessage;
  final String? createdJobId;

  const UploadState({
    this.status = UploadStatus.idle,
    this.filePath,
    this.fileName,
    this.fileSizeBytes,
    this.fileType,
    this.analysis,
    this.copies = 1,
    this.isColor = false,
    this.isDuplex = false,
    this.pageSize = 'A4',
    this.uploadProgress = 0,
    this.errorMessage,
    this.createdJobId,
  });

  UploadState copyWith({
    UploadStatus? status,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    String? fileType,
    DocumentAnalysisModel? analysis,
    int? copies,
    bool? isColor,
    bool? isDuplex,
    String? pageSize,
    double? uploadProgress,
    String? errorMessage,
    String? createdJobId,
  }) {
    return UploadState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileType: fileType ?? this.fileType,
      analysis: analysis ?? this.analysis,
      copies: copies ?? this.copies,
      isColor: isColor ?? this.isColor,
      isDuplex: isDuplex ?? this.isDuplex,
      pageSize: pageSize ?? this.pageSize,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      createdJobId: createdJobId,
    );
  }

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return '';
    return FileUtils.formatFileSize(fileSizeBytes!);
  }
}

// ── Upload Notifier ───────────────────────────────────────

class UploadNotifier extends Notifier<UploadState> {
  late StorageService _storageService;
  late FirestoreService _firestoreService;
  late String _userId;
  final DocumentAnalysisService _analysisService = DocumentAnalysisService();

  @override
  UploadState build() {
    _storageService = ref.watch(storageServiceProvider);
    _firestoreService = ref.watch(firestoreServiceProvider);
    final user = ref.watch(authStateProvider).value;
    _userId = user?.uid ?? '';
    return const UploadState();
  }

  Future<void> pickFile() async {
    state = state.copyWith(status: UploadStatus.picking);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'Could not access file',
        );
        return;
      }

      // Use FileValidator for validation
      final validation = FileValidator.validate(file.name, file.size);
      if (!validation.isValid) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: validation.errorMessage,
        );
        return;
      }

      final fileType = FileValidator.getFileType(file.name);

      state = state.copyWith(
        status: UploadStatus.analyzing,
        filePath: file.path,
        fileName: file.name,
        fileSizeBytes: file.size,
        fileType: fileType,
      );

      await _analyzeFile(file.path!, isScanned: false);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Failed to pick file: ${e.toString()}',
      );
    }
  }

  Future<void> scanDocument() async {
    state = state.copyWith(status: UploadStatus.picking);

    try {
      final scannerService = ref.read(documentScannerServiceProvider);
      final imagePaths = await scannerService.scanDocuments();

      if (imagePaths.isEmpty) {
        // User cancelled or no images scanned
        state = state.copyWith(status: UploadStatus.idle);
        return;
      }

      final filePath = await scannerService.createPdfFromImages(imagePaths);
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Generated PDF file not found');
      }

      final fileSize = await file.length();
      final fileName = filePath.split('/').last;

      final validation = FileValidator.validate(fileName, fileSize);
      if (!validation.isValid) {
        state = state.copyWith(
          status: UploadStatus.error,
          errorMessage: validation.errorMessage,
        );
        return;
      }

      state = state.copyWith(
        status: UploadStatus.analyzing,
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: fileSize,
        fileType: 'pdf',
      );

      await _analyzeFile(filePath, isScanned: true);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Scan failed: ${e.toString()}',
      );
    }
  }

  Future<void> _analyzeFile(String path, {required bool isScanned}) async {
    try {
      final analysis = await _analysisService.analyzeFile(File(path), isScanned: isScanned);
      
      state = state.copyWith(
        status: UploadStatus.idle,
        analysis: analysis,
        // Auto-select color mode if color pages are detected
        isColor: analysis.colorPages > 0,
      );
    } catch (e) {
      // If analysis fails, fallback to idle without analysis so user can still proceed
      state = state.copyWith(
        status: UploadStatus.idle,
      );
    }
  }

  void setCopies(int copies) {
    final clamped = copies.clamp(
      AppConstants.minCopies,
      AppConstants.maxCopies,
    );
    state = state.copyWith(copies: clamped);
  }

  void setColor(bool isColor) {
    state = state.copyWith(isColor: isColor);
  }

  void setDuplex(bool isDuplex) {
    state = state.copyWith(isDuplex: isDuplex);
  }

  void setPageSize(String pageSize) {
    state = state.copyWith(pageSize: pageSize);
  }

  Future<void> uploadAndCreateJob(String shopId) async {
    if (state.filePath == null || state.fileName == null) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Please select a file first',
      );
      return;
    }

    state = state.copyWith(
      status: UploadStatus.uploading,
      uploadProgress: 0,
      errorMessage: null,
    );

    try {
      final jobId = const Uuid().v4();

      state = state.copyWith(uploadProgress: 0.2);

      // Upload file
      final fileUrl = await _storageService.uploadFile(
        jobId: jobId,
        filePath: state.filePath!,
        fileName: state.fileName!,
      );

      state = state.copyWith(uploadProgress: 0.7);

      // We still create PrintJob directly for Phase 1 backwards compatibility
      // In Phase 3, this changes to creating an Order instead
      final job = PrintJobModel(
        id: jobId,
        userId: _userId,
        shopId: shopId,
        fileUrl: fileUrl,
        fileName: state.fileName!,
        fileType: state.fileType ?? 'pdf',
        fileSizeBytes: state.fileSizeBytes,
        pageCount: state.analysis?.totalPages,
        status: PrintJobStatus.uploaded,
        copies: state.copies,
        isColor: state.isColor,
        isDuplex: state.isDuplex,
        pageSize: state.pageSize,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPrintJob(job);

      state = state.copyWith(
        status: UploadStatus.success,
        uploadProgress: 1.0,
        createdJobId: jobId,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Upload failed: ${e.toString()}',
        uploadProgress: 0,
      );
    }
  }

  void reset() {
    state = const UploadState();
  }
}

// ── Provider ──────────────────────────────────────────────

final uploadNotifierProvider =
    NotifierProvider<UploadNotifier, UploadState>(UploadNotifier.new);
