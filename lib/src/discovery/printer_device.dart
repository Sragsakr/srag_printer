import '../transports/bluetooth_printer_transport.dart';
import '../transports/network_printer_transport.dart';
import '../transports/printer_transport.dart';
import '../transports/usb_printer_transport.dart';
import '../transports/windows_printer_transport.dart';

/// Supported printer connection types.
enum PrinterConnectionType {
  /// TCP socket printing, usually on port 9100.
  network,

  /// USB device or serial/COM printing depending on platform.
  usb,

  /// Bluetooth classic or BLE depending on platform support.
  bluetooth,

  /// Windows installed printer using RAW spooler output.
  windowsDriver,

  /// Windows serial COM port.
  windowsSerial,
}

/// Platforms understood by discovery and transport factories.
enum PrinterPlatform {
  /// Current runtime platform.
  current,

  /// Microsoft Windows.
  windows,

  /// Android.
  android,

  /// Apple iOS.
  ios,

  /// Other platform.
  other,
}

/// Generic printer or printer-like device returned by discovery.
class PrinterDevice {
  /// Creates a discovered printer device.
  const PrinterDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.platform,
    this.metadata = const <String, Object?>{},
  });

  /// Stable device identifier for the selected discovery source.
  final String id;

  /// Human-readable display name.
  final String name;

  /// Connection type used to reach this device.
  final PrinterConnectionType connectionType;

  /// Platform that produced this device.
  final PrinterPlatform platform;

  /// Platform-specific details such as port name, driver, vendor ID, or object.
  final Map<String, Object?> metadata;

  /// Creates the default transport for this device.
  ///
  /// For network devices, [networkHost] is required because v1 discovery does
  /// not scan local subnets automatically.
  PrinterTransport createTransport({String? networkHost, int networkPort = 9100}) {
    switch (connectionType) {
      case PrinterConnectionType.network:
        if (networkHost == null || networkHost.isEmpty) {
          throw ArgumentError('networkHost is required for network printers.');
        }
        return NetworkPrinterTransport(host: networkHost, port: networkPort);
      case PrinterConnectionType.usb:
        return UsbPrinterTransport.fromDevice(this);
      case PrinterConnectionType.bluetooth:
        return BluetoothPrinterTransport.fromDevice(this);
      case PrinterConnectionType.windowsDriver:
        return WindowsDriverPrinterTransport(printerName: id);
      case PrinterConnectionType.windowsSerial:
        return WindowsSerialPrinterTransport(portName: id);
    }
  }

  @override
  String toString() => 'PrinterDevice($connectionType, $id, $name)';
}

