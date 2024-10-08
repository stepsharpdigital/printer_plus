// ignore_for_file: public_member_api_docs

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:printer_plus/src/enums/connection_response.dart';
import 'package:printer_plus/src/models/pos_printer.dart';
import 'package:printer_plus/src/printer_plus.dart';

abstract class PrinterManager {
  PaperSize? paperSize;
  CapabilityProfile? profile;
  Generator? generator;
  bool isConnected = false;
  String? address;
  int? vendorId;
  int? productId;
  int? deviceId;
  int port = 9100;
  int spaceBetweenRows = 5;
  POSPrinter? printer;

  Future<ConnectionResponse> connect({Duration timeout});

  Future<dynamic> sendData(List<int> data, {bool isDisconnect = true});

  Future<ConnectionResponse> disconnect({Duration timeout});

  Stream<ConnectionStatus> connectionStatus();

  Future<bool> isDeviceConnected();
}
