import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/printer_exception.dart';
import '../discovery/printer_device.dart';
import 'printer_transport.dart';

/// BLE Bluetooth printer transport.
///
/// This transport writes raw ESC/POS bytes to the first writable BLE
/// characteristic. Classic Bluetooth SPP is not implemented in v1.
class BluetoothPrinterTransport implements PrinterTransport {
  /// Creates a BLE transport from a discovered [device].
  BluetoothPrinterTransport.fromDevice(PrinterDevice device)
      : bluetoothDevice = device.metadata['bleDevice'] as BluetoothDevice?;

  /// Creates a BLE transport from a [bluetoothDevice].
  BluetoothPrinterTransport.bleDevice({required this.bluetoothDevice});

  /// BLE device used for printing.
  final BluetoothDevice? bluetoothDevice;

  BluetoothCharacteristic? _writeCharacteristic;

  @override
  Future<void> open() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw const PrinterUnsupportedPlatformException(
        'Bluetooth LE is not supported on this device.',
      );
    }
    final device = bluetoothDevice;
    if (device == null) {
      throw const PrinterDeviceNotFoundException(
        'No Bluetooth device was provided.',
      );
    }
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            return;
          }
        }
      }
      await device.disconnect();
      throw const PrinterConnectionException(
        'No writable BLE characteristic found on selected device.',
      );
    } catch (error) {
      if (error is PrinterConnectionException) rethrow;
      throw PrinterConnectionException('Failed to open Bluetooth printer.', error);
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw const PrinterConnectionException('Bluetooth printer is not open.');
    }
    try {
      const mtuSize = 512;
      for (var i = 0; i < bytes.length; i += mtuSize) {
        final end = (i + mtuSize).clamp(0, bytes.length);
        await characteristic.write(
          bytes.sublist(i, end),
          withoutResponse: false,
        );
      }
    } catch (error) {
      throw PrinterWriteException('Failed to write to Bluetooth printer.', error);
    }
  }

  @override
  Future<void> close() async {
    await bluetoothDevice?.disconnect();
    _writeCharacteristic = null;
  }
}

