/// Exportaciones del módulo core.
///
/// Facilita importar todas las utilidades y servicios core
/// con una sola línea de import.
library;

// Constants
export 'constants/app_constants.dart';

// Enums
export 'enums/app_enums.dart';

// Extensions
export 'extensions/extensions.dart';

// Utils
export 'utils/app_logger.dart';
export 'utils/rate_limiter.dart';
export 'utils/retry_helper.dart';
export 'utils/validators.dart';

// Services
export 'services/analytics_service.dart';
export 'services/crashlytics_service.dart';
export 'services/connectivity_service.dart';
export 'services/haptic_service.dart';
