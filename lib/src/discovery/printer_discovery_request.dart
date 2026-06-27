import 'printer_device.dart';

/// Options used when discovering printer devices.
class PrinterDiscoveryRequest {
  /// Creates a discovery request.
  const PrinterDiscoveryRequest({
    required this.connectionType,
    this.platform = PrinterPlatform.current,
    this.timeout = const Duration(seconds: 5),
    this.includePairedBluetoothDevices = true,
    this.includeBleDevices = true,
    this.includeSystemPrinters = true,
    this.filters = const <String, Object?>{},
  });

  /// Type of devices to discover.
  final PrinterConnectionType connectionType;

  /// Target platform. Use [PrinterPlatform.current] for runtime detection.
  final PrinterPlatform platform;

  /// Maximum scan time for discovery mechanisms that support a timeout.
  final Duration timeout;

  /// Whether to include already paired/bonded Bluetooth devices.
  final bool includePairedBluetoothDevices;

  /// Whether to scan for BLE devices where supported.
  final bool includeBleDevices;

  /// Whether to include OS-installed printers on desktop platforms.
  final bool includeSystemPrinters;

  /// Optional user-controlled filters such as `nameContains`, `vendorId`, or
  /// `productId`. The package does not apply vendor-specific defaults.
  final Map<String, Object?> filters;
}

