// import 'package:casinoloyalty_flutter/providers/location_monitoring_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);

      // Feedback haptico/sonoro podría ir aquí

      // Simular validación con backend (por ahora aceptamos todo)
      await _processVisit(code);
    }
  }

  Future<void> _processVisit(String code) async {
    // DEBUG MODE: No auth check - Cloud Function uses debug UID
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('registerVisit');

      // Call the Cloud Function (will use debug-hernan-laurel UID)
      final result = await callable.call(<String, dynamic>{
        'qrCode': code,
      });

      if (!mounted) return;

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool;
      final casinoName = data['casinoName'] as String;

      if (success) {
        _showSuccessDialog(casinoName);
      } else {
        throw Exception('Validación fallida');
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Error al registrar visita';
      if (e is FirebaseFunctionsException) {
        errorMessage = e.message ?? errorMessage;
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(String casinoName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline,
            color: Colors.green, size: 48),
        title: const Text('¡Visita Registrada!'),
        content: Text(
          'Bienvenido a $casinoName.\nTu visita ha sido registrada exitosamente.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back to previous screen
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  case TorchState.unavailable:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay UI
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),

          // Bottom instruction text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Escanea el QR en la entrada del casino',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper class for the overlay shape (standard implementation or use a package)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    // borderWidthSize removed
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mCutOutSize = cutOutSize;
    final mBorderLength = borderLength;
    final mBorderRadius = borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill; // Fixed syntax error

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Unused boxPaint removed

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top +
          height / 2 -
          mCutOutSize / 2 +
          borderOffset -
          cutOutBottomOffset,
      mCutOutSize - borderWidth,
      mCutOutSize - borderWidth,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(mBorderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final cutOutBottom = cutOutRect.bottom;
    final cutOutTop = cutOutRect.top;
    final cutOutLeft = cutOutRect.left;
    final cutOutRight = cutOutRect.right;

    // Draw borders
    // Top Left
    canvas.drawPath(
        Path()
          ..moveTo(cutOutLeft, cutOutTop + mBorderLength)
          ..lineTo(cutOutLeft, cutOutTop + mBorderRadius)
          ..arcToPoint(Offset(cutOutLeft + mBorderRadius, cutOutTop),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(cutOutLeft + mBorderLength, cutOutTop),
        borderPaint);

    // Top Right
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRight - mBorderLength, cutOutTop)
          ..lineTo(cutOutRight - mBorderRadius, cutOutTop)
          ..arcToPoint(Offset(cutOutRight, cutOutTop + mBorderRadius),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(cutOutRight, cutOutTop + mBorderLength),
        borderPaint);

    // Bottom Right
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRight, cutOutBottom - mBorderLength)
          ..lineTo(cutOutRight, cutOutBottom - mBorderRadius)
          ..arcToPoint(Offset(cutOutRight - mBorderRadius, cutOutBottom),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(cutOutRight - mBorderLength, cutOutBottom),
        borderPaint);

    // Bottom Left
    canvas.drawPath(
        Path()
          ..moveTo(cutOutLeft + mBorderLength, cutOutBottom)
          ..lineTo(cutOutLeft + mBorderRadius, cutOutBottom)
          ..arcToPoint(Offset(cutOutLeft, cutOutBottom - mBorderRadius),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(cutOutLeft, cutOutBottom - mBorderLength),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
