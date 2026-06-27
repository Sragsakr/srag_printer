import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';

import '../core/printer_exception.dart';
import 'printer_device.dart';
import 'printer_discovery_request.dart';

/// Discovers printers and printer-like devices generically by type/platform.
class SragPrinterDiscovery {
  const SragPrinterDiscovery._();

  /// Discovers devices matching [request].
  ///
  /// Discovery never silently chooses a device. Applications should present the
  /// returned devices and let the user or app policy select one.
  static Future<List<PrinterDevice>> discover({
    required PrinterDiscoveryRequest request,
  }) async {
    final platform = _resolvePlatform(request.platform);
    final devices = await switch (request.connectionType) {
      PrinterConnectionType.network => Future.value(<PrinterDevice>[]),
      PrinterConnectionType.usb => _discoverUsb(platform),
      PrinterConnectionType.bluetooth => _discoverBluetooth(platform, request),
      PrinterConnectionType.windowsDriver => _discoverWindowsPrinters(platform),
      PrinterConnectionType.windowsSerial => _discoverWindowsSerial(platform),
    };
    return _applyFilters(devices, request.filters);
  }

  static PrinterPlatform _resolvePlatform(PrinterPlatform platform) {
    if (platform != PrinterPlatform.current) return platform;
    if (Platform.isWindows) return PrinterPlatform.windows;
    if (Platform.isAndroid) return PrinterPlatform.android;
    if (Platform.isIOS) return PrinterPlatform.ios;
    return PrinterPlatform.other;
  }

  static Future<List<PrinterDevice>> _discoverUsb(PrinterPlatform platform) {
    return switch (platform) {
      PrinterPlatform.android => _discoverAndroidUsb(),
      PrinterPlatform.windows => _discoverWindowsSerial(platform),
      PrinterPlatform.current ||
      PrinterPlatform.ios ||
      PrinterPlatform.other =>
        Future.value(<PrinterDevice>[]),
    };
  }

  static Future<List<PrinterDevice>> _discoverAndroidUsb() async {
    final devices = await UsbSerial.listDevices();
    return devices
        .map(
          (device) => PrinterDevice(
            id: device.deviceId?.toString() ?? device.hashCode.toString(),
            name: device.productName ?? device.manufacturerName ?? 'USB device',
            connectionType: PrinterConnectionType.usb,
            platform: PrinterPlatform.android,
            metadata: <String, Object?>{
              'usbDevice': device,
              'manufacturerName': device.manufacturerName,
              'productName': device.productName,
              'vendorId': device.vid,
              'productId': device.pid,
            },
          ),
        )
        .toList();
  }

  static Future<List<PrinterDevice>> _discoverBluetooth(
    PrinterPlatform platform,
    PrinterDiscoveryRequest request,
  ) async {
    if (platform == PrinterPlatform.other) return <PrinterDevice>[];
    final result = <PrinterDevice>[];

    if (await FlutterBluePlus.isSupported == false) {
      return result;
    }

    if (request.includePairedBluetoothDevices) {
      final bonded = await FlutterBluePlus.bondedDevices;
      result.addAll(
        bonded.map(
          (device) => PrinterDevice(
            id: device.remoteId.str,
            name: device.platformName.isEmpty
                ? device.remoteId.str
                : device.platformName,
            connectionType: PrinterConnectionType.bluetooth,
            platform: platform,
            metadata: <String, Object?>{'bleDevice': device, 'paired': true},
          ),
        ),
      );
    }

    if (request.includeBleDevices) {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) return result;

      await FlutterBluePlus.startScan(timeout: request.timeout);
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final scan in results) {
          final id = scan.device.remoteId.str;
          if (result.any((device) => device.id == id)) continue;
          result.add(
            PrinterDevice(
              id: id,
              name: scan.device.platformName.isEmpty
                  ? id
                  : scan.device.platformName,
              connectionType: PrinterConnectionType.bluetooth,
              platform: platform,
              metadata: <String, Object?>{
                'bleDevice': scan.device,
                'paired': false,
                'rssi': scan.rssi,
              },
            ),
          );
        }
      });
      await Future<void>.delayed(request.timeout);
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }

    return result;
  }

  static Future<List<PrinterDevice>> _discoverWindowsPrinters(
    PrinterPlatform platform,
  ) async {
    if (platform != PrinterPlatform.windows) return <PrinterDevice>[];
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-Command',
      r"Get-Printer | ForEach-Object { $_.Name + '|' + $_.PortName + '|' + $_.DriverName }",
    ]);
    if (result.exitCode != 0) {
      throw PrinterDiscoveryException(
        'Failed to enumerate Windows system printers.',
        result.stderr,
      );
    }
    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split('|');
      final name = parts[0].trim();
      return PrinterDevice(
        id: name,
        name: name,
        connectionType: PrinterConnectionType.windowsDriver,
        platform: PrinterPlatform.windows,
        metadata: <String, Object?>{
          'portName': parts.length > 1 ? parts[1].trim() : '',
          'driverName': parts.length > 2 ? parts[2].trim() : '',
        },
      );
    }).toList();
  }

  static Future<List<PrinterDevice>> _discoverWindowsSerial(
    PrinterPlatform platform,
  ) async {
    if (platform != PrinterPlatform.windows) return <PrinterDevice>[];
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-Command',
      r"Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match 'COM\d+' } | ForEach-Object { $_.Name }",
    ]);
    if (result.exitCode != 0) {
      return <PrinterDevice>[];
    }
    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final match = RegExp(r'(COM\d+)').firstMatch(line);
      final port = match?.group(1) ?? line;
      return PrinterDevice(
        id: port,
        name: line,
        connectionType: PrinterConnectionType.windowsSerial,
        platform: PrinterPlatform.windows,
        metadata: <String, Object?>{'portName': port},
      );
    }).toList();
  }

  static List<PrinterDevice> _applyFilters(
    List<PrinterDevice> devices,
    Map<String, Object?> filters,
  ) {
    final nameContains = filters['nameContains']?.toString().toLowerCase();
    final vendorId = filters['vendorId'];
    final productId = filters['productId'];
    return devices.where((device) {
      if (nameContains != null &&
          !device.name.toLowerCase().contains(nameContains)) {
        return false;
      }
      if (vendorId != null && device.metadata['vendorId'] != vendorId) {
        return false;
      }
      if (productId != null && device.metadata['productId'] != productId) {
        return false;
      }
      return true;
    }).toList();
  }
}
