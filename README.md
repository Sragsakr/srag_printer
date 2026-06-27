# srag_printer

`srag_printer` is a flexible Flutter thermal printing package for printing PDF widgets, PDF bytes, and image frames through ESC/POS thermal printers.

It is intentionally generic. It does not know about your POS models, tax rules, ZATCA QR generation, preferences, providers, or app assets. Your app builds the content; `srag_printer` renders and prints it.

## Acknowledgements

`srag_printer` is built on top of excellent Flutter/Dart packages, including:

- `pdf` for building PDF documents with Dart widgets.
- `pdfx` for rendering PDF pages into images.
- `image` for image decoding and processing.
- `esc_pos_utils_plus` for ESC/POS command generation utilities.
- `usb_serial` for Android USB serial communication.
- `flutter_blue_plus` for Bluetooth Low Energy discovery and communication.
- `ffi` for Windows RAW driver and serial port bindings.

Many thanks to the maintainers and contributors of these packages.

## What This Package Does

- Prints any `pw.Widget` from `package:pdf/widgets.dart`.
- Prints existing PDF bytes.
- Prints existing image frames as `List<Uint8List>`.
- Converts PDF pages into thermal-printer-width image frames.
- Converts images to ESC/POS raster commands.
- Sends bytes through network, USB, Bluetooth BLE, Windows driver, or Windows serial transports.
- Provides generic receipt widgets as optional helpers.
- Provides generic device discovery by type/platform.

## What This Package Does Not Do

- It does not generate ZATCA QR codes.
- It does not calculate tax, discounts, totals, or business rules.
- It does not depend on `SalesInvoice` or any app-specific model.
- It does not read `SharedPreferences` or app settings.
- It does not load your app assets automatically.
- It does not hardcode vendors such as POSIFLEX or any specific printer model.
- It does not silently select the first discovered printer by default.

## Installation

Add the package to your app. During local development inside this repository:

```yaml
dependencies:
  srag_printer:
    path: packages/srag_printer
```

Then import:

```dart
import 'package:srag_printer/srag_printer.dart';
import 'package:pdf/widgets.dart' as pw;
```

## Platform Support

| Capability | Windows | Android | iOS |
|---|---:|---:|---:|
| Print `pw.Widget` | Yes | Yes | Yes |
| Print PDF bytes | Yes | Yes | Yes |
| Print image frames | Yes | Yes | Yes |
| Network TCP/IP | Yes | Yes | Yes |
| USB direct | Yes via serial/driver | Yes | Not in v1 |
| Windows driver RAW | Yes | No | No |
| Windows COM serial | Yes | No | No |
| Bluetooth classic | Not in v1 | Not in v1 | Not in v1 |
| BLE Bluetooth | Yes | Possible | Possible |
| Generic USB discovery | COM/system devices | USB devices | No |
| Network discovery | Manual IP/port | Manual IP/port | Manual IP/port |

## Quick Start: Network Printer

```dart
final printer = SragPrinter(
  transport: NetworkPrinterTransport(host: '192.168.1.50', port: 9100),
  config: const SragPrinterConfig(
    paper: SragPaper.mm80(headDots: 528),
  ),
);

await printer.printWidget(
  (_) => pw.Column(
    children: [
      pw.Text('Hello from srag_printer'),
      pw.Text('Printed from a PDF widget'),
    ],
  ),
);
```

## Print Any PDF Widget

Use this when your app wants total control over layout:

```dart
await printer.printWidget(
  (_) => pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Column(
      children: [
        pw.Text('فاتورة تجريبية'),
        pw.Divider(),
        pw.Text('You can render any pdf widget here.'),
      ],
    ),
  ),
);
```

## Print PDF Bytes

```dart
final pdfBytes = await buildMyPdfSomewhereElse();
await printer.printPdf(pdfBytes);
```

## Print Image Frames

```dart
final frames = <Uint8List>[pngFrame1, pngFrame2];
await printer.printImages(frames);
```

## Receipt Widgets

The receipt widgets are optional helpers. You can use them, mix them with your own `pw.Widget`s, or ignore them completely.

```dart
await printer.printWidget(
  (_) => SragReceipt(
    textDirection: pw.TextDirection.ltr,
    children: [
      ReceiptHeader(
        titles: ['Simplified Tax Invoice', 'فاتورة ضريبية مبسطة'],
        infoRows: const [
          ReceiptKeyValue(label: 'Invoice No', value: '10001'),
          ReceiptKeyValue(label: 'Date', value: '2026-06-27'),
        ],
      ),
      ReceiptTable<Map<String, String>>(
        columns: [
          ReceiptTableColumn(title: 'Product', flex: 4, valueBuilder: (x) => x['name']!),
          ReceiptTableColumn(title: 'Qty', valueBuilder: (x) => x['qty']!),
          ReceiptTableColumn(title: 'Total', valueBuilder: (x) => x['total']!),
        ],
        rows: const [
          {'name': 'Coffee', 'qty': '1', 'total': '12.00'},
        ],
      ),
      ReceiptTotals(
        rows: const [
          ReceiptKeyValue(label: 'Subtotal', value: '12.00'),
          ReceiptKeyValue(label: 'Tax', value: '1.80'),
          ReceiptKeyValue(label: 'Total', value: '13.80'),
        ],
      ),
      ReceiptFooter(lines: const ['Thank you']),
    ],
  ),
);
```

## Custom Table Rows

```dart
ReceiptTable<MyItem>(
  columns: columns,
  rows: items,
  rowBuilder: (context, item, columns) {
    return pw.Column(
      children: [
        pw.Text(item.name),
        pw.Text('Custom options, modifiers, or notes'),
      ],
    );
  },
);
```

## QR Codes

`srag_printer` does not generate QR content. Generate the QR in your app, then pass it as an image or widget:

```dart
ReceiptQrSection.image(qrPngBytes);
ReceiptQrSection.widget(myQrPdfWidget);
```

## Discovery

Discovery is generic and platform-aware. It does not hardcode printer brands or choose for you:

```dart
final devices = await SragPrinterDiscovery.discover(
  request: const PrinterDiscoveryRequest(
    connectionType: PrinterConnectionType.usb,
  ),
);

final selected = devices.first; // Your UI or app policy chooses this.
final transport = selected.createTransport();
```

Optional filters are app-controlled:

```dart
final devices = await SragPrinterDiscovery.discover(
  request: const PrinterDiscoveryRequest(
    connectionType: PrinterConnectionType.usb,
    filters: {'nameContains': 'printer'},
  ),
);
```

## Paper and Print Options

```dart
const config = SragPrinterConfig(
  paper: SragPaper.mm58(headDots: 384),
  chunkSize: 512,
  chunkDelay: Duration(milliseconds: 6),
  feedLines: 3,
  cutAfterPrint: true,
);
```

Use `SragPaper.custom(widthMm: ..., headDots: ...)` for uncommon printers.

## Troubleshooting

- `Cannot reach printer at host:port`: check IP, port, network, and firewall.
- `No writable BLE characteristic found`: the printer may use classic Bluetooth SPP or a proprietary BLE service.
- `USB transport is supported on Android`: use Windows driver/serial transports on Windows.
- `Image frame could not be decoded`: pass PNG/JPEG bytes, not raw pixels.
- Cut command ignored: some printers do not have a cutter, or the driver may block raw ESC/POS commands.

## Migration Guide

Keep app-specific logic in your app:

```text
SalesInvoice / app model -> your adapter -> pw.Widget or receipt data -> srag_printer
```

Do not move tax, QR generation, ZATCA logic, local preferences, or app assets into this package.

## FAQ

**Can I print any Flutter widget?**  
No. The input must be a `pdf/widgets.dart` widget (`pw.Widget`), not a normal Flutter `Widget`.

**Can the package discover network printers automatically?**  
Not in v1. Use manual IP/port for reliability and predictable behavior.

**Does iOS support USB printing?**  
Generic USB thermal printing is not supported in v1.

**Does the package generate QR codes?**  
No. Pass a ready QR image or `pw.Widget`.

