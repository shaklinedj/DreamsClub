import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final prize = prizes.where((p) => p.id == widget.prizeId || p.redemptionCode == widget.prizeId).firstOrNull;

    setState(() {
      _prize = prize;
      _isLoading = false;
    });
  }

  Future<void> _sharePrize() async {
    if (_prize == null) return;
    await SharePlus.instance.share(ShareParams(
      text: '¡Gané ${_prize!.prize.name} en Dreams Club! 🎉\n'
          '${_prize!.prize.description}\n\n'
          'Código de Canje: ${_prize!.redemptionCode}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF12121A),
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
        backgroundColor: const Color(0xFF12121A),
        appBar: AppBar(
          title: const Text('Detalle del Premio'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Premio no encontrado', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isExpired = _prize!.isExpired;
    final isRedeemed = _prize!.isRedeemed;
    final code = _prize!.redemptionCode.isNotEmpty ? _prize!.redemptionCode : _prize!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: const Text('Voucher de Premio'),
        backgroundColor: Colors.black,
        actions: [
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
            // Prize Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _prize!.prize.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Prize Name
            Text(
              _prize!.prize.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Prize Description
            Text(
              _prize!.prize.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 20),

            // Status Badges
            if (isRedeemed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _prize!.redeemedBy != null
                          ? 'CANJEADO POR ${_prize!.redeemedBy!.toUpperCase()}'
                          : 'CANJEADO EN CAJA / BARRA',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (isExpired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_off, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'PREMIO EXPIRADO',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFD4AF37), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Válido por: ${_prize!.daysUntilExpiry}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Giant Alphanumeric Code Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'CÓDIGO ALFANUMÉRICO DE COBRO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    code,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Código copiado para el atendedor!'),
                          backgroundColor: Color(0xFFD4AF37),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Copiar Código',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QR Code Container
            if (!isRedeemed && !isExpired) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // How to Redeem Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront, color: Color(0xFFD4AF37), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Instrucciones de Canje en Casino:',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Acércate a la barra de tragos, caja o restaurante de Casino Dreams.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '2. Dicta o muestra el código alfanumérico al atendedor.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '3. El atendedor quemará el código en el sistema y te entregará tu ticket impreso.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
