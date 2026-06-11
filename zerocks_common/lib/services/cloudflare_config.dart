class CloudflareR2Config {
  /// Your Cloudflare Account ID (found on your Cloudflare dashboard/R2 page)
  static const String accountId = 'ddbb2fdb59135f355abff0a5ed221a74';

  /// Your Cloudflare R2 Bucket Name
  static const String bucketName = 'zerocks-storage';

  /// R2 API Access Key ID
  static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';

  /// R2 API Secret Access Key
  static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';

  /// Public Bucket URL or Custom Domain mapping.
  /// Used for generating read/download URLs for print shops.
  /// Example: 'https://pub-xxxxxx.r2.dev' or 'https://storage.zerocks.com'
  static const String publicUrl =
      'https://YOUR_PUBLIC_BUCKET_URL_OR_CUSTOM_DOMAIN';

  /// R2 Default Region (R2 S3-compatible API uses 'auto')
  static const String region = 'auto';

  /// Check if the configuration has been modified with actual credentials
  static bool get isConfigured {
    return accountId != 'YOUR_CLOUDFLARE_ACCOUNT_ID' &&
        accessKeyId != 'YOUR_ACCESS_KEY_ID' &&
        secretAccessKey != 'YOUR_SECRET_ACCESS_KEY';
  }
}
