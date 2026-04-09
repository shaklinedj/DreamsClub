import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// Spanish translation for the AssetPicker
class SpanishAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const SpanishAssetPickerTextDelegate();

  @override
  String get languageCode => 'es';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get gifIndicator => 'GIF';

  @override
  String get loadFailed => 'Error al cargar';

  @override
  String get original => 'Original';

  @override
  String get preview => 'Vista previa';

  @override
  String get select => 'Seleccionar';

  @override
  String get emptyList => 'Lista vacía';

  @override
  String get unSupportedAssetType => 'Tipo de archivo no soportado';

  @override
  String get unableToAccessAll =>
      'No se puede acceder a todos los archivos del dispositivo';

  @override
  String get viewingLimitedAssetsTip =>
      'Solo puedes ver archivos y álbumes accesibles por la app';

  @override
  String get changeAccessibleLimitedAssets =>
      'Toca para actualizar archivos accesibles';

  @override
  String get accessAllTip =>
      'La app solo puede acceder a algunos archivos del dispositivo. '
      'Ve a Configuración y permite a la app acceder a todos los archivos.';

  @override
  String get goToSystemSettings => 'Ir a Configuración';

  @override
  String get accessLimitedAssets => 'Continuar con acceso limitado';

  @override
  String get accessiblePathName => 'Archivos accesibles';

  @override
  String durationIndicatorBuilder(Duration duration) {
    const String separator = ':';
    final String minute = duration.inMinutes.toString().padLeft(2, '0');
    final String second =
        ((duration - Duration(minutes: duration.inMinutes)).inSeconds)
            .toString()
            .padLeft(2, '0');
    return '$minute$separator$second';
  }

  @override
  AssetPickerTextDelegate get semanticsTextDelegate => this;

  @override
  String semanticTypeLabel(AssetType type) {
    switch (type) {
      case AssetType.audio:
        return 'Audio';
      case AssetType.image:
        return 'Imagen';
      case AssetType.video:
        return 'Video';
      case AssetType.other:
        return 'Otro';
    }
  }

  @override
  String get sTypeAudioLabel => 'Audio';

  @override
  String get sTypeImageLabel => 'Imagen';

  @override
  String get sTypeVideoLabel => 'Video';

  @override
  String get sTypeOtherLabel => 'Otro';

  @override
  String get sActionPlayHint => 'reproducir';

  @override
  String get sActionPreviewHint => 'vista previa';

  @override
  String get sActionSelectHint => 'seleccionar';

  @override
  String get sActionSwitchPathLabel => 'cambiar carpeta';

  @override
  String get sActionUseCameraHint => 'usar cámara';

  @override
  String get sNameDurationLabel => 'duración';

  @override
  String get sUnitAssetCountLabel => 'cantidad';
}
