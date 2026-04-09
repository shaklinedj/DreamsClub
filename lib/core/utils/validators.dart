/// Validadores para entrada de usuario.
///
/// Proporciona métodos de validación reutilizables
/// para formularios y datos de entrada.
library;

/// Clase con métodos estáticos para validación de datos.
class Validators {
  Validators._();

  /// Valida que un campo no esté vacío.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida formato de email.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  /// Valida formato de teléfono chileno.
  static String? validatePhoneChile(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    // Formato chileno: +56 9 XXXX XXXX o 9 XXXX XXXX
    final phoneRegex = RegExp(r'^(\+56\s?)?9\s?\d{4}\s?\d{4}$');

    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Teléfono inválido. Formato: 9 XXXX XXXX';
    }

    return null;
  }

  /// Valida formato de teléfono internacional.
  static String? validatePhoneInternational(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Teléfono inválido';
    }

    return null;
  }

  /// Valida longitud mínima.
  static String? validateMinLength(
      String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Valida longitud máxima.
  static String? validateMaxLength(
      String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }
    return null;
  }

  /// Valida que sea un número.
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }

    return null;
  }

  /// Valida que sea un número positivo.
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName debe ser un número positivo';
    }

    return null;
  }

  /// Valida rango de número.
  static String? validateNumberRange(
    String? value,
    double min,
    double max,
    String fieldName,
  ) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;

    final number = double.parse(value!);
    if (number < min || number > max) {
      return '$fieldName debe estar entre $min y $max';
    }

    return null;
  }

  /// Valida RUT chileno.
  static String? validateRut(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUT es requerido';
    }

    // Limpiar RUT
    String rut = value.replaceAll(RegExp(r'[.-]'), '').toUpperCase();

    if (rut.length < 2) {
      return 'RUT inválido';
    }

    // Separar cuerpo y dígito verificador
    String body = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    // Validar que el cuerpo sea numérico
    if (int.tryParse(body) == null) {
      return 'RUT inválido';
    }

    // Calcular dígito verificador
    int suma = 0;
    int multiplicador = 2;

    for (int i = body.length - 1; i >= 0; i--) {
      suma += int.parse(body[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }

    int resto = suma % 11;
    String dvCalculado = resto == 0
        ? '0'
        : resto == 1
            ? 'K'
            : (11 - resto).toString();

    if (dv != dvCalculado) {
      return 'RUT inválido';
    }

    return null;
  }

  /// Valida URL.
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL es opcional
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'URL inválida';
    }

    return null;
  }

  /// Valida coordenadas geográficas.
  static String? validateLatitude(double? value) {
    if (value == null) {
      return 'Latitud es requerida';
    }
    if (value < -90 || value > 90) {
      return 'Latitud debe estar entre -90 y 90';
    }
    return null;
  }

  static String? validateLongitude(double? value) {
    if (value == null) {
      return 'Longitud es requerida';
    }
    if (value < -180 || value > 180) {
      return 'Longitud debe estar entre -180 y 180';
    }
    return null;
  }
}
