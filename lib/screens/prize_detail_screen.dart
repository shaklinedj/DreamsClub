import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PrizeDetailScreen extends StatefulWidget {
  final String prizeId;

  const PrizeDetailScreen({super.key, required this.prizeId});

  @override
  State<PrizeDetailScreen> createState() => _PrizeDetailScreenState();
}

class _PrizeDetailScreenState extends State<PrizeDetailScreen> {
  final PrizeService _prizeService = PrizeService();
  WonPrize? _prize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrize();
  }

  Future<void> _loadPrize() async {
    setState(() => _isLoading = true);

    final prizes = await _prizeService.getMyPrizes();
    final prize = prizes.where((p) => p.id == widget.prizeId).firstOrNull;

    setState(() {
      _prize = prize;
      _isLoading = false;
    });
  }

  Future<void> _markAsRedeemed() async {
    if (_prize == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Canje',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Ya canjeaste este premio? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Sí, Canjear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _prizeService.redeemPrize(widget.prizeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premio canjeado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _sharePrize() {
    if (_prize == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: '¡Gané ${_prize!.prize.name} en Dreams! 🎉\n'
            '${_prize!.prize.description}\n\n'
            'Código QR: ${_prize!.qrCode}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del Premio'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_prize == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del Premio'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Premio no encontrado',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isExpired = _prize!.isExpired;
    final isRedeemed = _prize!.redeemed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Premio'),
        backgroundColor: Colors.black,
        actions: [
          if (!isRedeemed && !isExpired)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePrize,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Prize icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              ),
              child: Center(
                child: Text(
                  _prize!.prize.icon,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Prize name
            Text(
              _prize!.prize.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Prize description
            Text(
              _prize!.prize.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 32),

            // Status badges
            if (isRedeemed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  '✓ PREMIO CANJEADO',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            else if (isExpired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  '⏰ PREMIO EXPIRADO',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Text(
                  'Expira en: ${_prize!.daysUntilExpiry}',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 32),

            // QR Code
            if (!isRedeemed && !isExpired) ...[
              const Text(
                'Muestra este código QR al personal',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _prize!.qrCode,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Código de canje:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _prize!.qrCode,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              // ignore: prefer_const_constructors
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📋 Cómo canjear:',
                    style: TextStyle(
                        color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Acércate al personal del casino',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Muestra este código QR',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. ¡Disfruta tu premio!',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Redeem button
            if (!isRedeemed && !isExpired)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markAsRedeemed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Marcar como Canjeado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
