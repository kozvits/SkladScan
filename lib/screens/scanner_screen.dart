// lib/screens/scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.dataMatrix,
    ],
  );

  bool _scanned = false;
  bool _torchOn = false;
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _lineAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _lineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _scanned = true;
    _controller.stop();

    _showAddDialog(barcode.rawValue!);
  }

  void _showAddDialog(String barcode) {
    final nameCtrl = TextEditingController(text: barcode);
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Товар найден'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcode display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      barcode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название товара',
                hintText: 'Введите название',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Количество',
                suffixText: 'ед.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Back to home without result
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              Navigator.pop(ctx);
              Navigator.pop(context, {
                'barcode': barcode,
                'name': name.isEmpty ? barcode : name,
                'quantity': qty.clamp(1, 99999),
              });
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _scanned) {
        // Resume scanner if dialog was dismissed
        setState(() => _scanned = false);
        _controller.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Сканирование',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Scan line animation
          _ScanLine(animation: _lineAnimation),

          // Bottom hint
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: const Text(
                'Наведите камеру на штрихкод или QR-код\nEAN-13 · QR · Code128 · DataMatrix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  final Animation<double> animation;
  const _ScanLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    const scanAreaSize = 240.0;
    final screenH = MediaQuery.of(context).size.height;
    final scanTop = (screenH - scanAreaSize) / 2;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Positioned(
        top: scanTop + animation.value * scanAreaSize,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: scanAreaSize - 32,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.accent,
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 240.0;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );

    // Dim background
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, holePath),
      dimPaint,
    );

    // Corners
    const cornerLen = 24.0;
    const cornerWidth = 3.5;
    final cornerPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(scanRect.topLeft, scanRect.topLeft.translate(cornerLen, 0), cornerPaint);
    canvas.drawLine(scanRect.topLeft, scanRect.topLeft.translate(0, cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(scanRect.topRight, scanRect.topRight.translate(-cornerLen, 0), cornerPaint);
    canvas.drawLine(scanRect.topRight, scanRect.topRight.translate(0, cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(scanRect.bottomLeft, scanRect.bottomLeft.translate(cornerLen, 0), cornerPaint);
    canvas.drawLine(scanRect.bottomLeft, scanRect.bottomLeft.translate(0, -cornerLen), cornerPaint);
    // Bottom-right
    canvas.drawLine(scanRect.bottomRight, scanRect.bottomRight.translate(-cornerLen, 0), cornerPaint);
    canvas.drawLine(scanRect.bottomRight, scanRect.bottomRight.translate(0, -cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
