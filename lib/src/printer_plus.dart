// ignore_for_file: no_default_cases, public_member_api_docs

import 'dart:typed_data';

import 'package:easy_logger/easy_logger.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:printer_plus/src/models/pos_printer.dart';
import 'package:printer_plus/src/services/bluetooth_printer_manager.dart';
import 'package:printer_plus/src/services/network_printer_manager.dart';
import 'package:printer_plus/src/services/printer_manager.dart';
import 'package:printer_plus/src/services/usb_printer_manager.dart';

/// {@template printer_plus}
/// Multi Printer package
/// {@endtemplate}
class PrinterPlus {
  factory PrinterPlus() {
    return _instance;
  }
  PrinterPlus._();

  static final PrinterPlus _instance = PrinterPlus._();

  static PrinterPlus get instance => _instance;

  static EasyLogger logger = EasyLogger(
    name: 'printer_plus',
    defaultLevel: LevelMessages.debug,
    enableBuildModes: [BuildMode.debug, BuildMode.profile, BuildMode.release],
    enableLevels: [
      LevelMessages.debug,
      LevelMessages.info,
      LevelMessages.error,
      LevelMessages.warning,
    ],
  );

  PrinterManager? _printerManager;

  bool _connected = false;

  Future<List<POSPrinter>> scanPrinters(POSPrinterMode? mode) async {
    var printers = <POSPrinter>[];
    try {
      switch (mode) {
        case POSPrinterMode.BLE:
          printers = await BluetoothPrinterManager.discover();
          break;
        case POSPrinterMode.NET:
          printers = await NetworkPrinterManager.discover();
          break;
        case POSPrinterMode.USB:
          printers = await USBPrinterManager.discover();
          break;
        default:
      }
    } catch (e) {
      rethrow;
    }

    return printers;
  }

  Future<bool> isConnected() async {
    if (_printerManager == null) return false;
    final isConnected = await _printerManager?.isDeviceConnected();
    return isConnected ?? false;
  }

  Future<bool> connectPrinter(
    POSPrinterMode? mode,
    POSPrinter printer,
  ) async {
    const paperSize = PaperSize.mm80;
    final profile = await CapabilityProfile.load();

    switch (mode) {
      case POSPrinterMode.USB:
        _printerManager = USBPrinterManager(printer, paperSize, profile);
        break;
      case POSPrinterMode.BLE:
        _printerManager = BluetoothPrinterManager(printer, paperSize, profile);
        break;
      case POSPrinterMode.NET:
        _printerManager = NetworkPrinterManager(printer, paperSize, profile);
        break;
      default:
    }

    if (await isConnected()) {
      await _printerManager?.disconnect();
    }

    final result = await _printerManager?.connect();

    if (result?.value == 1) {
      _connected = true;
      _printerManager?.isConnected = true;
      return true;
    } else {
      _connected = false;
      return false;
    }
  }

  Stream<ConnectionStatus> onConnectionChanged() {
    if (_printerManager != null) {
      return _printerManager!.connectionStatus();
    }
    return Stream.value(ConnectionStatus.disconnected);
  }

  Future<void> disconnect() async {
    await _printerManager?.disconnect();
  }

  Future<void> printReciept(
      POSPrinterMode? mode, POSPrinter printer, List<int> value) async {
    final data = Uint8List.fromList(value);

    if (await connectPrinter(mode, printer)) {
      if (mode == POSPrinterMode.USB) {
        await _printerManager?.sendData(data);
      } else if (mode == POSPrinterMode.NET) {
        await _printerManager?.sendData(data);
      } else {
        await _printerManager?.sendData(data, isDisconnect: false);
      }
    } else {
      throw Exception('Please connect a POS printer');
    }
  }
}

enum POSPrinterMode { NET, BLE, USB }

enum ConnectionStatus { connected, disconnected }
