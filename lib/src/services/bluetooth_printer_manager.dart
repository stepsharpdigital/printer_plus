// ignore_for_file: public_member_api_docs

import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart' as themal;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fblue;
import 'package:printer_plus/src/enums/connection_response.dart';
import 'package:printer_plus/src/models/bluetooth_printer.dart';
import 'package:printer_plus/src/models/pos_printer.dart';
import 'package:printer_plus/src/printer_plus.dart';

import 'package:printer_plus/src/services/bluetooth_service.dart';
import 'package:printer_plus/src/services/printer_manager.dart';

/// Bluetooth Printer
class BluetoothPrinterManager extends PrinterManager {
  BluetoothPrinterManager(
    POSPrinter printer,
    PaperSize paperSize,
    CapabilityProfile profile, {
    int spaceBetweenRows = 5,
    int port = 9100,
  }) {
    super.printer = printer;
    super.address = printer.address;
    super.paperSize = paperSize;
    super.profile = profile;
    super.spaceBetweenRows = spaceBetweenRows;
    super.port = port;
    generator =
        Generator(paperSize, profile, spaceBetweenRows: spaceBetweenRows);
  }

  themal.BlueThermalPrinter bluetooth = themal.BlueThermalPrinter.instance;
  fblue.FlutterBluePlus flutterBlue = fblue.FlutterBluePlus();
  late fblue.BluetoothDevice fbdevice;

  /// [connect] let you connect to a bluetooth printer
  @override
  Future<ConnectionResponse> connect({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (Platform.isIOS) {
        fbdevice = fblue.BluetoothDevice.fromId(printer!.address!);
        final connected = fblue.FlutterBluePlus.connectedDevices;
        final index =
            connected.indexWhere((e) => e.remoteId == fbdevice.remoteId);
        if (index < 0) await fbdevice.connect();
      } else if (Platform.isAndroid) {
        final device = themal.BluetoothDevice(printer!.name, printer!.address);
        await bluetooth.connect(device);
      }

      isConnected = true;
      printer!.connected = true;
      return Future<ConnectionResponse>.value(ConnectionResponse.success);
    } catch (e) {
      isConnected = false;
      printer!.connected = false;
      return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
    }
  }

  /// [discover] let you explore all bluetooth printer nearby your device
  static Future<List<BluetoothPrinter>> discover() async {
    final results = await BluetoothService.findBluetoothDevice();
    print(results);
    return [
      ...results.map(
        (e) => BluetoothPrinter(
          id: e.address,
          name: e.name,
          address: e.address,
          type: e.type,
        ),
      ),
    ];
  }

  /// [sendData] let you write raw list int data into socket
  @override
  Future<void> sendData(List<int> data, {bool isDisconnect = true}) async {
    try {
      if (!isConnected) {
        await connect();
      }
      if (Platform.isAndroid) {
        await bluetooth.writeBytes(Uint8List.fromList(data));
        if (isDisconnect) {
          await disconnect();
        }
      } else if (Platform.isIOS) {
        final services = await fbdevice.discoverServices();
        final service = services.firstWhere((e) => e.isPrimary);
        final charactor =
            service.characteristics.firstWhere((e) => e.properties.write);
        await charactor.write(data, withoutResponse: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error : $e');
      }
    }
  }

  /// [timeout]: milliseconds to wait after closing the socket
  @override
  Future<ConnectionResponse> disconnect({Duration? timeout}) async {
    if (Platform.isAndroid) {
      await bluetooth.disconnect();
      isConnected = false;
    } else if (Platform.isIOS) {
      await fbdevice.disconnect();
      isConnected = false;
    }

    if (timeout != null) {
      await Future.delayed(timeout, () => null);
    }
    return ConnectionResponse.success;
  }

  @override
  Stream<ConnectionStatus> connectionStatus() {
    if (Platform.isAndroid) {
      return bluetooth.onStateChanged().asyncMap((event) {
        if (kDebugMode) {
          print('Connection Status: $event');
        }
        if (event == themal.BlueThermalPrinter.STATE_ON ||
            event == themal.BlueThermalPrinter.CONNECTED) {
          return ConnectionStatus.connected;
        } else {
          return ConnectionStatus.disconnected;
        }
      });
    } else {
      return fbdevice.bondState.asyncMap((event) {
        if (kDebugMode) {
          print('Connection Status: $event');
        }
        if (event == fblue.BluetoothBondState.bonded) {
          return ConnectionStatus.connected;
        } else if (event == fblue.BluetoothBondState.none) {
          return ConnectionStatus.disconnected;
        } else {
          return ConnectionStatus.disconnected;
        }
      });
    }
  }

  @override
  Future<bool> isDeviceConnected() async {
    if (Platform.isAndroid) {
      final connected = await bluetooth.isConnected;
      return connected ?? false;
    } else if (Platform.isIOS) {
      final list = fblue.FlutterBluePlus.connectedDevices;
      return list.isNotEmpty;
    }
    return false;
  }
}
