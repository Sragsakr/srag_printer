import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:srag_printer/srag_printer.dart';

/// Starts the `srag_printer` example application.
void main() {
  runApp(const SragPrinterExampleApp());
}

/// Example app shell for trying the package manually.
class SragPrinterExampleApp extends StatelessWidget {
  /// Creates the example app.
  const SragPrinterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'srag_printer example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const ExampleHomePage(),
    );
  }
}

/// Home page that demonstrates discovery, configuration, and print flows.
class ExampleHomePage extends StatefulWidget {
  /// Creates the example home page.
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final TextEditingController _host = TextEditingController(text: '192.168.1.50');
  final TextEditingController _port = TextEditingController(text: '9100');
  PrinterConnectionType _type = PrinterConnectionType.network;
  SragPaper _paper = const SragPaper.mm80();
  bool _cut = true;
  int _chunkSize = 512;
  String _log = 'Ready';
  List<PrinterDevice> _devices = <PrinterDevice>[];
  PrinterDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    SragFonts.load().then((_) => setState(() {}));
  }

  SragReceiptStyle get _receiptStyle => SragReceiptStyle.defaults();

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('srag_printer example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<PrinterConnectionType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Connection type'),
            items: PrinterConnectionType.values
                .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _host,
            decoration: const InputDecoration(labelText: 'Network host'),
          ),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: 'Network port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paper.name,
            decoration: const InputDecoration(labelText: 'Paper'),
            items: const [
              DropdownMenuItem(value: '58mm', child: Text('58mm / 384 dots')),
              DropdownMenuItem(value: '80mm', child: Text('80mm / 528 dots')),
              DropdownMenuItem(value: '80mm wide', child: Text('80mm / 576 dots')),
            ],
            onChanged: (value) {
              setState(() {
                _paper = switch (value) {
                  '58mm' => const SragPaper.mm58(),
                  '80mm wide' => const SragPaper.mm80Wide(),
                  _ => const SragPaper.mm80(),
                };
              });
            },
          ),
          SwitchListTile(
            value: _cut,
            title: const Text('Cut after print'),
            onChanged: (value) => setState(() => _cut = value),
          ),
          Slider(
            value: _chunkSize.toDouble(),
            min: 128,
            max: 2048,
            divisions: 15,
            label: 'Chunk $_chunkSize',
            onChanged: (value) => setState(() => _chunkSize = value.round()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _discover,
                child: const Text('Discover'),
              ),
              FilledButton(
                onPressed: _printTestImage,
                child: const Text('Print image'),
              ),
              FilledButton(
                onPressed: _printCustomWidget,
                child: const Text('Print widget'),
              ),
              FilledButton(
                onPressed: _printReceiptEnglish,
                child: const Text('English receipt'),
              ),
              FilledButton(
                onPressed: _printReceiptArabic,
                child: const Text('Arabic receipt'),
              ),
              FilledButton(
                onPressed: _printReceiptBilingual,
                child: const Text('Bilingual receipt'),
              ),
              OutlinedButton(
                onPressed: _renderPdfPreview,
                child: const Text('Render PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_devices.isNotEmpty)
            DropdownButtonFormField<PrinterDevice>(
              value: _selectedDevice,
              decoration: const InputDecoration(labelText: 'Discovered device'),
              items: _devices
                  .map(
                    (device) => DropdownMenuItem(
                      value: device,
                      child: Text('${device.name} (${device.connectionType.name})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedDevice = value),
            ),
          const SizedBox(height: 16),
          SelectableText(_log),
        ],
      ),
    );
  }

  SragPrinter _printer() {
    return SragPrinter(
      transport: _transport(),
      config: SragPrinterConfig(
        paper: _paper,
        chunkSize: _chunkSize,
        cutAfterPrint: _cut,
      ),
    );
  }

  PrinterTransport _transport() {
    if (_type == PrinterConnectionType.network) {
      return NetworkPrinterTransport(
        host: _host.text,
        port: int.tryParse(_port.text) ?? 9100,
      );
    }
    final selected = _selectedDevice;
    if (selected == null) {
      return MemoryPrinterTransport();
    }
    return selected.createTransport(
      networkHost: _host.text,
      networkPort: int.tryParse(_port.text) ?? 9100,
    );
  }

  Future<void> _discover() async {
    try {
      final hasPermissions = await _ensureRuntimePermissions();
      if (!hasPermissions) {
        setState(() {
          _log = 'Required permission was denied. '
              'Open system settings and allow the requested access.';
        });
        return;
      }
      final devices = await SragPrinterDiscovery.discover(
        request: PrinterDiscoveryRequest(connectionType: _type),
      );
      setState(() {
        _devices = devices;
        _selectedDevice = devices.isEmpty ? null : devices.first;
        _log = 'Found ${devices.length} device(s). Select one before printing.';
      });
    } catch (error) {
      setState(() => _log = 'Discovery error: $error');
    }
  }

  Future<bool> _ensureRuntimePermissions() async {
    if (_type != PrinterConnectionType.bluetooth) return true;

    final permissions = switch (defaultTargetPlatform) {
      TargetPlatform.android => <Permission>[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ],
      TargetPlatform.iOS || TargetPlatform.macOS => <Permission>[
          Permission.bluetooth,
        ],
      _ => <Permission>[],
    };

    for (final permission in permissions) {
      if (await permission.isGranted) continue;
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }
    return true;
  }

  Future<void> _printTestImage() async {
    final frame = _buildTestImage();
    await _run(() => _printer().printImages([frame]));
  }

  Future<void> _printCustomWidget() async {
    await _run(
      () => _printer().printWidget(
        (_) {
          final style = _receiptStyle;
          return SragReceipt(
            style: style,
            children: [
              ReceiptHeader(
                style: style,
                titles: const [
                  'srag_printer',
                  'Thermal Printing Solution',
                ],
              ),
              ReceiptDivider(),
              pw.Center(child: pw.Text('Welcome to srag_printer!')),
              pw.Center(child: pw.Text('Print any PDF widget with ease')),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('srag.sabry@gmail.com')),
              pw.Center(child: pw.Text('+201029382968')),
              ReceiptDivider(),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  children: [
                    pw.Center(child: pw.Text('مرحباً بكم في طباعة سراج!')),
                    pw.Center(child: pw.Text('اطبع أي محتوى بسهولة تامة')),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // English receipt
  // ---------------------------------------------------------------------------
  Future<void> _printReceiptEnglish() async {
    final style = _receiptStyle;
    await _run(
      () => _printer().printWidget(
        (_) => SragReceipt(
          style: style,
          children: [
            ReceiptHeader(
              style: style,
              titles: const ['Coffee House', 'Tax Invoice'],
              infoRows: const [
                ReceiptKeyValue(label: 'Invoice', value: '10001'),
                ReceiptKeyValue(label: 'Date', value: '2026-06-27'),
                ReceiptKeyValue(label: 'Cashier', value: 'John'),
              ],
            ),
            ReceiptTable<Map<String, String>>(
              style: style,
              columns: [
                ReceiptTableColumn(
                  title: 'Product',
                  flex: 2,
                  valueBuilder: (item) => item['name']!,
                ),
                ReceiptTableColumn(
                  title: 'Tax',
                  valueBuilder: (item) => item['tax']!,
                ),
                ReceiptTableColumn(
                  title: 'Qty',
                  valueBuilder: (item) => item['qty']!,
                ),
                ReceiptTableColumn(
                  title: 'Total',
                  valueBuilder: (item) => item['total']!,
                ),
              ],
              rows: const [
                {'name': 'Latte', 'qty': '2', 'total': '24.00', 'tax': '2.40'},
                {'name': 'Croissant', 'qty': '1', 'total': '8.00', 'tax': '0.80'},
                {'name': 'Orange Juice', 'qty': '1', 'total': '10.00', 'tax': '1.00'},
              ],
            ),
            ReceiptTotals(
              style: style,
              rows: const [
                ReceiptKeyValue(label: 'Subtotal', value: '42.00'),
                ReceiptKeyValue(label: 'Tax (10%)', value: '4.20'),
                ReceiptKeyValue(label: 'Total', value: '46.20'),
              ],
            ),
            ReceiptPayments(
              style: style,
              rows: const [ReceiptKeyValue(label: 'Card', value: '46.20')],
            ),
            ReceiptFooter(
              style: style,
              lines: const ['Thank you for your visit!', 'www.coffeehouse.com'],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Arabic receipt (RTL)
  // ---------------------------------------------------------------------------
  Future<void> _printReceiptArabic() async {
    final style = _receiptStyle;
    await _run(
      () => _printer().printWidget(
        (_) => SragReceipt(
          style: style,
          textDirection: pw.TextDirection.rtl,
          children: [
            ReceiptHeader(
              style: style,
              titles: const ['مقهى البيت', 'فاتورة ضريبية'],
              infoRows: const [
                ReceiptKeyValue(label: 'رقم الفاتورة', value: '10002',),
                ReceiptKeyValue(label: 'التاريخ', value: '2026-06-27'),
                ReceiptKeyValue(label: 'الكاشير', value: 'أحمد'),
              ],
            ),
            ReceiptTable<Map<String, String>>(
              style: style,
              columns: [
                ReceiptTableColumn(
                  title: 'المنتج',
                  flex: 2,
                  valueBuilder: (item) => item['name']!,
                ),
                ReceiptTableColumn(
                  title: 'الضريبة',
                  valueBuilder: (item) => item['tax']!,
                ),
                ReceiptTableColumn(
                  title: 'الكمية',
                  valueBuilder: (item) => item['qty']!,
                ),
                ReceiptTableColumn(
                  title: 'الإجمالي',
                  valueBuilder: (item) => item['total']!,
                ),
              ],
              rows: const [
                {'name': 'قهوة لاتيه', 'qty': '2', 'total': '24.00', 'tax': '2.40'},
                {'name': 'كرواسون', 'qty': '1', 'total': '8.00', 'tax': '0.80'},
                {'name': 'عصير برتقال', 'qty': '1', 'total': '10.00', 'tax': '1.00'},
              ],
            ),
            ReceiptTotals(
              style: style,
              rows: const [
                ReceiptKeyValue(label: 'المجموع الفرعي', value: '42.00'),
                ReceiptKeyValue(label: 'الضريبة (10%)', value: '4.20'),
                ReceiptKeyValue(label: 'الإجمالي', value: '46.20'),
              ],
            ),
            ReceiptPayments(
              style: style,
              title: 'طرق الدفع',
              rows: const [ReceiptKeyValue(label: 'نقدي', value: '46.20')],
            ),
            ReceiptFooter(
              style: style,
              lines: const ['شكراً لزيارتكم!', 'www.albait-cafe.com'],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bilingual receipt (English + Arabic)
  // ---------------------------------------------------------------------------
  Future<void> _printReceiptBilingual() async {
    final style = _receiptStyle;
    await _run(
      () => _printer().printWidget(
        (_) => SragReceipt(
          style: style,
          textDirection: pw.TextDirection.rtl,
          children: [
            ReceiptHeader(
              style: style,
              titles: const ['Coffee House | مقهى البيت', 'Tax Invoice | فاتورة ضريبية'],
              infoRows: const [
                ReceiptKeyValue(label:'فاتورة' , value: '10003', trailingLabel:'Invoice' ),
                ReceiptKeyValue(label: 'التاريخ' , value: '2026-06-27', trailingLabel:'Date'),
                ReceiptKeyValue(label:'الكاشير' , value: 'Ahmed | أحمد', trailingLabel:'Cashier' ),
              ],
            ),
            ReceiptTable<Map<String, String>>(
              style: style,
              columns: [
                ReceiptTableColumn(
                  title: 'Product',
                  flex: 2,
                  valueBuilder: (item) => item['name']!,
                ),
                ReceiptTableColumn(
                  title: 'Tax',
                  valueBuilder: (item) => item['tax']!,
                ),
                ReceiptTableColumn(
                  title: 'Qty',
                  valueBuilder: (item) => item['qty']!,
                ),
                ReceiptTableColumn(
                  title: 'Total',
                  valueBuilder: (item) => item['total']!,
                ),
              ],
              rows: const [
                {'name': 'Latte | لاتيه', 'qty': '2', 'total': '24.00', 'tax': '2.40'},
                {'name': 'Croissant | كرواسون', 'qty': '1', 'total': '8.00', 'tax': '0.80'},
                {'name': 'Juice | عصير', 'qty': '1', 'total': '10.00', 'tax': '1.00'},
              ],
            ),
            ReceiptTotals(
              style: style,
              rows: const [
                ReceiptKeyValue(label: 'Subtotal | المجموع', value: '42.00'),
                ReceiptKeyValue(label: 'Tax | الضريبة (10%)', value: '4.20'),
                ReceiptKeyValue(label: 'Total | الإجمالي', value: '46.20'),
              ],
            ),
            ReceiptPayments(
              style: style,
              title: 'Payment Methods | طرق الدفع',
              rows: const [ReceiptKeyValue(label: 'Card | بطاقة', value: '46.20')],
            ),
            ReceiptFooter(
              style: style,
              lines: const [
                'Thank you! | شكراً لزيارتكم!',
                'www.coffeehouse.com',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renderPdfPreview() async {
    final renderer = PdfWidgetRenderer(
      config: SragPrinterConfig(paper: _paper),
    );
    final bytes = await renderer.render((_) => pw.Text('PDF preview bytes'));
    setState(() => _log = 'Rendered PDF: ${bytes.length} bytes');
  }

  Future<void> _run(Future<PrintResult> Function() action) async {
    try {
      final result = await action();
      setState(() {
        _log = 'Printed ${result.frameCount} frame(s), '
            '${result.bytesWritten} bytes in ${result.duration.inMilliseconds}ms';
      });
    } catch (error) {
      setState(() => _log = 'Print error: $error');
    }
  }

  Uint8List _buildTestImage() {
    final width = _paper.headDots;
    final image = image_lib.Image(width: width, height: 180);
    image_lib.fill(image, color: image_lib.ColorRgb8(255, 255, 255));
    for (var x = 20; x < width - 20; x++) {
      image.setPixelRgb(x, 20, 0, 0, 0);
      image.setPixelRgb(x, 160, 0, 0, 0);
    }
    for (var y = 60; y < 120; y++) {
      for (var x = 80; x < width - 80; x++) {
        if ((x ~/ 8 + y ~/ 8) % 2 == 0) {
          image.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    return Uint8List.fromList(image_lib.encodePng(image));
  }
}
