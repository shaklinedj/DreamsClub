import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/utils/spanish_asset_picker_delegate.dart';

class UploadPostScreen extends ConsumerStatefulWidget {
  const UploadPostScreen({super.key});

  @override
  ConsumerState<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends ConsumerState<UploadPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedFile;
  FeedMediaType _mediaType = FeedMediaType.image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _selectedCasinoId;

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    // Pre-select user's favorite casino
    final user = ref.read(userProvider);
    _selectedCasinoId = user.favoriteCasinoId;

    // Trigger gallery picker immediately on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openGallery();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Opens gallery directly, allowing selection of both images and videos
  /// Uses wechat_assets_picker for Instagram-like experience
  Future<void> _openGallery() async {
    try {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common, // Both images and videos
          themeColor: AppTheme.kPrimaryBlue,
          textDelegate: SpanishAssetPickerTextDelegate(),
        ),
      );

      if (result != null && result.isNotEmpty) {
        final AssetEntity asset = result.first;
        final File? file = await asset.file;

        if (file != null) {
          final bool isVideo = asset.type == AssetType.video;

          if (isVideo) {
            _videoController?.dispose();
            _videoController = VideoPlayerController.file(file)
              ..initialize().then((_) {
                if (mounted) setState(() {});
              });
          }

          setState(() {
            _selectedFile = file;
            _mediaType = isVideo ? FeedMediaType.video : FeedMediaType.image;
          });
        }
      } else {
        // User cancelled
        if (_selectedFile == null && mounted) {
          // Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar multimedia: $e')),
        );
      }
    }
  }

  /// Opens camera for photo
  Future<void> _openCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _processPickedFile(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }

  /// Process the picked file - detect type and set state
  Future<void> _processPickedFile(XFile pickedFile) async {
    final File file = File(pickedFile.path);
    final String path = pickedFile.path.toLowerCase();

    // Detect if it's a video based on extension
    final bool isVideo = path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm') ||
        path.endsWith('.3gp');

    if (isVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }

    setState(() {
      _selectedFile = file;
      _mediaType = isVideo ? FeedMediaType.video : FeedMediaType.image;
    });
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return null;

    try {
      String extension = _mediaType == FeedMediaType.video ? 'mp4' : 'jpg';
      String contentType =
          _mediaType == FeedMediaType.video ? 'video/mp4' : 'image/jpeg';

      if (_selectedFile != null) {
        final path = _selectedFile!.path;
        if (path.contains('.')) {
          extension = path.split('.').last.toLowerCase();
        }

        // Basic MIME type mapping
        if (extension == 'mov') contentType = 'video/quicktime';
        if (extension == 'avi') contentType = 'video/x-msvideo';
        if (extension == 'png') contentType = 'image/png';
        if (extension == 'heic') contentType = 'image/heic';
      }

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final Reference ref =
          FirebaseStorage.instance.ref().child('posts').child(fileName);

      // Add Cache-Control metadata for CDNs and Browser caching
      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      );

      final UploadTask uploadTask = ref.putFile(_selectedFile!, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  Future<void> _submitPost() async {
    final description = _descriptionController.text.trim();

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona una imagen o video')),
      );
      return;
    }

    if (_selectedCasinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor agrega una ubicación')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Upload Media
      final downloadUrl = await _uploadFile();
      if (downloadUrl == null) {
        throw Exception("No se pudo obtener URL de descarga");
      }

      // 2. Generate Title from Description (first 30 chars)
      String title = description.split('\n').first;
      if (title.length > 30) {
        title = '${title.substring(0, 27)}...';
      }
      if (title.isEmpty) {
        title = 'Nueva Publicación';
      }

      // 3. Create Post
      final newPost = FeedPost(
        id: '', // Firestore generates ID
        title: title,
        description: description,
        mediaUrl: downloadUrl,
        mediaType: _mediaType,
        postType: FeedPostType.news, // Default
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        casinoId: _selectedCasinoId!,
      );

      // 4. Save to Firestore via Provider
      await ref.read(feedProvider.notifier).addPost(newPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Publicación creada con éxito!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              subtitle: const Text('Fotos y videos'),
              onTap: () {
                Navigator.pop(context);
                _openGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              subtitle: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final casinosAsync = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.kPrimaryBlue)),
              ),
            )
          else
            TextButton(
              onPressed: _submitPost,
              child: const Text('Compartir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                      'Subiendo... ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLoading)
                    LinearProgressIndicator(value: _uploadProgress),

                  // Instagram Style: Row with Thumbnail + TextField
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        GestureDetector(
                          onTap: _showMediaPickerOptions,
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[800],
                            child: _selectedFile != null
                                ? _mediaType == FeedMediaType.video
                                    ? (_videoController != null &&
                                            _videoController!
                                                .value.isInitialized)
                                        ? FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _videoController!
                                                  .value.size.width,
                                              height: _videoController!
                                                  .value.size.height,
                                              child: VideoPlayer(
                                                  _videoController!),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.videocam,
                                                color: Colors.white))
                                    : Image.file(_selectedFile!,
                                        fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(Icons.add_a_photo,
                                        color: Colors.grey),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Caption
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un pie de foto...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              fillColor: Colors.transparent,
                            ),
                            maxLines: 5,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Location Selector
                  casinosAsync.when(
                    loading: () =>
                        const ListTile(title: Text('Cargando ubicaciones...')),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (casinos) {
                      final selectedCasino = casinos.firstWhere(
                        (c) => c.id == _selectedCasinoId,
                        orElse: () => casinos
                            .first, // Fallback dummy, handle properly below
                      );

                      final bool hasSelection = _selectedCasinoId != null &&
                          casinos.any((c) => c.id == _selectedCasinoId);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: const Text('Agregar ubicación',
                            style: TextStyle(fontSize: 16)),
                        subtitle: hasSelection
                            ? Text(selectedCasino.nombre,
                                style: const TextStyle(
                                    color: AppTheme.kPrimaryBlue))
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        leading: const Icon(Icons.location_on_outlined),
                        onTap: () {
                          // Show simple dialog to select casino
                          showDialog(
                              context: context,
                              builder: (context) {
                                return SimpleDialog(
                                  title: const Text('Seleccionar Ubicación'),
                                  children: casinos
                                      .map((c) => SimpleDialogOption(
                                            onPressed: () {
                                              setState(() {
                                                _selectedCasinoId = c.id;
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(c.nombre,
                                                  style: TextStyle(
                                                      color:
                                                          _selectedCasinoId ==
                                                                  c.id
                                                              ? AppTheme
                                                                  .kPrimaryBlue
                                                              : null,
                                                      fontWeight:
                                                          _selectedCasinoId ==
                                                                  c.id
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal)),
                                            ),
                                          ))
                                      .toList(),
                                );
                              });
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
    );
  }
}
