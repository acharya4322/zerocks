/// Data Transfer Object for creating a new print job.
/// Immutable — used to pass validated data from UI to repository.
class CreateJobDto {
  final String userId;
  final String shopId;
  final String shopName;
  final String fileName;
  final String fileType; // 'pdf' | 'image'
  final int fileSizeBytes;
  final int copies;
  final bool isColor;
  final bool isDuplex;
  final String pageSize; // 'A4' | 'A3' | 'Letter'
  final String orientation; // 'portrait' | 'landscape' | 'auto'
  final String? pageRange; // e.g. "1-5,8,10" or null for all

  const CreateJobDto({
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.copies = 1,
    this.isColor = false,
    this.isDuplex = false,
    this.pageSize = 'A4',
    this.orientation = 'auto',
    this.pageRange,
  });
}
