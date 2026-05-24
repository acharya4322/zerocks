/// Zerocks Common — Shared models, services, repositories, DTOs,
/// validators, and utilities for the Zerocks platform.
library;

// Models
export 'models/user_model.dart';
export 'models/shop_model.dart';
export 'models/print_job_model.dart';
export 'models/shop_owner_model.dart';
export 'models/pricing_model.dart';
export 'models/printer_status_model.dart';
export 'models/analytics_model.dart';

// Services
export 'services/auth_service.dart';
export 'services/firestore_service.dart';
export 'services/storage_service.dart';
export 'services/messaging_service.dart';

// Repositories
export 'repositories/auth_repository.dart';
export 'repositories/print_job_repository.dart';
export 'repositories/shop_repository.dart';
export 'repositories/user_repository.dart';

// DTOs
export 'dtos/create_job_dto.dart';
export 'dtos/update_job_dto.dart';

// Validators
export 'validators/file_validator.dart';
// Note: phone_validator.dart has its own ValidationResult class
// Import it directly to avoid conflicts:
// import 'package:zerocks_common/validators/phone_validator.dart';

// Utilities
export 'utils/date_utils.dart';
export 'utils/file_utils.dart';
export 'utils/geo_utils.dart';
export 'utils/queue_estimator.dart';
export 'utils/logger.dart';
