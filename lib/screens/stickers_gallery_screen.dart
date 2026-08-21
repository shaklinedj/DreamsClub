import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack_exception.dart';
import 'package:whatsapp_stickers_handler/service/sticker_pack_util.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class StickersGalleryScreen extends ConsumerStatefulWidget {
  final int? targetStreakTier;
  final String? packName;

  const StickersGalleryScreen({
    super.key,
    this.targetStreakTier,
    this.packName,
  });

  @override
  ConsumerState<StickersGalleryScreen> createState() => _StickersGalleryScreenState();
}

class _StickersGalleryScreenState extends ConsumerState<StickersGalleryScreen> {
  bool _isProcessing = false;
  String _progressText = '';

  /// Recorta fondos oscuros o blancos para dejar transparencia transparente en stickers
  Future<File> _processAndCutoutImage(File file, Directory dir, String name) async {
    try {
      final bytes = await file.readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded != null) {
        decoded = decoded.convert(numChannels: 4);
        for (final pixel in decoded) {
          // Remover fondo blanco / claro
          if (pixel.r > 235 && pixel.g > 235 && pixel.b > 235) {
            pixel.a = 0;
          }
          // Remover fondo muy oscuro / negro puro
          else if (pixel.r < 25 && pixel.g < 25 && pixel.b < 25) {
            pixel.a = 0;
          }
        }
        final pngBytes = img.encodePng(decoded);
        final outFile = File('${dir.path}/cutout_$name.png');
        return await outFile.writeAsBytes(pngBytes);
      }
    } catch (e) {
      debugPrint('Error recortando fondo de sticker: $e');
    }
    return file;
  }

  /// Helper para convertir la URL de Google Drive a formato de descarga directa
  String _getDirectImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    final trimmed = rawUrl.trim();

    String? fileId;
    if (trimmed.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/open?id=')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/uc')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('googleusercontent.com/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else {
      return trimmed;
    }

    if (fileId != null) {
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return trimmed;
  }

  /// Helper para copiar un sticker de los assets locales a un archivo temporal
  Future<File?> _loadAssetStickerToTemp(String assetPath, Directory dir, String name) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final file = File('${dir.path}/$name.jpg');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      return file;
    } catch (e) {
      debugPrint('Error cargando sticker asset $assetPath: $e');
      return null;
    }
  }

  /// Descarga SOLO las imágenes desbloqueadas por racha, las convierte a WebP y las instala en WhatsApp
  Future<void> _installStickerPack(List<QueryDocumentSnapshot> unlockedDocs) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _progressText = 'Preparando pack de stickers...';
    });

    try {
      final handler = WhatsappStickersHandler();

      // Verificar si WhatsApp está instalado
      final isInstalled = await handler.isWhatsAppInstalled;
      if (!isInstalled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp no está instalado en este dispositivo.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final tierId = widget.targetStreakTier ?? 0;
      final stickerDir = Directory('${appDir.path}/stickers_pack_tier_$tierId');
      if (await stickerDir.exists()) {
        await stickerDir.delete(recursive: true);
      }
      await stickerDir.create(recursive: true);

      final List<String> stickerPaths = [];
      final stickerUtil = StickerPackUtil();

      // 1. Procesar stickers de Firestore desbloqueados
      for (int i = 0; i < unlockedDocs.length && stickerPaths.length < 30; i++) {
        final data = unlockedDocs[i].data() as Map<String, dynamic>;
        final rawUrl = data['url'] as String? ?? '';
        final name = data['name'] as String? ?? 'sticker_$i';

        if (rawUrl.isEmpty) continue;

        setState(() {
          _progressText = 'Procesando ${i + 1}/${unlockedDocs.length}: $name...';
        });

        final directUrl = _getDirectImageUrl(rawUrl);

        try {
          final fileInfo = await DefaultCacheManager().downloadFile(directUrl);
          final cutoutFile = await _processAndCutoutImage(fileInfo.file, stickerDir, 'stk_$i');
          final webpPath = await stickerUtil.createStickerFromImage(
            cutoutFile.path,
            '${stickerDir.path}/sticker_$i.webp',
          );
          stickerPaths.add(webpPath);
        } catch (e) {
          debugPrint('Error procesando sticker $name: $e');
        }
      }

      // 2. WhatsApp exige al menos 3 stickers por pack. Si hay menos de 3, completamos con assets locales de la app
      if (stickerPaths.length < 3) {
        setState(() {
          _progressText = 'Completando pack de racha...';
        });

        final defaultAssets = [
          'assets/images/stickers/sticker_streak_${tierId == 0 ? 1 : tierId}.jpg',
          'assets/images/stickers/sticker_cat_poker.jpg',
          'assets/images/stickers/sticker_cat_mate.jpg',
          'assets/images/stickers/sticker_cat_jackpot.jpg',
          'assets/images/stickers/sticker_cat_roulette.jpg',
        ];

        int assetIndex = 0;
        while (stickerPaths.length < 3 && assetIndex < defaultAssets.length) {
          final assetPath = defaultAssets[assetIndex];
          assetIndex++;

          final file = await _loadAssetStickerToTemp(assetPath, stickerDir, 'local_asset_$assetIndex');
          if (file != null) {
            final cutoutFile = await _processAndCutoutImage(file, stickerDir, 'cutout_local_$assetIndex');
            final webpPath = await stickerUtil.createStickerFromImage(
              cutoutFile.path,
              '${stickerDir.path}/local_sticker_$assetIndex.webp',
            );
            stickerPaths.add(webpPath);
          }
        }
      }

      if (stickerPaths.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requieren al menos 3 stickers para instalar el pack en WhatsApp.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      setState(() {
        _progressText = 'Creando pack exclusivo...';
      });

      // Crear tray icon desde el primer sticker
      final trayImagePath = await stickerUtil.saveWebpAsTrayImage(stickerPaths.first);

      // Crear el Pack con ID y Nombre limpios sin caracteres especiales para que WhatsApp los acepte sin error
      final packIdentifier = 'dreams_pack_tier_${widget.targetStreakTier ?? 0}';
      final rawTitle = widget.packName ?? (widget.targetStreakTier != null ? 'Dreams Racha ${widget.targetStreakTier}d' : 'Dreams Club Coyhaique');
      
      String removeAccents(String str) {
        return str
            .replaceAll(RegExp(r'[áàäâÁÀÄÂ]'), 'a')
            .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
            .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
            .replaceAll(RegExp(r'[óòöôÓÒÖÔ]'), 'o')
            .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u')
            .replaceAll(RegExp(r'[ñÑ]'), 'n');
      }

      final cleanTitle = removeAccents(rawTitle)
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('&', 'y')
          .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')
          .trim();

      final stickerPack = StickerPack(
        identifier: packIdentifier,
        name: cleanTitle,
        publisher: 'Dreams Club',
        trayImage: trayImagePath,
        stickers: stickerPaths,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progressText = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abriendo WhatsApp para guardar "$cleanTitle"...'),
            backgroundColor: const Color(0xFF25D366),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      try {
        await handler.addStickerPack(stickerPack);
      } catch (e) {
        debugPrint('addStickerPack execution result: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Atención al abrir WhatsApp: $e'),
              backgroundColor: Colors.orangeAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

    } on StickerPackException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de sticker pack: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progressText = '';
        });
      }
    }
  }

  void _showStickerPreview(Map<String, dynamic> stickerData) {
    final rawUrl = stickerData['url'] as String? ?? '';
    final name = stickerData['name'] as String? ?? 'Sticker';
    final directUrl = _getDirectImageUrl(rawUrl);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: directUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.orange),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStreak = ref.watch(userProvider).streak;
    final displayTitle = widget.packName ?? 'Pack de Stickers';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stickers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar stickers:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5200)));
          }

          final docs = snapshot.data?.docs ?? [];

          // Filtrar estrictamente por el nivel de racha exclusivo de este pack
          List<QueryDocumentSnapshot> filteredDocs = docs;
          if (widget.targetStreakTier != null) {
            filteredDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final req = (data['requiredStreak'] as num?)?.toInt() ?? 0;
              return req == widget.targetStreakTier;
            }).toList();
          }

          // Separar en desbloqueados vs bloqueados según la racha del usuario
          final unlockedDocs = filteredDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final required = (data['requiredStreak'] as num?)?.toInt() ?? 0;
            return userStreak >= required;
          }).toList();

          final lockedDocs = filteredDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final required = (data['requiredStreak'] as num?)?.toInt() ?? 0;
            return userStreak < required;
          }).toList();

          if (filteredDocs.isEmpty && docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay stickers publicados.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            children: [
              // Botón principal para instalar el pack específico en WhatsApp
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _installStickerPack(unlockedDocs),
                    icon: _isProcessing 
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: Text(
                      _isProcessing ? _progressText : 'Agregar Pack a WhatsApp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // Color verde de WhatsApp
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.lock_open, color: Colors.green[400], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${unlockedDocs.length} desbloqueados',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    if (lockedDocs.isNotEmpty) ...[
                      Icon(Icons.lock, color: Colors.red[300], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${lockedDocs.length} bloqueados · Tu Racha: ${userStreak}d',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Grilla de stickers
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: unlockedDocs.length + lockedDocs.length,
                  itemBuilder: (context, index) {
                    final isLocked = index >= unlockedDocs.length;
                    final doc = isLocked ? lockedDocs[index - unlockedDocs.length] : unlockedDocs[index];
                    final stickerData = doc.data() as Map<String, dynamic>;
                    final rawUrl = stickerData['url'] as String? ?? '';
                    final directUrl = _getDirectImageUrl(rawUrl);
                    final requiredStreak = (stickerData['requiredStreak'] as num?)?.toInt() ?? 0;

                    return GestureDetector(
                      onTap: isLocked
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('🔒 Necesitas una racha de $requiredStreak días para este sticker'),
                                backgroundColor: Colors.orange[800],
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          : () => _showStickerPreview(stickerData),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isLocked ? 0.02 : 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLocked
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ColorFiltered(
                                  colorFilter: isLocked
                                      ? const ColorFilter.matrix(<double>[
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0,      0,      0,      0.4, 0,
                                        ])
                                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                                  child: CachedNetworkImage(
                                    imageUrl: directUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                    ),
                                    errorWidget: (context, url, error) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white30),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isLocked)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock, color: Colors.white60, size: 24),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$requiredStreak días',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
