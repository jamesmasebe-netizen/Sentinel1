import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WmsScannerScreen extends StatefulWidget {
  const WmsScannerScreen({super.key});

  @override
  State<WmsScannerScreen> createState() => _WmsScannerScreenState();
}

class _WmsScannerScreenState extends State<WmsScannerScreen> {
  String? _scannedBarcode;
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
          _scannedBarcode = barcode.rawValue;
        });

        // Simulate fetching WMS logic
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Item Scanned'),
              content: Text('SKU / Bin: $_scannedBarcode\n\nPerform picking or packing action here.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isProcessing = false;
                      _scannedBarcode = null;
                    });
                  },
                  child: const Text('Continue Scanning'),
                ),
              ],
            );
          },
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS Mobile Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              // Toggle Flash (Requires MobileScannerController)
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(onDetect: _onDetect),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(48),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _scannedBarcode != null ? 'Processing: $_scannedBarcode' : 'Align barcode within the frame',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
